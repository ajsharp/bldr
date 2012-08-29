class Author < Struct.new(:name)
end

class Post
  attr_accessor :title, :body, :comments, :author

  def initialize(title = nil, body = nil)
    @title, @body = title, body
    @comments = []
  end

end
