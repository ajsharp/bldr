require 'spec_helper'

describe "evaluating a tilt template" do
  it "registers with Tilt" do
    Tilt['test.bldr'].should == Bldr::Template
  end

  it "renders a template" do
    alex = Person.new
    alex.name = 'alex'

    tpl = Bldr::Template.new { "object(:person => alex) { attribute(:name) }" }
    tpl.render(Node.new, :alex => alex).should == jsonify({:person => {:name => 'alex'}})
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

    result = tpl.render(Node.new, :alex => alex, :john => john)
    result.should == jsonify({
      :person_1 => {:name => 'alex'},
      :person_2 => {:name => 'john'}
    })
  end
end
