module ObjectMomma
  module ModuleMethods
    def builder_for(object_type)
      ObjectMomma::Builder.builder_for(object_type)
    end

    def method_missing(method_name, *args, &block)
      return super unless respond_to?(method_name)
      return super if block_given?
      
      object_type = object_type_from_attributes_getter(method_name)
      if object_type
        args.push(:find_or_create)
        child = ObjectMomma::Child.new(object_type, *args)
        return child.attributes_for_child
      end

      object_type, actualize_strategy = object_type_and_actualize_strategy_from_method_name(method_name)
      args.push(actualize_strategy)

      child = ObjectMomma::Child.new(object_type, *args)
      child.child_object
    end

    def mullet!
      return false if Object.const_defined?(:ObjectMother)

      object_mother = Class.new(BasicObject) do
        def self.method_missing(*args)
          ObjectMomma.send(*args)
        end
      end

      Object.const_set(:ObjectMother, object_mother)
      true
    end

    def object_type_from_attributes_getter(method_name)
      return nil unless ObjectMomma.use_serialized_attributes
      match = method_name.to_s.match(%r{^(\w+)_attributes$}).to_a[1..-1]
      return nil unless match

      object_type = match[0]

      begin
        builder_for(object_type)
        object_type
      rescue NameError
        nil
      end
    end

    def object_type_and_actualize_strategy_from_method_name(method_name)
      # Try ObjectMomma.user
      begin
        builder_for(method_name)
        object_type = method_name.to_sym
        return [object_type, :find_or_create]
      rescue NameError
      end

      # Try ObjectMomma.spawn_user, ObjectMomma.find_user
      public_method_name, object_type = [*method_name.to_s.match(/^(create|find|spawn)_(\w+)$/).to_a[1..-1]].compact.map(&:to_sym)
      return nil if object_type.nil?

      begin
        builder_for(object_type)
        if public_method_name == :spawn
          actualize_strategy = :find_or_create
        else
          actualize_strategy = public_method_name
        end
        [object_type, actualize_strategy]
      rescue NameError
        nil
      end
    end
    alias_method :parse_method_name, :object_type_and_actualize_strategy_from_method_name

    def respond_to?(method_name, *args)
      return true if super
      return true if object_type_from_attributes_getter(method_name)
      parse_method_name(method_name).nil? ? false : true
    end

    def spawn(hash = {})
      hash.each do |object_type, child_id_or_ids|
        begin
          builder_for(object_type)
        rescue NameError => ne
          singularized = object_type.to_s.chomp('s').to_sym
          raise ne if singularized == object_type
          
          builder_for(singularized)
          object_type = singularized
        end
        
        child_ids = [*child_id_or_ids]
        child_ids.each { |child_id| send("spawn_#{object_type}", child_id) }
      end
    end
  end
end
