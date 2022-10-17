require "./record_loader"

record BlogPost, id : Int32, title : String, author_id : Int32

BLOG_POSTS = [
  BlogPost.new(1, "Hello world", 1),
  BlogPost.new(2, "GraphQL is awesome", 2),
  BlogPost.new(3, "GraphQL is cool", 2),
  BlogPost.new(4, "GraphQL is fun", 3),
]

class UserBlogPostsLoader < GraphQL::DataLoader::Loader(User, Int32, Array(BlogPost))
  private getter blog_posts

  def initialize(@blog_posts : Array(BlogPost))
    super()
  end

  def key_for(user : User) : Int32
    user.id
  end

  def fetch(batch users : Array(User)) : Array(Array(BlogPost))
    puts "SELECT * FROM blogposts WHERE author_id IN (#{users.map(&.id).join(", ")})"
    users.map do |user|
      blog_posts.select { |blog_post| blog_post.author_id == user.id }
    end
  end
end

USER_BLOG_POSTS_LOADER = UserBlogPostsLoader.new(BLOG_POSTS)

def load_blog_posts_for_users(user_ids : Array(Int32)) : Array({User, Array(BlogPost)}?)
  results = user_ids.map do |user_id|
    Channel({User, Array(BlogPost)}).new.tap do |channel|
      spawn do
        user = USER_LOADER.load(user_id)
        next channel.close if user.nil?

        blog_posts = USER_BLOG_POSTS_LOADER.load(user)
        channel.send({user, blog_posts})
      end
    end
  end

  results.map(&.receive?)
end

def print_result(result : {User, Array(BlogPost)}?)
  if result
    user, blog_posts = result
    puts "#{user.inspect} has written #{blog_posts.inspect}"
  else
    puts "User not found"
  end
end

load_blog_posts_for_users([1, 2, 1, 0]).each do |result|
  print_result(result)
end

load_blog_posts_for_users([1, 2, 3, 1]).each do |result|
  print_result(result)
end
