
module Bldr

  class Node

    PROTECTED_IVARS = [:@parent, :@opts, :@current_object, :@views, :@locals, :@result]

    attr_reader :current_object, :result, :parent, :opts, :views, :locals

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
      @locals         = opts[:locals]
      # Storage hash for all descendant nodes
      @result         = {}

      copy_instance_variables_from(opts[:parent]) if opts[:parent]

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
    # @example "Pass-through" objects
    #   object :person => person do
    #     object :hobbies => hobbies
    #   end
    #
    # @param [Hash, Nil] hash a key/value pair indicating the output key name
    #   and the object to serialize.
    # @param [Proc] block the code block to evaluate
    #
    # @return [Bldr::Node] returns self
    def object(base = nil, &block)
      if block_given?
        if keyed_object?(base)
          key   = base.keys.first
          value = base.values.first
        else
          key = base
          value = nil
        end

        # Short circuit here if the object passed in pointed
        # at a nil value. There's some debate about how this
        # should behave by default -- should it build the keyspace,
        # pointing a null value, or should it leave the key out.
        # With this implementation, it leaves the keyspace out.
        return nil if value.nil? and keyed_object?(base)

        node  = Node.new(value, opts.merge(:parent => self), &block)
        merge_result!(key, node.result)
      else
        merge_result!(nil, base)
      end

      self
    end

    # Build a collection of objects, either passing each object
    # into the block provided, or rendering the collection
    # "pass-through", i.e. exactly as it appears.
    #
    # @example
    #   object :person => person do
    #     attributes :id, :name, :age
    #
    #     collection :friends => person.friends do
    #       attributes :name, :age, :friend_count
    #     end
    #   end
    #
    # @example "Pass-through" collections
    #   object :person => person do
    #     collection :hobbies => hobbies
    #   end
    #
    # @param [Array, Hash] items Either an array of items, or a hash.
    #   If an array is passed in, the objects will be rendered at the
    #   "top level", i.e. without a key pointing to them.
    # @return [Bldr::Node] returns self
    def collection(items, &block)

      # Does this collection live in a key, or is it top-level?
      if keyed_object?(items)
        key = items.keys.first
        values = items.values.to_a.first
      else
        key = nil
        values = items
      end

      vals = if values
        if block_given?
          values.map do |item|
            Node.new(item, opts.merge(:parent => self), &block).result
          end
        else
          values
        end
      else
        []
      end

      if keyed_object?(items)
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
      self
    end

    def attribute(*args,&block)
      if block_given?
        raise(ArgumentError, "You may only pass one argument to #attribute when using the block syntax.") if args.size > 1
        raise(ArgumentError, "You cannot use a block of arity > 0 if current_object is not present.") if block.arity > 0 and current_object.nil?
        merge_result!(args.first, (block.arity == 1) ? block.call(current_object) : current_object.instance_eval(&block))
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
      self
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

    # Retrieves all instance variables from an object and sets them in the
    #   current scope.
    #
    # @param [Object] object The object to copy instance variables from.
    def copy_instance_variables_from(object)
      ivar_names = (object.instance_variables - PROTECTED_IVARS).map(&:to_s)
      ivar_names.map do |name|
        instance_variable_set(name, object.instance_variable_get(name))
      end
    end

    # Determines if an object was passed in with a key pointing to it, or if
    # it was passed in as the "root" of the current object. Essentially, this
    # checks if `obj` quacks like a hash.
    #
    # @param [Object] obj
    # @return [Boolean]
    def keyed_object?(obj)
      obj.respond_to?(:keys)
    end
    
    def find_template(template)
      path = []
      path << views if views
      template += ".json.bldr" unless template =~ /\.bldr$/
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
