require 'spec_helper'
require 'action_view'
require 'bldr/rails/rails3'

describe ActionView::Template::Handlers::Bldr do
  it "sets the default format to json" do
    subject.default_format.should == Mime::JSON
  end
end

describe ActionView::Template::Handlers::Bldr, '#compile' do
  let(:source) { "object { attribute(:foo) { 'bar' } }" }
  let(:template) do
    identifier = 'template identifier'
    handler = ActionView::Template::Handlers::Bldr
    ActionView::Template.new(source, identifier, handler, :format => Mime::JSON)
  end

  it "returns the string that will get eval-ed by ActionView" do
    ActionView::Template::Handlers::Bldr.new.compile(template).should == "Bldr::Engine.new(\"#{source}\").render"
  end
end