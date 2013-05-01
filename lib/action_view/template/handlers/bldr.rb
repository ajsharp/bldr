module ActionView::Template::Handlers
  class Bldr

    # @param [ActionView::Template] template the template instance
    # @return [String] the rendered ruby code string to render the template
    def self.call(template, opts = {})
      source = if template.source.empty?
        File.read(template.identifier)
      else
        template.source
      end

      %{
        node = ::Bldr::Node.new(nil, parent: self, root: true) {
          #{source}
        }
        MultiJson.encode node.result
      }
    end

  end
end

ActionView::Template.register_template_handler :bldr, ActionView::Template::Handlers::Bldr
