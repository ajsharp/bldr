
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
