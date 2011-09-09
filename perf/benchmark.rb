require 'benchmark'
require File.expand_path(File.dirname(__FILE__) + '/../lib/bldr')

class Person
  attr_reader :name
  def initialize(name)
    @name = name
  end
end

Benchmark.bm(20) do |bm|
  i = 1000
  $guy = Person.new "john"
  $friends = [Person.new("jim"), Person.new("bob")]
  puts "i = #{i}"

  bm.report "node with collection" do
    i.times do
      Bldr::Node.new do
        object :dude => $guy do
          attributes :name

          collection :friends => $friends do
            attributes :name
          end
        end
      end
    end
  end
end