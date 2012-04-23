
module Bldr

  class Node

    attr_reader :current_object, :result, :parent, :opts, :views

    # Initialize a new Node instance.
    #
    # @example Building a simple node
    #   node = Node.new do
    #     Node.new(:person => Person.new("alex")) do
    #       attributes(:name)
    #     end
    #   end
    #   node.to_json # => {"person": {"name": "alex"}}
    #
    #
    # @param [Object] value an object to serialize.
    def initialize(value = nil, opts = {}, &block)
      @current_object = value
      @opts           = opts
      @parent         = opts[:parent]
      @views          = opts[:views]
      # Storage hash for all descendant nodes
      @result  = {}

      instance_eval(&block) if block_given?
    end
    
    # Create and render a node.
    #
    # @example A keyed object
    #   get '/users/:id' do
    #     user = User.find(params['id'])
    #
    #     bldr :'users/show.json', :locals => {:user => user}
    #   end
    #
    #   # views/users/show.json.bldr
    #   object :user => user do
    #     attributes :name, :email
    #
    #     attribute(:id) { |person| person.id.to_s }
    #   end
    #
    # @example Root-level object with no key
    #   get '/' do
    #     url = "http://google.com"
    #
    #     bldr :'template.json', :locals => {:url => url}
    #   end
    #
    #   # views/template.json.bldr
    #   object do
    #     attributes(:url) { url }
    #   end
    #
    # @param [Hash, Nil] hash a key/value pair indicating the output key name
    #   and the object to serialize.
    # @param [Proc] block the code block to evaluate
    #
    # @return [String] returns a json-encoded string of itself and all
    #   descendant nodes.
    def object(base = nil, &block)
      if base.kind_of? Hash
        key   = base.keys.first
        value = base.values.first
      else
        key = base
        value = nil
      end

      return nil if value.nil? and base.kind_of? Hash
      node  = Node.new(value, opts.merge(:parent => self), &block)
      merge_result!(key, node.result)
      
      self
    end

    def collection(items, &block)

      if items.respond_to?('keys')
        key = items.keys.first
        values = items.values.to_a.first
      else
        key = nil
        values = items
      end
      
      vals = if values
               values.map{|item| Node.new(item, opts.merge(:parent => self), &block).result}
             else
               []
             end

      if items.respond_to?('keys')
        merge_result! key, vals
      else
        @result = massage_value(vals)
      end
        
      self
    end

    # Add attributes to the result hash in a variety of ways
    #
    # @example Simple list of attributes
    #   object :person => dude do
    #     attributes :name, :age
    #   end
    #
    # @example Attribute aliasing
    #   object :person => dude do
    #     attributes :surname => :last_name
    #   end
    #
    # @example Dynamic attributes (explicit object context)
    #   object :person => employee do
    #     collection :colleagues => employee.colleagues do |colleague|
    #       attribute :isBoss do |colleague|
    #         employee.works_with?(colleague) && colleague.admin?
    #       end
    #     end
    #   end
    #
    # @example Dynamic attributes (implicit object context)
    #   object :person => dude do
    #     collection :colleagues => employee.colleagues do |colleague|
    #       attribute :rank do
    #         # method called on colleague
    #         if admin? && superior_to?(employee)
    #           "High Up"
    #         end
    #       end
    #     end
    #   end
    #
    # @return [Nil]
    def attributes(*args, &block)
      if current_object.nil?
        raise(ArgumentError, "No current_object to apply #attributes to.")
      end

      args.each do |arg|
        if arg.is_a?(Hash)
          merge_result!(arg.keys.first, current_object.send(arg.values.first))
        else
          merge_result!(arg, current_object.send(arg))
        end
      end
    end

    def attribute(*args,&block)
      if block_given?
        raise(ArgumentError, "You may only pass one argument to #attribute when using the block syntax.") if args.size > 1
        raise(ArgumentError, "You cannot use a block of arity > 0 if current_object is not present.") if block.arity > 0 and current_object.nil?
        merge_result!(args.first, (block.arity == 1) ? block.call(current_object) : current_object.instance_eval(&block))
        self
      else
        case args.size
        when 1 # inferred object
          raise(ArgumentError, "#attribute can't be used when there is no current_object.") if current_object.nil?
          if args[0].is_a?(Hash)
            merge_result!(args[0].keys.first, current_object.send(args[0].values.first))
          else
            merge_result!(args[0], current_object.send(args[0]))
          end
        when 2 # static property
          merge_result!(args[0], args[1])
        else
          raise(ArgumentError, "You cannot pass more than two arguments to #attribute.")
        end
      end
    end

    # Render a template inline within a view
    #
    # @example Simple render
    #   object :person => dude do
    #     template "path/to/template"
    #   end
    # 
    # @example Using locals
    #   object :person => dude do
    #     template "path/to/template", :locals => {:foo => 'bar'}
    #   end
    #
    # @return [Bldr::Node] returns self
    def template(template, options={})
      locals = options[:locals] || options['locals']

      if tpl = Bldr::Template.new(find_template(template)).render(self, locals)
        merge_result! nil, tpl.result
      end

      self
    end

    private
    
    def find_template(template)
      path = []
      path << views if views
      template += ".json.bldr" unless template =~ /\.json\.bldr$/
      path << template
      File.join(*path)
    end

    # Merges values into the "local" result hash.
    def merge_result!(key, val)
      if key
        result[key] = massage_value(val)
      else
        result.merge!(massage_value(val))
      end
    end

    # put any specializations in here
    # @todo: add config handlers to specify your own overridable Class->lambda methods of serialization
    def massage_value(val)
      if block = Bldr.handlers[val.class]
        return block.call(val)
      else
        val
      end
    end
    
  end
end
