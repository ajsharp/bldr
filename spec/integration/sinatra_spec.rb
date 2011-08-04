require 'spec_helper'


describe "Using Bldr with a sinatra app" do
  require 'sinatra/bldr'

  class TestApp < Sinatra::Base
    register Sinatra::Bldr

    get '/' do
      alex =  Person.new("alex", 25)
      tpl = <<-RUBY
        object(:dude => alex) do
          attributes :name, :age
        end
      RUBY

      status(200)
      bldr tpl, :locals => {:alex => alex}
    end

    get '/collections' do
      alex = Person.new('alex', 25)

      tpl = <<-RUBY
        object :person => alex do
          attributes :name, :age

          collection :friends => [Person.new("john", 24)] do
            attributes :name, :age
          end
        end
      RUBY

      bldr tpl, :locals => {:alex => alex}
    end
  end

  it "returns json for a simple single-level template" do
    request = Rack::MockRequest.new(TestApp)
    response = request.get '/'
    response.status.should == 200
    response.body.should == jsonify({'dude' => {'name' => 'alex', 'age' => 25}})
  end

  it "properly serializes templates with collections" do
    request = Rack::MockRequest.new(TestApp)
    response = request.get '/collections'

    response.status.should == 200
    response.body.should == jsonify({
      'person'=> {'name' => 'alex', 'age' => 25, 'friends' => [{'name' => 'john', 'age' => 24}]}
    })
  end
end
