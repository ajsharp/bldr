
module Bldr

  class Node

    attr_reader :current_object, :result, :parent

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
      @parent         = opts[:parent]

      # Storage hash for all descendant nodes
      @result  = {}

      instance_eval(&block) if block_given?
    end

    # Merge the local results into the ancestor result hash.
    #
    # @return [Hash]
    def render!
      result
    end

    # Return the json-encoded result hash.
    #
    # @return [String] the json-encoded result hash
    def to_json
      MultiJson.encode(result)
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
    def object(hash = nil, &block)
      if hash
        key   = hash.keys.first
        value = hash.values.first
      end

      node  = Node.new(value, :parent => self, &block)
      merge_result!(key, node.render!)
      node.parent.to_json
    end

    def collection(items, &block)
      key   = items.keys.first
      items = items.values.first

      merge_result!(key, [])
      items.each do |item|
        node = Node.new(item, :parent => self, &block)
        append_result!(key, node.render!)
      end
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
      if block_given?
        if args.size > 1
          raise(ArgumentError, "You may only pass one argument to #attribute when using the block syntax.")
        end

        merge_result!(args.first, (block.arity == 1) ? block.call(current_object) : current_object.instance_eval(&block))
        return nil
      end

      args.each do |arg|
        if arg.is_a?(Hash)
          merge_result!(arg.keys.first, current_object.send(arg.values.first))
        else
          merge_result!(arg, current_object.send(arg))
        end
      end
      nil
    end
    alias :attribute :attributes

    private

    # Merges values into the "local" result hash.
    def merge_result!(key = nil, val)
      if key
        result[key] = val
      else
        result.merge!(val)
      end
    end

    def append_result!(key, val)
      result[key] << val
    end

  end
end
