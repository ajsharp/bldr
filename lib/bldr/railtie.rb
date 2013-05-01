module Bldr
  class Railtie < Rails::Railtie
    initializer 'bldr.initialize' do |app|
      ActiveSupport.on_load(:action_view) do
        require 'action_view/template/handlers/bldr'
      end
    end
  end
end