
class Comment
  attr_accessor :body, :name, :email

  def initialize(body = nil, name = nil, email = nil)
    @body, @name, @email = body, name, email
  end
end
