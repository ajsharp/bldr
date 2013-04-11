require 'spec_helper'

ERROR_MESSAGES = { :attribute_lambda_one_argument              => "You may only pass one argument to #attribute when using the block syntax.",
  :attribute_inferred_missing_one_argument    => "#attribute can't be used when there is no current_object.",
  :attribute_more_than_two_arg                => "You cannot pass more than two arguments to #attribute.",
  :attribute_inferred_missing_arity_too_large => "You cannot use a block of arity > 0 if current_object is not present.",
  :attributes_inferred_missing                => "No current_object to apply #attributes to." }

module Bldr
  describe Node, "#attributes" do
    let(:person) {
      Person.new('john', 25)
    }
    let(:node) { Bldr::Node.new(person) }

    it "returns stuff" do
      node.attribute(:age).should == node
    end
  end

  describe Node, "#attribute" do
    it "raises an exception when passed more than one argument and a block" do
      expect {
        Node.new {
          attribute(:one, :two) do |person|
            "..."
          end
        }
      }.to raise_error(ArgumentError, ERROR_MESSAGES[:attribute_lambda_one_argument])
    end

    it "raises an exception when passed more than two args" do
      expect {
        Node.new {
          attribute(:one, :two, :three)
        }
      }.to raise_error(ArgumentError, ERROR_MESSAGES[:attribute_more_than_two_arg])
    end

    it "errors on 1 argument since there is no inferred object" do
      expect {
        Node.new {
          attribute(:one)
        }
      }.to raise_error(ArgumentError, ERROR_MESSAGES[:attribute_inferred_missing_one_argument])
    end

    describe "wrapped in an object block" do
      it "renders 2 arguments statically" do
        node = Node.new do
          object :person do
            attribute(:name, "alex")
          end
        end
        node.result.should == {:person => {:name => 'alex'}}
      end

      it "renders 1 argument and one lambda with zero arity" do
        node = Node.new do
          object :person do
            attribute(:name) { "alex" }
          end
        end
        node.result.should == {:person => {:name => 'alex'}}
      end

      it "renders 1 argument to the inferred object" do
        node = Node.new do
          object :person => Person.new('alex', 25) do
            attribute(:name)
          end
        end
        node.result.should == {:person => {:name => 'alex'}}
      end

      it "renders 1 argument hash to the inferred object as the different key" do
        node = Node.new do
          object :person => Person.new('alex', 25) do
            attribute(:fake => :name)
          end
        end
        node.result.should == {:person => {:fake => 'alex'}}
      end

      it "renders 2 arguments statically" do
        node = Node.new do
          object :person => Person.new('alex', 25) do
            attribute(:name, 'ian')
          end
        end
        node.result.should == {:person => {:name => 'ian'}}
      end

      it "renders 1 argument and one lambda with zero arity" do
        node = Node.new do
          object :person => Person.new('alex', 25) do
            attribute(:name) { 'ian' }
          end
        end

        node.result.should == {:person => {:name => 'ian'}}
      end

      it "renders 1 argument and one lambda with arity 1" do
        node = Node.new do
          object :person => Person.new('alex', 25) do
            attribute(:name) { |person| person.name }
          end
        end

        node.result.should == {:person => {:name => 'alex'}}
      end

      it "renders nil attributes" do
        node = Node.new do
          object :person => Person.new('alex') do
            attribute :age
          end
        end

        node.result.should == {:person => {:age => nil}}
      end
    end

    describe 'when in static key-value form (with two arguments)' do
      it "renders 2 arguments statically as key, value" do
        node = Node.new { attribute(:name, "alex") }
        node.result.should == {:name => 'alex'}
      end

      it "renders null attributes to null, not 'null'" do
        node = Node.new { attribute(:name, nil) }
        node.result.should == {:name => nil}
      end
    end

    describe 'when in dynamic block form (with 1 argument and a block)' do
      it 'sets the attribute default context to bldr node' do
        node = Node.new { attribute(:key) { self.class } }
        node.result[:key].should == ::Bldr::Node
      end

      it "uses the argument as the key and the block result as the value" do
        node = Node.new {
          attribute(:name) do
            "alex"
          end
        }
        node.result.should == {:name => 'alex'}
      end

      it "errors on 1 argument and one lambda with arity 1" do
        expect {
          Node.new {
            attribute(:name) do |name|
              name
            end
          }
        }.to raise_error(ArgumentError, ERROR_MESSAGES[:attribute_inferred_missing_arity_too_large])
      end
    end

  end

  describe Node, "#object" do
    it 'renders the object structure for a nil object' do
      node = Node.new do
        object :person => nil do
          attributes :name
        end
        attribute(:foo) { "bar" }
      end
      node.result.should == {
        person: nil,
        foo: 'bar'
      }
    end

    it 'is passes block the block variable to the block' do
      denver = Person.new('John Denver')
      node = Node.new do
        object :person => denver do |jd|
          attribute(:name) { jd.name }
        end
      end

      node.result.should == {:person => {:name => 'John Denver'}}
    end

    context "rendering an object exactly as it exists" do
      it "renders the object exactly as it appears when passed an object with no block" do
        obj = {'key' => 'val', 'nested' => {'key' => 'val'}}
        node = node_wrap do
          object obj
        end
        node.result.should == obj
      end
    end

    context "a zero arg root object node" do

      def wrap(&block)
        Bldr::Node.new do
          object(&block)
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

          its(:result) { should == {:person => nil} }
        end

        it "renders each argument against the inferred object" do
          node = wrap { attributes(:name, :age) }
          node.result.should == {:person => {:name => 'alex', :age => 25}}
        end

        it "renders nil attributes" do
          node = node_wrap do
            object :person => Person.new('alex') do
              attributes :name, :age
            end
          end

          node.result.should == {:person => {:name => 'alex', :age => nil}}
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

        node.result.should == {:dude => {:name => 'alex', :bro => {:name => 'john'}}}
      end
    end

  end

  describe "Node#result" do
    it "returns an empty hash when not passed an object" do
      Bldr::Node.new.result.should == {}
    end

    it "a document with a single node with no nesting" do
      node = node_wrap do
        object :person => Person.new('alex') do
          attributes :name
        end
      end

      node.result.should == {:person => {:name => 'alex'}}
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

      node.result.should == {:alex => {:name => 'alex'}, :john => {:name => 'john'}}
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

      node.result.should == {
        :alex => {
          :name => 'alex', :friend => {:name => 'john'}
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

        node.result.should == {:person => {:surname => 'alex', :age => 25}}
      end
    end
  end

  describe Node, "#to_json" do
    it "recursively returns the result json" do
      node = node_wrap do
        object :person => Person.new("alex") do
          attributes :name

          object :friend => Person.new("pete", 30) do
            attributes :name, :age
          end
        end
      end

      node.result.should == {
        :person => {
          :name => 'alex',
          :friend => {:name => 'pete', :age => 30}
        }
      }
    end

    it "returns null values for nil attributes" do
      node = node_wrap do
        object :person => Person.new('alex') do
          attributes :name, :age
        end
      end

      node.result[:person].should have_key(:age)
      node.result[:person][:age].should be_nil
    end
  end

  describe Node, "#collection" do
    context "when passed an object with no block" do
      it "renders the object exactly as it exists" do
        coll = [{'key' => 'val'}]
        node = node_wrap do
          collection coll
        end

        node.result.should == coll
      end

      it "renders complex collection objects correctly" do
        hobbies = [{'name' => "Gym"}, {'name' => "Tan"}, {'name' => "Laundry"}]

        node = node_wrap do
          object 'person' => Person.new("Alex") do
            attribute :name
            collection 'hobbies' => hobbies
          end
        end

        node.result.should == {'person' => {:name => "Alex", 'hobbies' => hobbies}}
      end
    end

    it "iterates through the collection and passes each item as a block variable" do
      denver = Person.new('John Denver')
      songs = [Song.new('Rocky Mountain High'), Song.new('Take Me Home, Country Roads')]

      node = Node.new do
        object :artist => denver do
          attribute :name

          collection :songs => songs do |song|
            attribute(:name) { song.name }
          end
        end
      end

      node.result.should == {
        :artist => {:name => 'John Denver',
          :songs => [{:name => 'Rocky Mountain High'},
            {:name => 'Take Me Home, Country Roads'}
          ]
        }
      }
    end

    it "iterates through the collection and renders them as nodes" do
      node = node_wrap do
        object :person => Person.new('alex', 26) do
          attributes :name, :age

          collection :friends => [Person.new('john', 24), Person.new('jeff', 25)] do
            attributes :name, :age
          end
        end
      end

      node.result.should == {
        :person => {
          :name => 'alex', :age => 26,
          :friends => [
            {:name => 'john', :age => 24},
            {:name => 'jeff', :age => 25}]
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

      nodes.result.should == {:people => [{:name => 'bert'}, {:name => 'ernie'}]}
    end

    it "renders properly when a collection is the root node" do
      nodes = node_wrap do
        collection [Person.new('bert'), Person.new('ernie')] do
          attributes :name
        end
      end

      nodes.result.should == [{:name => 'bert'}, {:name => 'ernie'}]
    end

    it "gracefully handles empty collections" do
      nodes = node_wrap do
        collection :people => [] do
          attributes :name
        end
      end

      nodes.result.should == {:people => []}
    end

    it "gracefully handles nil collections" do
      nodes = node_wrap do
        collection :people => nil do
          attributes :name
        end
      end

      nodes.result.should == {:people => []}
    end

    it "renders nested collections properly" do
      post = Post.new("my post")
      post.comments << Comment.new('my comment')

      nodes = node_wrap do
        collection :posts => [post] do |post|
          attributes :title
          attribute(:comment_count) { |post| post.comments.count }

          collection :comments => post.comments do
            attributes :body
          end
        end
      end

      nodes.result.should == {
        :posts => [
          {:title => 'my post', :comment_count => 1, :comments => [{:body => 'my comment'}]}
        ]
      }
    end

    it "renders objects nested in collections properly" do
      post = Post.new 'foo'
      post.author = Author.new('John Doe')
      posts = [post]

      nodes = node_wrap do
        collection :data => posts do |post|
          attributes :title

          object :author => post.author do
            attributes :name
          end
        end
      end

      nodes.result.should == {
        :data => [
          {:title => 'foo', :author => {:name => 'John Doe'}}
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
        collection :posts => [post1, post2] do |post|
          attributes :title
          attribute(:comment_count) { |post| post.comments.count }

          collection :comments => post.comments do
            attributes :body
          end
        end
      end

      nodes.result.should == {
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

      node.result.should == {:name => 'john doe', :age => 25}
    end

  end

  describe Node, "#template" do
    it "includes the partial as a top level" do
      nodes = node_wrap do
        template "spec/fixtures/partial.json.bldr"
      end

      nodes.result.should == {:foo => "bar"}
    end

    it "includes the partial on a top level object" do
      nodes = node_wrap do
        object :container do
          attribute(:blah) { "baz" }
          template "spec/fixtures/partial.json.bldr"
        end
      end

      nodes.result.should == {:container => {:blah => "baz", :foo => "bar"}}
    end

    it "includes the partial on a top level collection" do
      nodes = node_wrap do
        collection :people => [Person.new('bert'), Person.new('ernie')] do
          attribute(:blah) { "baz" }
          template "spec/fixtures/partial.json.bldr"
        end
      end

      nodes.result.should == {:people => [{:blah => "baz", :foo => 'bar'}, {:blah => "baz", :foo => 'bar'}]}
    end

    it "includes the partial on a sub object" do
      nodes = node_wrap do
        object :container do
          object :sub do
            attribute(:blah) { "baz" }
            template "spec/fixtures/partial.json.bldr"
          end
        end
      end

      nodes.result.should == {:container => {:sub => {:blah => "baz", :foo => "bar"}}}
    end

    it "includes the partial on a sub collection" do
      nodes = node_wrap do
        object :container do
          collection :people => [Person.new('bert'), Person.new('ernie')] do
            attribute(:blah) { "baz" }
            template "spec/fixtures/partial.json.bldr"
          end
        end
      end

      nodes.result.should == {:container => {:people => [{:blah => "baz", :foo => 'bar'}, {:blah => "baz", :foo => 'bar'}]}}
    end

    it "includes both the partials" do
      nodes = node_wrap do
        object :container do
          template "spec/fixtures/partial.json.bldr"
          object :sub do
            attribute(:blah) { "baz" }
            template "spec/fixtures/partial.json.bldr"
          end
        end
      end

      nodes.result.should == {:container => {:foo => "bar", :sub => {:blah => "baz", :foo => "bar"}}}
    end

    it "includes the partial with the locals" do
      Obj = Struct.new(:foo)
      nodes = node_wrap do
        template "spec/fixtures/partial_with_locals.json.bldr", :locals => {:obj => Obj.new('test')}
      end

      nodes.result.should == {:name => {:foo => 'test'}}
    end

    it "raises an error when the partial isn't found" do
      expect {
        nodes = node_wrap do
          template "unknown/path"
        end
      }.to raise_error(Errno::ENOENT)
    end

    it "doesn't raise an error when with a base path option specified and the right file" do
      nodes = node_wrap nil, :views => 'spec/fixtures/some' do
        object :foo do
          template "include"
        end
      end
    end
  end

  describe Node, "#locals" do
    let(:node) { Bldr::Node.new({:foo => 'bar'}, :locals => {:key => 'val'})}
    subject { node.locals }

    it { should == {:key => 'val'} }
  end

  describe Node, '#current_object' do
    it 'returns the node value' do
      Node.new('hey').current_object.should == 'hey'
    end

    it 'displays a deprecation warning' do
      Object.any_instance.should_receive(:warn).with("[DEPRECATION] `current_object` is deprecated. Please use object or collection block varibles instead.")
      Node.new.current_object
    end
  end
end
