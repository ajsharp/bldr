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

    def it_renders_template_to_hash(template,hash)
      tpl  = Bldr::Template.new {template}
      result = tpl.render(Bldr::Node.new)
      result.should == jsonify(hash)
    end

    describe "attribute" do

      it "renders two static attributes" do
        tpl = %| object do
                   attribute :url, "http://google.com"
                 end |
        it_renders_template_to_hash(tpl,{'url' => 'http://google.com'})
      end

      it "renders one attribute and one lambda" do
        tpl = %| object do
                   attribute(:url) {"http://google.com"}
                 end |
        it_renders_template_to_hash(tpl,{'url' => 'http://google.com'})
      end

      it "raises an error when only one argument is passed" do
        tpl = %| object do
                   attribute :url
                 end |
        expect {
          it_renders_template_to_hash(tpl,{})
        }.to raise_error(ArgumentError, "You cannot pass one argument to #attribute when inferred object is not present.")
      end

      it "raises an error when you send a lambda to an attribute with two arguments" do
        tpl = %| object do
                   attribute(:url,"http://foo.com") {"http://google.com"}
                 end |
        expect {
          it_renders_template_to_hash(tpl,{})
        }.to raise_error(ArgumentError, "You may only pass one argument to #attribute when using the block syntax.")
      end

      it "raises an error when you send more than 2 arguments" do
        tpl = %| object do
                   attribute :url, :something, :something_else
                 end |
        expect {
          it_renders_template_to_hash(tpl,{})
        }.to raise_error(ArgumentError, "You cannot pass more than two arguments to #attribute.")
      end

    end

    describe "attributes" do
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
      parse_json(result).should == {'person' => {'name' => 'alex', 'age' => 25}}
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
      parse_json(result).should == {
        'person'=> {'name' => 'alex', 'age' => 25, 'friends' => [{'name' => 'ian', 'age' => 32}]}
      }
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
      parse_json(result).should == {
        'people'=> [{'name' => 'alex', 'age' => 25},{'name' => 'ian', 'age' => 32}]
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
      result = tpl.render(Bldr::Node.new, :people => [alex,ian])
      parse_json(result).should == {
        'people'=> [{
          'name' => 'alex',
          'age' => 25,
          "friends" => [{"name" => 'bo', "age" => 33}]
        },{
          'name' => 'ian',
          'age' => 32,
          "friends" => [{"name" => 'eric', "age" => 34}]
        }]
      }
    end

  end
end
