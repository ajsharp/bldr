require 'spec_helper'

module Bldr
  describe Node, 'access to the params hash' do
    let(:params) { {foo: 'bar'} }
    let(:parent) { Struct.new(:params).new(params) }

    it 'has access in the root node' do
      Node.new(nil, parent: parent) do
        attribute(:foo) { params[:foo] }
      end.result.should == {
        foo: 'bar'
      }
    end

    it 'has access in child nodes' do
      Node.new(nil, parent: parent) do
        object(:foo) do
          attribute(:baz) { params[:foo] }
        end
      end.result.should == {
        foo: {baz: 'bar'}
      }
    end
  end
end
