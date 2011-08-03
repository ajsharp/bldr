require 'rubygems'
require 'rspec'

require 'yajl'
require 'tilt'
require 'ruby-debug'

$:.unshift(File.dirname(File.expand_path(__FILE__)))

require File.join(File.dirname(File.expand_path(__FILE__)), "..", "lib", "bldr")

Dir['spec/models/*'].each { |f| require File.expand_path(f) }

RSpec.configure do |c|
  c.include Bldr

  def jsonify(hash)
    Yajl::Encoder.encode(hash)
  end
end
