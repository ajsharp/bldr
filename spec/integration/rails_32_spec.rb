require 'spec_helper'
require 'rails'
require 'action_controller/railtie'
require 'bldr/railtie'

describe 'a template for a rails controller' do
  TestRailsApp = Class.new(Rails::Application) do
    routes.append do
      resources :people
    end

    config.secret_token = "secret"
    config.session_store = :disabled
    config.active_support.deprecation = nil
    config.middleware.delete 'ActionDispatch::Session::CookieStore'
  end

  class PeopleController < ActionController::Base
    helper_method :boss?

    # GET /people
    def index
      @people = [Person.new('Dave Chappelle'), Person.new('Chris Rock')]
      render 'spec/fixtures/templates/rails/people/index', handlers: [:bldr], formats: [:json]
    end

    # GET /people/:id
    def show
      @person = Person.new('Dave Chappelle')
      render 'spec/fixtures/templates/rails/people/show', handlers: [:bldr], formats: [:json]
    end

    private
    def boss?(person)
      person.name == 'Dave Chappelle'
    end
  end

  TestRailsApp.initialize!

  def app
    TestRailsApp.app
  end

  def get(url)
    Rack::MockRequest.new(app).get(url)
  end

  def decode(d)
    MultiJson.decode(d)
  end

  it 'returns 200' do
    get('/people').status.should == 200
  end

  it 'returns a json thing' do
    decode(get('/people').body).should == [
      {'name' => 'Dave Chappelle'},
      {'name' => 'Chris Rock'}
    ]
  end

  it 'returns json content type' do
    get('/people').content_type.should =~ %r{application/json}
  end

  it 'has access to controller helper methods' do
    response = get('/people/123?use_boss_helper=true')
    response.status.should == 200
    decode(response.body).should == {
      'id'   => '123',
      'name' => 'Dave Chappelle',
      'boss' => true
    }
  end

  it 'has access to params' do
    decode(get('/people/123').body).should == {
      'id' => '123',
      'name' => 'Dave Chappelle'
    }
  end
end
