
$:.unshift(File.dirname(File.expand_path(__FILE__)))

require 'multi_json'
require 'bldr/engine'
require 'bldr/template'
require 'bldr/node'

module Bldr
  class << self

    def json_encoder=(encoder)
      MultiJson.engine = encoder
    end

    # Define a custom handler.
    #
    # @example Over-riding BSON::ObjectId
    #   Bldr.handler BSON::ObjectId do |value|
    #     val.to_s # => "4e77a682364141ecf5000002"
    #   end
    #
    # @param [Class] klass The klass name of the class to match
    # @param [Proc] block The code to execute to properly format the data
    def handler(klass,&block)
      raise(ArgumentError, "You must pass a Proc") if block.nil?
      raise(ArgumentError, "You must pass only one argument to the Proc") unless block.arity == 1

      handlers[klass] = block
    end

    def handlers
      @handlers ||= {}
    end
  end
end
