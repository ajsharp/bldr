
module Bldr

  class Engine
    attr_reader :template, :options, :result

    def initialize(template, options = {})
      @template, @options = template, options
      @result   = {}
      @handlers = {}
    end

    # Render the template
    # We render the template by instance_eval-ing it in the context of a `Bldr::Node` object.
    #
    # @return [String] the json-encoded string of the template
    def render
      Node.new.instance_eval(template)
    end

  end

end
