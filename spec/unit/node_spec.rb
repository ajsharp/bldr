require 'spec_helper'

ERROR_MESSAGES = { :attribute_lambda_one_argument              => "You may only pass one argument to #attribute when using the block syntax.",
                   :attribute_inferred_missing_one_argument    => "#attribute can't be used when there is no current_object.",
                   :attribute_more_than_two_arg                => "You cannot pass more than two arguments to #attribute.",
                   :attribute_inferred_missing_arity_too_large => "You cannot use a block of arity > 0 if current_object is not present.",
                   :attributes_inferred_missing                => "No current_object to apply #attributes to." }

describe "Node#object" do

  context "a zero arg root object node" do

    def wrap(&block)
      Bldr::Node.new do
        object(&block)
      end
    end

    describe "#attribute" do

      it "errors on a single argument" do
        expect {
          node_wrap {
            attribute(:one, :two) do |person|
              "..."
            end
          }
        }.to raise_error(ArgumentError, ERROR_MESSAGES[:attribute_lambda_one_argument])
      end
      it "errors on 3 arguments" do
        expect {
          node_wrap {
            attribute(:one, :two, :three)
          }
        }.to raise_error(ArgumentError, ERROR_MESSAGES[:attribute_more_than_two_arg])
      end
      it "errors on 2 arguments and a lambda" do
        expect {
          node_wrap {
            attribute(:one, :two) do |person|
              "..."
            end
          }
        }.to raise_error(ArgumentError, ERROR_MESSAGES[:attribute_lambda_one_argument])
      end
      it "errors on 1 argument since there is no inferred object" do
        expect {
          node_wrap {
            attribute(:one)
          }
        }.to raise_error(ArgumentError, ERROR_MESSAGES[:attribute_inferred_missing_one_argument])
      end
      it "renders 2 arguments statically" do
        node = wrap { attribute(:name, "alex") }
        node.render!.should == {:name => 'alex'}
      end
      it "renders 1 argument and one lambda with zero arity" do
        node = wrap {
          attribute(:name) do
            "alex"
          end
        }
        node.render!.should == {:name => 'alex'}
      end
      it "errors on 1 argument and one lambda with arity 1" do
        expect {
          node_wrap {
            attribute(:name) do |name|
              name
            end
          }
        }.to raise_error(ArgumentError, ERROR_MESSAGES[:attribute_inferred_missing_arity_too_large])
      end
      it "should render null attributes to null, not 'null'" do
        node = wrap { attribute(:name, nil) }
        node.render!.should == {:name => nil}
      end

    end

    describe "#attributes" do

      it "errors since current_object is nil" do
        expect {
          node_wrap {
            attributes(:name)
          }
        }.to raise_error(ArgumentError, ERROR_MESSAGES[:attributes_inferred_missing])
      end

    end

  end

  context "a single arg root object node" do

    def wrap(&block)
      Bldr::Node.new do
        object(:person, &block)
      end
    end

    describe "#attribute" do

      it "errors on a single argument" do
        expect {
          node_wrap {
            attribute(:one, :two) do |person|
              "..."
            end
          }
        }.to raise_error(ArgumentError, ERROR_MESSAGES[:attribute_lambda_one_argument])
      end
      it "errors on 3 arguments" do
        expect {
          node_wrap {
            attribute(:one, :two, :three)
          }
        }.to raise_error(ArgumentError, ERROR_MESSAGES[:attribute_more_than_two_arg])
      end
      it "errors on 2 arguments and a lambda" do
        expect {
          node_wrap {
            attribute(:one, :two) do |person|
              "..."
            end
          }
        }.to raise_error(ArgumentError, ERROR_MESSAGES[:attribute_lambda_one_argument])
      end
      it "errors on 1 argument since there is no inferred object" do
        expect {
          node_wrap {
            attribute(:one)
          }
        }.to raise_error(ArgumentError, ERROR_MESSAGES[:attribute_inferred_missing_one_argument])
      end
      it "renders 2 arguments statically" do
        node = wrap { attribute(:name, "alex") }
        node.render!.should == {:person => {:name => 'alex'}}
      end
      it "renders 1 argument and one lambda with zero arity" do
        node = wrap {
          attribute(:name) do
            "alex"
          end
        }
        node.render!.should == {:person => {:name => 'alex'}}
      end
      it "errors on 1 argument and one lambda with arity 1" do
        expect {
          node_wrap {
            attribute(:name) do |name|
              name
            end
          }
        }.to raise_error(ArgumentError, ERROR_MESSAGES[:attribute_inferred_missing_arity_too_large])
      end
    end

    describe "#attributes" do

      it "errors since current_object is nil" do
        expect {
          node_wrap {
            attributes(:name)
          }
        }.to raise_error(ArgumentError, ERROR_MESSAGES[:attributes_inferred_missing])
      end

    end

  end

  context "a hash-arg root object node" do

    def wrap(&block)
      alex = Person.new('alex').tap { |p| p.age = 25; p }
      Bldr::Node.new do
        object(:person => alex, &block)
      end
    end

    describe "#attribute" do

      it "errors on 3 arguments" do
        expect {
          node_wrap {
            attribute(:one, :two, :three)
          }
        }.to raise_error(ArgumentError, ERROR_MESSAGES[:attribute_more_than_two_arg])
      end
      it "errors on 2 arguments and a lambda" do
        expect {
          node_wrap {
            attribute(:one, :two) do |person|
              "..."
            end
          }
        }.to raise_error(ArgumentError, ERROR_MESSAGES[:attribute_lambda_one_argument])
      end
      it "renders 1 argument to the inferred object" do
        node = wrap { attribute(:name) }
        node.render!.should == {:person => {:name => 'alex'}}
      end
      it "renders 1 argument hash to the inferred object as the different key" do
        node = wrap { attribute(:fake => :name) }
        node.render!.should == {:person => {:fake => 'alex'}}
      end
      it "renders 2 arguments statically" do
        node = wrap { attribute(:name, "ian") }
        node.render!.should == {:person => {:name => 'ian'}}
      end
      it "renders 1 argument and one lambda with zero arity" do
        node = wrap { attribute(:name){"ian"} }
        node.render!.should == {:person => {:name => 'ian'}}
      end
      it "renders 1 argument and one lambda with arity 1" do
        node = wrap { attribute(:name){|person| person.name} }
        node.render!.should == {:person => {:name => 'alex'}}
      end
      it "renders nil attributes" do
        node = node_wrap do
          object :person => Person.new('alex') do
            attribute :age
          end
        end

        node.render!.should == {:person => {:age => nil}}
      end

    end

    describe "#attributes" do
      describe "when an object key is passed a null value" do
        subject {
          node = node_wrap do
            object(:person => nil) do
              attributes(:one, :two) do |person|
                "..."
              end
            end
          end
        }

        it "does not raise an inferred object error" do
          expect {
            subject
          }.not_to raise_error(ArgumentError, ERROR_MESSAGES[:attributes_inferred_missing])
        end

        its(:result) { should == {} }
      end

      it "renders each argument against the inferred object" do
        node = wrap { attributes(:name, :age) }
        node.render!.should == {:person => {:name => 'alex', :age => 25}}
      end
      it "renders nil attributes" do
        node = node_wrap do
          object :person => Person.new('alex') do
            attributes :name, :age
          end
        end

        node.render!.should == {:person => {:name => 'alex', :age => nil}}
      end

    end

  end

  describe "embedded objects" do
    it "evaluates the block and returns json" do
      node = node_wrap do
        object(:dude => Person.new("alex")) do
          attributes :name

          object(:bro => Person.new("john")) do
            attributes :name
          end
        end
      end

      node.render!.should == {:dude => {:name => 'alex', :bro => {:name => 'john'}}}
    end
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

  # @todo fix this
  it "renders properly when a collection is the named root node" do
    nodes = node_wrap do
      collection :people => [Person.new('bert'), Person.new('ernie')] do
        attributes :name
      end
    end

    nodes.render!.should == {:people => [{:name => 'bert'}, {:name => 'ernie'}]}
  end

  it "renders properly when a collection is the root node" do
    nodes = node_wrap do
      collection [Person.new('bert'), Person.new('ernie')] do
        attributes :name
      end
    end

    nodes.render!.should == [{:name => 'bert'}, {:name => 'ernie'}]
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

describe "Node#partial" do
  it "includes the partial as a top level" do
    nodes = node_wrap do
      render "spec/fixtures/partial.json.bldr"
    end

    nodes.render!.should == {:foo => "bar"}
  end
  
  it "includes the partial on a top level object" do
    nodes = node_wrap do
      object :container do
        attribute(:blah) { "baz" }
        render "spec/fixtures/partial.json.bldr"
      end
    end

    nodes.render!.should == {:container => {:blah => "baz", :foo => "bar"}}
  end
  
  it "includes the partial on a top level collection" do
    nodes = node_wrap do
      collection :people => [Person.new('bert'), Person.new('ernie')] do
        attribute(:blah) { "baz" }
        render "spec/fixtures/partial.json.bldr"
      end
    end

    nodes.render!.should == {:people => [{:blah => "baz", :foo => 'bar'}, {:blah => "baz", :foo => 'bar'}]}
  end
  
  it "includes the partial on a sub object" do
    nodes = node_wrap do
      object :container do
        object :sub do
          attribute(:blah) { "baz" }
          render "spec/fixtures/partial.json.bldr"
        end
      end
    end

    nodes.render!.should == {:container => {:sub => {:blah => "baz", :foo => "bar"}}}
  end
  
  it "includes the partial on a sub collection" do
    nodes = node_wrap do
      object :container do
        collection :people => [Person.new('bert'), Person.new('ernie')] do
          attribute(:blah) { "baz" }
          render "spec/fixtures/partial.json.bldr"
        end
      end
    end

    nodes.render!.should == {:container => {:people => [{:blah => "baz", :foo => 'bar'}, {:blah => "baz", :foo => 'bar'}]}}
  end
  
  it "includes both the partials" do
    nodes = node_wrap do
      object :container do
        render "spec/fixtures/partial.json.bldr"
        object :sub do
          attribute(:blah) { "baz" }
          render "spec/fixtures/partial.json.bldr"
        end
      end
    end

    nodes.render!.should == {:container => {:foo => "bar", :sub => {:blah => "baz", :foo => "bar"}}}
  end
  
end