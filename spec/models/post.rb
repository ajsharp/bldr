
class Post
  attr_accessor :title, :body, :comments

  def initialize(title = nil, body = nil)
    @title, @body = title, body
    @comments = []
  end

end
