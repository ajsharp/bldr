require 'spec_helper'

describe "the json encoding library" do
  it "uses yajl by default" do
    MultiJson.engine.should == MultiJson::Adapters::Yajl
  end

  it "allows changing the json encoder to json pure" do
    Bldr.json_encoder = :json_pure
    MultiJson.engine.should == MultiJson::Adapters::JsonPure
  end

  it "allows changing the json encoder to the json gem" do
    Bldr.json_encoder = :json_gem
    MultiJson.engine.should == MultiJson::Adapters::JsonGem
  end

end

describe "defining custom handlers" do

  describe "erroneously" do

    it "errors when you don't pass a class arg" do
      expect {
        Bldr.handler {|foo| 'foo' }
      }.to raise_error(ArgumentError)
    end

    it "errors when you don't pass a block" do
      expect {
        Bldr.handler(Object)
      }.to raise_error(ArgumentError, "You must pass a Proc")
    end

    it "errors when no args are passed to the block" do
      expect {
        Bldr.handler(Object) do
        end
      }.to raise_error(ArgumentError, "You must pass only one argument to the Proc")
    end

    it "errors when 2 args are passed to the block" do
      expect {
        Bldr.handler(Object) do |one,two|
        end
      }.to raise_error(ArgumentError, "You must pass only one argument to the Proc")
    end

  end

  describe "successfully" do

    it "adds the handler to the collection for the specific Class" do
      Bldr.handler(Object) {|o|}
      Bldr.handlers[Object].should respond_to(:call)
    end

    it "assigns the lambda passed in" do
      code = lambda {|foo| "foo" }
      Bldr.handler(Time,&code)
      Bldr.handlers[Time].should == code
    end

  end

end
