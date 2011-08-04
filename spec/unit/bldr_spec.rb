require 'spec_helper'

describe "the json encoding library" do
  it "uses yajl by default" do
    MultiJson.engine.should == MultiJson::Engines::Yajl
  end

  it "allows changing the json encoder to json pure" do
    Bldr.json_encoder = :json_pure
    MultiJson.engine.should == MultiJson::Engines::JsonPure
  end

  it "allows changing the json encoder to the json gem" do
    Bldr.json_encoder = :json_gem
    MultiJson.engine.should == MultiJson::Engines::JsonGem
  end
end
