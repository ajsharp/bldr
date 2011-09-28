require 'sinatra/base'

module Sinatra

  module Bldr
    module Helpers

      # Wrapper for Tilt's `render` method
      #
      # We use this to properly set the scope the template gets rendered
      # within to a `Bldr::Node` object and pass in local variables.
      #
      # @param [String, Symbol] template the template to render
      #   Can be a relative file location or a string template.
      #   The template may also be passed in as the block argument
      #   to this method, in which case, template argument is nil.
      #
      # @example Render a template in a file
      #   get '/users/:id' do
      #     user = User.find(params['id'])
      #     bldr :'users/public.bldr', :locals => {:user => user}
      #   end
      #
      # @param [Hash] opts a hash of options
      # @option opts [Hash] :locals a hash of local variables to be used in the template
      # @option
      def bldr(template, opts = {}, &block)
        opts[:scope] = ::Bldr::Node.new
        locals = opts.delete(:locals)
        render(:bldr, template, opts, locals, &block)
      end
    end

    def self.registered(app)
      app.helpers Helpers
    end
  end

  register Bldr
end
