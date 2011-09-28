module Bldr
  class Railtie < Rails::Railtie

    initializer "bldr.initialize" do |app|
      ActiveSupport.on_load(:action_view) do
        require 'bldr/rails/rails3'
      end
    end
  end
end
