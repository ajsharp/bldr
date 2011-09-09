require 'spec_helper'

describe "Node#attributes" do
  def wrap(&block)
    alex = Person.new('alex').tap { |p| p.age = 25; p }
    Bldr::Node.new do
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
      node_wrap {
        attributes(:one, :two) do |person|
          "..."
        end
      }
    }.to raise_error(ArgumentError, "You may only pass one argument to #attribute when using the block syntax.")
  end

  it "returns nil attributes in the result" do
    node = node_wrap do
      object :person => Person.new('alex') do
        attributes :name, :age
      end
    end

    node.render!.should == {:person => {:name => 'alex', :age => nil}}
  end

end

describe "Node#render!" do
  it "returns an empty hash when not passed an object" do
    Bldr::Node.new.render!.should == {}
  end

  it "a document with a single node with no nesting" do
    node = node_wrap do
      object :person => Person.new('alex') do
        attributes :name
      end
    end

    node.render!.should == {:person => {:name => 'alex'}}
  end

  it "works for multiple top-level objects" do
    alex, john = Person.new("alex"), Person.new("john")

    node = node_wrap do
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
    node = node_wrap do
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

      node = node_wrap do
        object(:person => alex) do
          attributes({:surname => :name}, :age)
        end
      end

      node.render!.should == {:person => {:surname => 'alex', :age => 25}}
    end
  end
end

describe "Node#object" do
  it "evaluates the block and returns json" do
    node = Bldr::Node.new
    result = node.object(:dude => Person.new("alex")) do
      attributes :name

      object(:bro => Person.new("john")) do
        attributes :name
      end
    end

    result.should == jsonify({
      :dude => {:name => 'alex', :bro => {:name => 'john'}}
    })
  end
end

describe "Node#to_json" do
  it "recursively returns the result json" do
    node = node_wrap do
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

  it "returns null values for nil attributes" do
    node = node_wrap do
      object :person => Person.new('alex') do
        attributes :name, :age
      end
    end

    parse_json(node.to_json)['person'].should have_key('age')
    parse_json(node.to_json)['person']['age'].should be_nil
  end
end

describe "Node#collection" do
  it "iterates through the collection and renders them as nodes" do
    node = node_wrap do
      object :person => Person.new('alex', 26) do
        attributes :name, :age

        collection :friends => [Person.new('john', 24), Person.new('jeff', 25)] do
          attributes :name, :age
        end
      end
    end

    node.render!.should == {
      :person => {
        :name => 'alex', :age => 26,
        :friends => [{:name => 'john', :age => 24}, {:name => 'jeff', :age => 25}]
      }
    }
  end

  it "renders properly when a collection is the root node" do
    nodes = node_wrap do
      collection :people => [Person.new('bert'), Person.new('ernie')] do
        attributes :name
      end
    end

    nodes.render!.should == {:people => [{:name => 'bert'}, {:name => 'ernie'}]}
  end

  it "gracefully handles empty collections" do
    nodes = node_wrap do
      collection :people => [] do
        attributes :name
      end
    end

    nodes.render!.should == {:people => []}
  end

  it "gracefully handles nil collections" do
    nodes = node_wrap do
      collection :people => nil do
        attributes :name
      end
    end

    nodes.render!.should == {:people => []}
  end

  it "renders nested collections properly" do
    post = Post.new("my post")
    post.comments << Comment.new('my comment')

    nodes = node_wrap do
      collection :posts => [post] do
        attributes :title
        attribute(:comment_count) { |post| post.comments.count }

        collection :comments => current_object.comments do
          attributes :body
        end
      end
    end

    nodes.render!.should == {
      :posts => [
        {:title => 'my post', :comment_count => 1, :comments => [{:body => 'my comment'}]}
      ]
    }
  end

  it "renders nested collections with dynamic property values correctly" do
    post1 = Post.new("post 1")
    post2 = Post.new("post 2")
    post1.comments << Comment.new('post 1 comment')
    post2.comments << Comment.new('post 2 first comment')
    post2.comments << Comment.new('post 2 second comment')

    nodes = node_wrap do
      collection :posts => [post1, post2] do
        attributes :title
        attribute(:comment_count) { |post| post.comments.count }

        collection :comments => current_object.comments do
          attributes :body
        end
      end
    end

    nodes.render!.should == {
      :posts => [
        {
          :title => 'post 1',
          :comment_count => 1,
          :comments => [{:body => 'post 1 comment'}]
        },
        {
          :title => 'post 2',
          :comment_count => 2,
          :comments => [{:body => 'post 2 first comment'}, {:body => 'post 2 second comment'}]
        }
      ]
    }
  end

  it "allows root level attributes using local variables" do
    node = node_wrap do
      name = "john doe"
      age  = 25

      object do
        attribute(:name) { name }
        attribute(:age) { age }
      end
    end

    node.render!.should == {:name => 'john doe', :age => 25}
  end

end
