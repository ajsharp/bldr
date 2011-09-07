
class Person

  attr_accessor :name, :age, :friends

  def initialize(name = nil, age = nil, friends = nil)
    @name, @age, @friends = name, age, friends
  end
end
