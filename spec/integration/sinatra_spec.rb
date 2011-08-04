require 'spec_helper'


describe "Using Bldr with a sinatra app" do
  require 'sinatra/bldr'

  class TestApp < Sinatra::Base
    enable :raise_errors
    enable :show_exceptions

    register Sinatra::Bldr

    get '/' do
      alex =  Person.new("alex", 25)
      tpl = <<-RUBY
        object(:dude => alex) do
          attributes :name, :age
        end
      RUBY

      status(200)
      bldr tpl, {}, :alex => alex
    end
  end

  it "returns json for a simple single-level template" do
    request = Rack::MockRequest.new(TestApp)
    response = request.get '/'
    response.status.should == 200
    parse_json(response.body).should == {'dude' => {'name' => 'alex', 'age' => 25}}
  end
end
