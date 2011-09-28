module ActionView
  module Template::Handlers

    class Bldr < Template::Handler
      include Compilable

      self.default_format = Mime::JSON

      # Compile the template
      #
      # @note This method is called by ActionView::Handler#call, which is called upon rendering
      #
      # @param [ActionView::Template] the actionview template
      # @return [String] the template string
      def compile(template)
        source = template.source.inspect
        "Bldr::Engine.new(#{source}).render"
      end
    end

  end
end

ActionView::Template.register_template_handler :bldr, ActionView::Template::Handlers::Bldr
