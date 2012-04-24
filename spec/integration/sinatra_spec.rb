require 'spec_helper'


describe "Using Bldr with a sinatra app" do
  require 'sinatra/bldr'

  class TestApp < Sinatra::Base
    register Sinatra::Bldr

    set :views, File.expand_path(__FILE__ + '/../..')
    disable :show_exceptions
    enable  :raise_errors

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

    get '/template' do
      bert  = Person.new('bert', 25)
      ernie = Person.new('ernie', 26)
      bldr :'fixtures/nested_objects.json', :locals => {:bert => bert, :ernie => ernie}
    end

    get '/root_template' do
      name = "john doe"
      age  = 26

      bldr :'fixtures/root_template.json', :locals => {:name => name, :age => age}
    end

    get '/root_partial' do
      bldr :'fixtures/root_partial'
    end
  end

  it "properly renders a template that only contains a template call" do
    response = Rack::MockRequest.new(TestApp).get('/root_partial')
    MultiJson.decode(response.body).should == {'foo' => 'bar'}
  end

  it "returns json for a simple single-level template" do
    request = Rack::MockRequest.new(TestApp)
    response = request.get '/'
    response.status.should == 200
    parse_json(response.body).should == {'dude' => {'name' => 'alex', 'age' => 25}}
  end

  it "properly serializes templates with collections" do
    request = Rack::MockRequest.new(TestApp)
    response = request.get '/collections'

    response.status.should == 200
    parse_json(response.body).should == {
      'person'=> {'name' => 'alex', 'age' => 25, 'friends' => [{'name' => 'john', 'age' => 24}]}
    }
  end

  it "works with template files" do
    request = Rack::MockRequest.new(TestApp)
    response = request.get '/template'

    parse_json(response.body).should == {
      'person' => {'name' => 'bert', 'age' => 25, 'name_age' => "bert 25",
        'friend' => {'name' => 'ernie', 'age' => 26}
      }
    }
  end

  it "allows using root-level attributes" do
    request = Rack::MockRequest.new(TestApp)
    response = request.get '/root_template'

    parse_json(response.body).should == {'name' => 'john doe', 'age' => 26}
  end
end

describe "access to the locals hash inside sinatra bldr templates" do
  class Locals < BaseTestApp
    disable :show_exceptions
    enable  :raise_errors

    get '/' do
      tpl = <<-RUBY
        object(:locals) do
          attribute(:key) { locals[:key] }
        end
      RUBY

      bldr tpl, :locals => {:key => 'val'}
    end
  end

  it "provides access to the locals hash in the template" do
    response = Rack::MockRequest.new(Locals).get('/')
    MultiJson.decode(response.body)['locals']['key'].should == 'val'
  end
end