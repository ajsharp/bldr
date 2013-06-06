require 'spec_helper'

describe 'setting the current object in an object block' do
  it 'sets the object' do
    klass = Struct.new(:name)
    person = klass.new('alex')
    Bldr::Node.new(nil, locals: {person: person}) do
      object person do
        attributes(:name)
      end
    end.result.should == {name: 'alex'}
  end
end