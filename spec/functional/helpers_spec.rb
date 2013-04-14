require 'spec_helper'

module Bldr
  describe Node, 'delegating helper methods' do
    before do
      # mock version of a module of methods that would be attached
      # to an ActionView::Base instance
      helpers = Module.new do
        def my_helper
          'my helper'
        end

        def helper_with_args_and_block(one, two)
          yield if block_given?
        end
      end

      # set up a mock ActionView::Base instance
      mock_action_view = Struct.new(:helpers)
      @view = mock_action_view.new(helpers)
      @view.extend(helpers)

      @node = Node.new(nil, root: true, parent: @view)
    end

    it 'delegates the methods to the parent object' do
      @view.should_receive(:my_helper)
      @node.my_helper
    end

    it 'gives access to helper methods to child nodes' do
      node = Node.new(nil, root: true, parent: @view) do
        object(:foo => Object.new) do
          attribute(:bar) { my_helper }
        end
      end
      node.result.should == {foo: {bar: 'my helper'}}
    end

    it 'assigns opts[:parent] as a @view instance variable' do
      @node.instance_variable_get(:@view).should == @view
    end

    it 'delegates arguments and blocks to the parent' do
      lam = lambda { }
      @view.should_receive(:helper_with_args_and_block).with(1, 2, lam)
      @node.helper_with_args_and_block(1, 2, lam)
    end

    it 'defines helper methods on a per-instance basis' do
      @node.methods.should include :my_helper

      new_parent = Struct.new(nil).new
      Node.new(nil, root: true, parent: new_parent).methods.should_not include :my_helper
    end
  end
end
