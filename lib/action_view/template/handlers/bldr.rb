module ActionView::Template::Handlers
  class Bldr
    # @return [String] the rendered template string
    def self.call(template, opts = {})
      source = if template.source.empty?
        File.read(template.identifier)
      else
        template.source
      end

      %{
        node = ::Bldr::Node.new(nil, parent: self) {
          #{source}
        }
        MultiJson.encode node.result
      }
    end
  end
end

ActionView::Template.register_template_handler :bldr, ActionView::Template::Handlers::Bldr