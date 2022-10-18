require "../spec_helper"

record User, id : Int32, name : String
record BlogPost, id : Int32, title : String, author_id : Int32

class UserLoader < GraphQL::DataLoader::Loader(Int32, Int32, User?)
  private getter users : Array(User)
  private getter batch_log = Array(Array(Int32)).new
  getter batch_log

  def initialize(@users)
    super()
  end

  def fetch(batch ids : Array(Int32)) : Array(User?)
    batch_log << ids
    ids.map do |id|
      users.find { |user| user.id == id }
    end
  end
end

class UserBlogPostsLoader < GraphQL::DataLoader::Loader(User, Int32, Array(BlogPost))
  private getter users : Array(User)
  private getter blog_posts : Array(BlogPost)
  private getter batch_log = Array(Array(Int32)).new
  getter batch_log

  def initialize(@users, @blog_posts)
    super()
  end

  def key_for(user : User) : Int32
    user.id
  end

  def fetch(batch users : Array(User)) : Array(Array(BlogPost))
    user_ids = users.map(&.id)
    batch_log << user_ids

    user_ids.map do |id|
      blog_posts.select { |blog_post| blog_post.author_id == id }
    end
  end
end

describe GraphQL::DataLoader::Loader do
  it "loads objects using the defined fetch method" do
    users = [
      User.new(1, "Ada"),
      User.new(2, "Grace"),
    ]
    loader = UserLoader.new(users)
    loader.load(1).should eq(users[0])
    loader.load(2).should eq(users[1])
  end

  it "caches results" do
    users = [
      User.new(1, "Ada"),
      User.new(2, "Grace"),
    ]
    loader = UserLoader.new(users)
    loader.load(1).should eq(users[0])
    loader.load(1).should eq(users[0])
    loader.batch_log.size.should eq(1)
  end

  it "batches loads" do
    users = [
      User.new(1, "Ada"),
      User.new(2, "Grace"),
    ]
    loader = UserLoader.new(users)
    spawn { loader.load(1) }
    spawn { loader.load(2) }
    sleep 1.millisecond

    loader.batch_log.size.should eq(1)
    loader.batch_log.first.should eq([1, 2])
  end

  it "allows using any object as load argument" do
    users = [
      User.new(1, "Ada"),
      User.new(2, "Grace"),
    ]

    blog_posts = [
      BlogPost.new(1, "GraphQL", 1),
      BlogPost.new(2, "GraphQL", 2),
      BlogPost.new(3, "GraphQL", 1),
    ]

    loader = UserBlogPostsLoader.new(users, blog_posts)
    spawn { loader.load(users[0]).should eq([blog_posts[0], blog_posts[2]]) }
    spawn { loader.load(users[1]).should eq([blog_posts[1]]) }
    sleep 1.millisecond

    loader.batch_log.size.should eq(1)
    loader.batch_log.first.should eq([1, 2])
  end
end
