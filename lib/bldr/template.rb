require 'tilt'

module Bldr

  class Template < Tilt::Template

    self.default_mime_type = 'application/json'

    def initialize_engine
      require_template_library 'bldr'
    end

    def self.engine_initialized?
      defined? ::Bldr
    end

    def prepare
      # @engine = Bldr::Engine.new(data, options)
    end

    def precompiled_template(locals)
      data.to_s
    end
    
    def render(scope=Bldr::Node.new, locals={}, &block)
      # super.send("to#{format}".to_sym)
      # super.to_json
      super
    end

  end

  Tilt.register 'bldr', Bldr::Template
end
