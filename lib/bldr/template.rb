
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

    private
      def evaluate_source(scope, locals, &block)
        super(scope, locals, &block)#.render!
      end
  end

  Tilt.register 'bldr', Bldr::Template
end
