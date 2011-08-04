
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
  end
end
