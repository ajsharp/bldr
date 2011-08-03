
module Bldr

  class Node

    attr_reader :value, :result, :parent

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
    # @param [Hash] value a key => value pair.
    def initialize(value = {}, opts = {}, &block)
      @value     = value.values.first
      @parent    = opts[:parent]

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
    # @param [Hash] hash a key/value pair indicating the output key name
    #   and the object to serialize.
    # @param [Proc] block the code block to evaluate
    #
    # @return [Nil]
    def object(hash, &block)
      key  = hash.keys.first
      node = Node.new(hash, :parent => self, &block)
      merge_result!(key, node.render!)
      node.parent.render!
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

        merge_result!(args.first, (block.arity == 1) ? block.call(value) : value.instance_eval(&block))
        return nil
      end

      args.each do |arg|
        if arg.is_a?(Hash)
          merge_result!(arg.keys.first, value.send(arg.values.first))
        else
          merge_result!(arg, value.send(arg))
        end
      end
      nil
    end
    alias :attribute :attributes

    private

    # Merges values into the "local" result hash.
    def merge_result!(key, val)
      result[key] = val
    end

  end
end
