require 'spec_helper'

module Bldr
  describe "instance variables" do
    let(:ctx) { Object.new }

    it 'has access to instance variables in include template partials' do
      ctx.instance_variable_set(:@person, Person.new('john denver'))

      Template.new {
        <<-RUBY
         template('spec/fixtures/ivar.bldr')
        RUBY
      }.render(Node.new(nil, :parent => ctx))
      .result
      .should == {:person => {:name => 'john denver', :age => nil}}
    end

    it 'has access to ivars in attribute blocks with no arity' do
      ctx.instance_variable_set(:@person, Person.new('john denver'))

      Template.new {
        <<-RUBY
         object :person do
           attribute(:name) { @person.name }
         end
        RUBY
      }.render(Node.new(nil, :parent => ctx))
      .result
      .should == {:person => {:name => 'john denver'}}
    end

    it 'has access to ivars in attribute blocks with arity of 1' do
      ctx.instance_variable_set(:@denver, Person.new('john denver'))
      ctx.instance_variable_set(:@rich, Person.new('charlie rich'))
      Template.new {
        <<-RUBY
         object :person => @denver do
           attribute(:name) { |p| @rich.name }
         end
        RUBY
      }.render(Node.new(nil, :parent => ctx))
      .result
      .should == {:person => {:name => 'charlie rich'}}
    end
  end


  describe "evaluating a tilt template" do
    it "registers with Tilt" do
      Tilt['test.bldr'].should == Bldr::Template
    end

    it "renders a template" do
      alex = Person.new
      alex.name = 'alex'

      tpl = Bldr::Template.new { "object(:person => alex) { attribute(:name) }" }
      tpl.render(Bldr::Node.new, :alex => alex).result.should == {:person => {:name => 'alex'}}
    end

    it "allows attribute to be used at the root-level" do
      tpl = Bldr::Template.new {
      <<-RUBY
        attribute(:foo) { "bar" }
      RUBY
      }
      tpl.render(Bldr::Node.new(nil)).result.should == {:foo => 'bar'}
    end

    it "works when render two top-level objects" do
      alex = Person.new('alex')
      john = Person.new('john')

      tpl = Bldr::Template.new {
      <<-RUBY
        object(:person_1 => alex) { attribute(:name) }
        object(:person_2 => john) { attribute(:name) }
      RUBY
      }

      result = tpl.render(Bldr::Node.new, :alex => alex, :john => john).result
      result.should == {
                        :person_1 => {:name => 'alex'},
                        :person_2 => {:name => 'john'}
                       }
    end

    it "renders nil -> null correctly" do
      alex = Person.new('alex')
      tpl = Bldr::Template.new {
      <<-RUBY
        object(:person_1 => alex) { attributes(:age) }
      RUBY
      }
      result = tpl.render(Bldr::Node.new, :alex => alex).result
      result.should == {:person_1 => {:age => nil}}
    end

    describe "root Object nodes" do

      let(:alex) { Person.new('alex', 25) }
      let(:ian) { Person.new('ian', 32) }

      it "returns json for a root object" do
        tpl = Bldr::Template.new {
        <<-RUBY
          object :person => alex do
            attributes :name, :age
          end
        RUBY
        }
        result = tpl.render(Bldr::Node.new, :alex => alex, :ian => ian).result
        result.should == {:person => {:name => 'alex', :age => 25}}
      end

      it "returns json for root object templates with nested collections" do
        tpl = Bldr::Template.new {
        <<-RUBY
          object :person => alex do
            attributes :name, :age

            collection :friends => friends do
              attributes :name, :age
            end
          end
        RUBY
        }
        result = tpl.render(Bldr::Node.new, :alex => alex, :friends => [ian]).result
        result.should == {
                          :person=> {:name => 'alex', :age => 25, :friends => [{:name => 'ian', :age => 32}]}
                         }
      end

      it "renders nil -> null correctly" do
        alex = Person.new('alex')
        tpl = Bldr::Template.new {
        <<-RUBY
          object :person_1 => alex do
            attributes(:age)
          end
        RUBY
        }
        result = tpl.render(Bldr::Node.new, :alex => alex).result
        result.should == {:person_1 => {:age => nil}}
      end

    end

    describe "root Collection nodes" do

      let(:alex) { Person.new('alex', 25, [Person.new('bo',33)]) }
      let(:ian) { Person.new('ian', 32, [Person.new('eric',34)]) }

      it "returns json for a root collection template" do
        tpl = Bldr::Template.new {
        <<-RUBY
          collection :people => people do
            attributes :name, :age
          end
        RUBY
        }
        result = tpl.render(Bldr::Node.new, :people => [alex,ian]).result
        result.should == {
                          :people => [{:name => 'alex', :age => 25}, {:name => 'ian', :age => 32}]
                         }
      end

      it "returns json for a root collection with embedded collection template" do
        tpl = Bldr::Template.new {
        <<-RUBY
          collection :people => people do
            attributes :name, :age
            collection :friends => current_object.friends do
              attributes :name, :age
            end
          end
        RUBY
        }
        result = tpl.render(Bldr::Node.new, :people => [alex,ian]).result
        result.should == {
                          :people=> [{
                                      :name => 'alex',
                                      :age => 25,
                                      :friends => [{:name => 'bo', :age => 33}]
                                     },{
                                        :name => 'ian',
                                        :age => 32,
                                        :friends => [{:name => 'eric', :age => 34}]
                                       }]
                         }
      end

    end
  end

  describe "using a partial template at the root of another template" do
    it "works as expected" do
      template = Bldr::Template.new('./spec/fixtures/root_partial.bldr')
      template.render(Bldr::Node.new(nil, :views => './spec')).result.should == {:foo => 'bar'}
    end
  end
end
