require 'spec_helper'

describe "Defining different types of handlers" do

  describe "Time" do
    it "uses the handler for Time when rendering" do
      Bldr.handler Time do |time|
        "bar"
      end

      output = "{\"foo\":\"bar\"}"
      node = Bldr::Node.new do
        object { attribute(:foo) { Time.now } }
      end

      node.to_json.should == output
    end
  end

end