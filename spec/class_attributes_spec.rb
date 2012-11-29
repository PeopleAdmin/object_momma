require 'object_momma/class_attributes'

describe ObjectMomma::ClassAttributes do
  let!(:base_klass) do
    Class.new do
      extend ObjectMomma::ClassAttributes

      class_attribute :foo, :ping

      def self.set_foo(value)
        self.foo = value
      end

      def self.set_ping(value)
        self.ping = value
      end
    end
  end

  let!(:subclass) do
    Class.new(base_klass) do
      set_foo :bar
      set_ping :pong
    end
  end

  let!(:subsubclass) do
    Class.new(subclass) do
      set_foo :baz
    end
  end

  it "propagates class attributes to deep subclasses" do
    subclass.foo.should     == :bar
    subclass.ping.should    == :pong
    subsubclass.foo.should  == :baz
    subsubclass.ping.should == :pong
  end
end
