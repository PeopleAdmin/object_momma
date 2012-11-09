module FakeModel
  def self.included(base)
    base.extend(ClassMethods)
  end

  def ==(other_object)
    self.object_id == other_object.object_id
  end

  def initialize(attributes = {})
    attributes.each do |key, value|
      instance_variable_set("@#{key}".to_sym, value)
    end

    self.class.instances << self
  end
  
  def id
    return nil unless persisted?

    persisted_instances = self.class.instances.select(&:persisted?)
    index = persisted_instances.index { |instance| instance == self }
    index + 1
  end

  def persisted?
    @is_persisted ? true : false
  end

  def save
    @is_persisted = true
    true
  end
  alias_method :save!, :save

  module ClassMethods
    def belongs_to(association_name)
      define_method(association_name) do
        instance_variable_get("@#{association_name}")
      end

      define_method("#{association_name}_id") do
        send(association_name).id
      end

      define_method("#{association_name}=") do |value|
        instance_variable_set("@#{association_name}", value)
      end
    end

    def destroy_all
      instances.clear
    end

    def instances
      @instances ||= []
    end

    def fake_column(column_name)
      class_eval { attr_accessor(column_name) }
    end

    def fake_columns(*column_names)
      column_names.each { |column_name| fake_column(column_name) }
    end

    def where(conditions = {})
      object = instances.detect do |object|
        conditions.all? { |attr, value| object.send(attr) == value }
      end

      object ||= self.new

      scope = BasicObject.new

      scope.instance_exec(object) { |o| @__scope_object__ = o }

      class << scope
        def first_or_initialize
          @__scope_object__
        end
        def method_missing(method_name, *args, &block)
          @__scope_object__.send(method_name, *args, &block)
        end
      end

      scope
    end
  end
end
