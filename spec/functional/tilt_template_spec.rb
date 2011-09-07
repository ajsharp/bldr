require 'spec_helper'

describe "evaluating a tilt template" do
  it "registers with Tilt" do
    Tilt['test.bldr'].should == Bldr::Template
  end

  it "renders a template" do
    alex = Person.new
    alex.name = 'alex'

    tpl = Bldr::Template.new { "object(:person => alex) { attribute(:name) }" }
    tpl.render(Bldr::Node.new, :alex => alex).should == jsonify({:person => {:name => 'alex'}})
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

    result = tpl.render(Bldr::Node.new, :alex => alex, :john => john)
    result.should == jsonify({
      :person_1 => {:name => 'alex'},
      :person_2 => {:name => 'john'}
    })
  end

  describe "root Object nodes" do

    let(:alex) { Person.new('alex', 25) }
    let(:ian) { Person.new('ian', 32) }

    it "returns json for a blank root object " do
      tpl  = Bldr::Template.new {
        <<-RUBY
          object do
            attribute(:url) {"http://google.com"}
          end
        RUBY
      }
      result = tpl.render(Bldr::Node.new)
      result.should == jsonify({'url' => 'http://google.com'})
    end

    it "returns json for a root object" do
      tpl = Bldr::Template.new {
        <<-RUBY
          object :person => alex do
            attributes :name, :age
          end
        RUBY
      }
      result = tpl.render(Bldr::Node.new, :alex => alex, :ian => ian)
      result.should == jsonify({'person' => {'name' => 'alex', 'age' => 25}})
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
      result = tpl.render(Bldr::Node.new, :alex => alex, :friends => [ian])
      result.should == jsonify({
        'person'=> {'name' => 'alex', 'age' => 25, 'friends' => [{'name' => 'ian', 'age' => 32}]}
      })
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
      result = tpl.render(Bldr::Node.new, :people => [alex,ian])
      result.should == jsonify({
        'people'=> [{'name' => 'alex', 'age' => 25},{'name' => 'ian', 'age' => 32}]
      })
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
      result = tpl.render(Bldr::Node.new, :people => [alex,ian])
      result.should == jsonify({
        'people'=> [{
          'name' => 'alex',
          'age' => 25,
          "friends" => [{"name" => 'bo', "age" => 33}]
        },{
          'name' => 'ian',
          'age' => 32,
          "friends" => [{"name" => 'eric', "age" => 34}]
        }]
      })
    end

  end
end
