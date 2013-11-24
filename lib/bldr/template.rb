require 'tilt'

module Bldr

  # This class is required for Tilt compatibility
  class Template < Tilt::Template

    self.default_mime_type = 'application/json'

    def initialize_engine
      require_template_library 'bldr'
    end

    def self.engine_initialized?
      defined? ::Bldr
    end

    # Called at the end of Tilt::Template#initialize.
    # Use this method to access or mutate any state available to Tilt::Template
    def prepare
      # We get NotImplementedError by Tilt when we don't have this method
    end

    def precompiled_template(locals)
      data.to_s
    end

    # Helper to render templates outside the context of a rails/sinatra view.
    #
    # @param [String] template path to a file name
    # @param [Hash] opts
    #
    # @return [String]
    def self.render(template, opts = {})
      scope  = ::Bldr::Node.new
      locals = opts.delete(:locals) || {}
      node   = new(template, 1, opts).render(scope, locals)
      MultiJson.encode(node.result)
    end
  end

  Tilt.register 'bldr', Bldr::Template
end
