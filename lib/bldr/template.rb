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

    protected
    def compiled_method(locals_keys)
      compile_template_method(locals_keys)
    end
  end

  Tilt.register 'bldr', Bldr::Template
end
