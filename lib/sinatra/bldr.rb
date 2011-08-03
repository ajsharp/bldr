require 'sinatra/base'

module Sinatra

  module Bldr
    module Helpers
      def bldr(template, opts = {}, locals = {}, &block)
        opts[:scope] = ::Bldr::Node.new
        render(:bldr, template, opts, locals, &block)
      end
    end

    def self.registered(app)
      app.helpers Helpers
    end
  end

  register Bldr
end
