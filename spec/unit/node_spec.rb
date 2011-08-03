require 'spec_helper'

describe "Node#attributes" do
  let(:alex) {
  }

  def wrap(&block)
    alex = Person.new('alex').tap { |p| p.age = 25; p }
    Node.new do
      object(:person => alex, &block)
    end
  end

  it "adds attributes of the person to the result hash" do
    node = wrap { attributes(:name, :age) }
    node.render!.should == {:person => {:name => 'alex', :age => 25}}
  end

  it "supports dynamic block attributes with explicit object context" do
    node = wrap do
      attribute(:oldness) do |person|
        "#{person.age} years"
      end
    end

    node.render!.should == {:person => {:oldness => "25 years"}}
  end

  it "supports dynamic block attributes with implicit object context" do
    node = wrap do
      attribute(:oldness) do
        "#{age} years"
      end
    end

    node.render!.should == {:person => {:oldness => "25 years"}}
  end

  it "raises an error when you use the block syntax with more than one attribute" do
    expect {
      wrap {
        attributes(:one, :two) do |person|
          "..."
        end
      }
    }.to raise_error(ArgumentError, "You may only pass one argument to #attribute when using the block syntax.")
  end

end

describe "Node#render!" do
  it "returns an empty hash when not passed an object" do
    Node.new.render!.should == {}
  end

  it "a document with a single node with no nesting" do
    node = Node.new do
      object :person => Person.new('alex') do
        attributes :name
      end
    end

    node.render!.should == {:person => {:name => 'alex'}}
  end

  it "works for multiple top-level objects" do
    alex, john = Person.new("alex"), Person.new("john")

    node = Node.new do
      object(:alex => alex) do
        attributes :name
      end

      object(:john => john) do
        attributes :name
      end
    end

    node.render!.should == {:alex => {:name => 'alex'}, :john => {:name => 'john'}}
  end

  it "recursively renders nested objects" do
    node = Node.new do
      object :alex => Person.new("alex") do
        attributes :name

        object :friend => Person.new("john") do
          attributes :name
        end
      end
    end

    node.render!.should == {
      :alex => {
        :name => 'alex',
        :friend => {:name => 'john'}
      }
    }
  end

  describe "#attributes syntax" do
    it "allows a hash to be sent where the keys are the result keys" do
      alex = Person.new("alex").tap do |p|
        p.age = 25
        p
      end

      node = Node.new do
        object(:person => alex) do
          attributes({:surname => :name}, :age)
        end
      end

      node.render!.should == {:person => {:surname => 'alex', :age => 25}}
    end
  end
end

describe "Node#object" do
  it "returns nil"
  it "evaluates the block stored inside"
end

describe "Node#to_json" do
  it "recursively returns the result json" do
    node = Node.new do
      object :person => Person.new("alex") do
        attributes :name

        object :friend => Person.new("pete", 30) do
          attributes :name, :age
        end
      end
    end

    node.to_json.should == jsonify({
      :person => {
        :name => 'alex',
        :friend => {:name => 'pete', :age => 30}
      }
    })
  end
end
