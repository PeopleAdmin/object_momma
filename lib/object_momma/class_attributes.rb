module ObjectMomma
  module ClassAttributes
    # See http://www.ruby-forum.com/topic/197051
    def class_attribute(*attributes)
      singleton_class.class_eval do
        attr_accessor *attributes
      end

      @class_attributes ||= []
      @class_attributes.concat(attributes)
    end

    def inherited(subclass)
      @class_attributes.compact.each do |attribute|
        subclass.class_attribute attribute

        value = self.send(attribute)
        next if value.nil?

        subclass.send("#{attribute}=", self.send(attribute))
      end
    end
  end
end
