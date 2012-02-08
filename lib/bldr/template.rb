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
      # We get NotImplementedError by Tilt when we don't have this method
    end

    def precompiled_template(locals)
      data.to_s
    end
  end

  Tilt.register 'bldr', Bldr::Template
end
