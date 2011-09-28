require 'spec_helper'

describe Bldr::Engine, '#render' do
  it "instance_evals the template in a Bldr::Node object" do
    node     = mock("Node")
    template = "object { attribute(:foo) { 'bar' }}"
    
    Bldr::Node.stub!(:new => node)
    node.should_receive(:instance_eval).with(template)
    
    Bldr::Engine.new(template).render
  end
end