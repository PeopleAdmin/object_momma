module ObjectMomma
  module Config
    def self.extended(base)
      base.singleton_class.instance_eval do
        attr_reader :serialized_attributes_path, :use_serialized_attributes
      end
    end

    def serialized_attributes_path=(path)
      unless File.directory?(path)
        raise ArgumentError, "`#{path}' is not a valid directory"
      end
      @serialized_attributes_path = path
    end

    def use_serialized_attributes=(true_or_false)
      @use_serialized_attributes = true_or_false ? true : false
    end
  end
end
