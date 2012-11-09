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
      @class_attributes.each do |attribute|
        subclass.send("#{attribute}=", self.send(attribute))
      end
    end
  end
end
