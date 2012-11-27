module ObjectMomma
  VALID_IDENTIFIER_CHARS = %q{-\w\s_'\"\.}

  class Builder
    extend ObjectMomma::ClassAttributes

    class_attribute :child_id_serializer, :siblings

    attr_reader :child
    private :child

    def build_child_from_hash(hash, &block)
      if has_child_id_serializer?
        child.child_id = self.class.run_with_binding(hash)

        hash.each do |name, value|
          if has_siblings?
            sibling_object_type = self.class.siblings[name]
            if sibling_object_type
              if value.is_a?(ObjectMomma::Child)
                child = value
              else
                child = yield(sibling_object_type, value)
              end
              value = child.child_object
            end
          end

          ivar_name = "@#{name}"
          instance_variable_set(ivar_name, value)
          self.singleton_class.instance_exec(name, ivar_name) do |name, ivar_name|
            define_method(name) { instance_variable_get(ivar_name) }
          end
        end
      else
        child.child_id = hash.delete(:child_id)
      end
    end

    def build!(*args)
      raise Objectmomma::SubclassNotImplemented
    end

    def child_id
      child.child_id
    end

    def initialize(child)
      @child = child
    end

    def is_persisted?(object)
      if object.respond_to?(:persisted?)
        object.persisted?
      else
        raise ObjectMomma::SubclassNotImplemented, "Override #is_persisted? "\
          "to support objects that do not respond to #persisted?"
      end
    end

    def self.builder_for(object_type)
      if ObjectMomma.builder_path
        builder_file = File.join(ObjectMomma.builder_path, "#{object_type}_builder.rb")
        require builder_file if File.size?(builder_file)
      end

      classified_name = "_#{object_type}Builder".gsub(/_\w/) do |underscored|
        underscored[1].upcase
      end

      ObjectMomma.const_get(classified_name)
    end

    def self.has_child_id_serializer?
      self.child_id_serializer.respond_to?(:to_proc)
    end

    def self.has_siblings?
      self.siblings.is_a?(Hash)
    end

    def self.run_with_binding(props = {}, &block)
      Object.new.tap do |o|
        props.each do |name, value|
          ivar_name = "@#{name}".to_sym
          o.singleton_class.class_eval do
            define_method(name) { instance_variable_get(ivar_name) }
          end
          o.instance_variable_set(ivar_name, value)
        end

        o.singleton_class.class_eval(&block) if block_given?
      end.instance_exec(&child_id_serializer)
    end

    def self.string_to_hash(object_type, string)
      builder = builder_for(object_type)

      if builder.has_child_id_serializer?
        vars = []

        builder.run_with_binding(vars: vars) do
          def method_missing(sym, *args, &block)
            return super unless args.empty? && !block_given?
            vars << sym unless vars.include?(sym)
          end
        end

        string_matcher = "([#{VALID_IDENTIFIER_CHARS}]+)"
        regex_string = builder.run_with_binding(string_matcher: string_matcher) do
          def method_missing(sym, *args, &block)
            return super unless args.empty? && !block_given?
            string_matcher
          end
        end

        regex = Regexp.new("^#{regex_string}$")
        matches = string.match(regex).to_a[1..-1]

        if matches.nil?
          raise BadChildIdentifier, "Bad child_id `#{string}' for builder "\
            "`#{name}'"
        end

        Hash[vars.zip(matches)]
      else
        {child_id: string}
      end
    end

    class << self
      def child_id(&block)
        self.child_id_serializer = block
      end

      def has_siblings(*args)
        if args.last.is_a?(Hash)
          hash = args.pop.each_with_object({}) do |(sibling_name, object_type), hash|
            hash[sibling_name] = object_type
          end
        else
          hash = {}
        end

        args.each_with_object(hash) do |sibling_name|
          object_type = sibling_name
          hash[sibling_name] = object_type
        end

        self.siblings = hash
      end
    end

    private

    def has_child_id_serializer?
      self.class.has_child_id_serializer?
    end

    def has_siblings?
      self.class.has_siblings?
    end
  end
end
