class ObjectMomma::ThingBuilder < ObjectMomma::Builder
  class Thing
    attr_accessor :a_property, :another_property

    def persisted?
      a_property.nil? ? false : true
    end
  end

  def first_or_initialize
    Thing.new
  end

  def build!(thing)
    thing.a_property       = :foo
    thing.another_property = :bar
  end
end
