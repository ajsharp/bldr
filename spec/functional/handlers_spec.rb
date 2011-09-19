require 'spec_helper'

describe "Defining different types of handlers" do

  describe "Time" do
    context do
      Bldr.handler Time do |time|
        "bar"
      end
    end

    it "uses the handler for Time when rendering" do
      output = "{\"foo\":\"bar\"}"
      node = Bldr::Node.new do
        object { attribute(:foo) { Time.now } }
      end

      node.to_json.should == output
    end
  end

end