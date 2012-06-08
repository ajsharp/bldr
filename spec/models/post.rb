class PostMetadata
  attr_accessor :posted_at

  def initialize(posted_at=Time.new(0))
    @posted_at = posted_at
  end
end


class Post
  attr_accessor :title, :body, :comments, :meta

  def initialize(title = nil, body = nil)
    @title, @body = title, body
    @comments = []
    @meta = PostMetadata.new
  end

end
