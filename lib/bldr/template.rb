require 'tilt'

module Bldr

  class Template < Tilt::Template
    # attr_reader :engine
    # self.default_mime_type = 'application/json'

    def initialize_engine
      require_template_library 'bldr'
    end

    def self.engine_initialized?
      defined? ::Bldr
    end

    def prepare
      @engine = Bldr::Engine.new(data, options)
    end

    def precompiled_template(locals)
      data.to_s
    end
    
    def render(*args,&block)
      super.to_json
    end

  end

  Tilt.register 'bldr', Bldr::Template
end
