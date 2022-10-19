# GraphQL::DataLoader

A batch loading library to help prevent N+1 queries

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     graphql-dataloader:
       github: graphql-crystal/dataloader
   ```

2. Run `shards install`

## Usage

See [examples](examples) for working examples. It's possible to use
GraphQL::Dataloader outside of a GraphQL application. It can be a nice
abstraction for any type data fetching benefitting from batching (i.e. fetching
data from a REST API). In GraphQL however it quickly becomes almost a
necessity, as you have little control over the queries your api will receive.
Here's an example:

``` gql
query GetUsersWithBlogPosts {
  users {
    id
    name
    blogPosts {
      id
      title
    }
  }
}
```

``` crystal
@[GraphQL::Object]
class User < GraphQL::BaseObject
  @[GraphQL::Field]
  def id : GraphQL::Scalars::ID
    GraphQL::Scalars::ID.new(@id.to_s)
  end

  @[GraphQL::Field]
  getter name : String

  @[GraphQL::Field]
  def blog_posts : Array(BlogPost)
    BlogPostQuery.new.author_id(@id).to_a
  end
end

@[GraphQL::Object]
class BlogPost < GraphQL::BaseObject
  @[GraphQL::Field]
  def id : GraphQL::Scalars::ID
    GraphQL::Scalars::ID.new(@id.to_s)
  end

  @[GraphQL::Field]
  getter title : String

  @[GraphQL::Field]
  def author : User
    UserQuery.new.find(@id)
  end
end
```

This will result in an N+1 query for blog posts as for each user a query like the following is run.

``` sql
SELECT * FROM blog_posts WHERE author_id = $1
```

Things get even worse when has many relations are nested (maybe blog posts have
tags?). Again: you have little control over what users of your API will do.

Here's where DataLoaders come in. Not only can they batch requests to the same
resource, but they also cache already fetched resources. So even if you can't
query all records for a type at once because of some dependencies in the graph,
you will never fetch the same record twice. Because of this, DataLoaders should
be short-lived objects best located in your GraphQL request context.

Here's how we can improve the situation above:

``` crystal
class UserLoader < GraphQL::DataLoader::Loader(Int32, Int32, User?)
  def fetch(batch ids : Array(Int32)) : Array(User?)
    users = UserQuery.new.id.in(ids).to_a
    # Make sure to return results having the same size and order as the batch
    ids.map { |id| users.find { |user| user.id == id } }
  end
end

class UserBlogPostsLoader < GraphQL::DataLoader::Loader(User, Int32, Array(BlogPost))
  def key_for(user : User) : Int32
    user.id
  end

  def fetch(batch users : Array(User)) : Array(Array(BlogPost))
    blog_posts = BlogPostQuery.new.author_id.in(users.map(&.id))
    users.map do |user|
      blog_posts.select { |blog_post| blog_post.author_id == user.id } }
    end
  end
end

class Context < GraphQL::Context
  getter user_loader = UserLoader.new
  getter user_blog_posts_loader = UserBlogPostsLoader.new
end

@[GraphQL::Object]
class User < GraphQL::BaseObject
  # ...

  @[GraphQL::Field]
  def blog_posts(context : Context) : Array(BlogPost)
    context.user_blog_posts_loader.load(self)
  end
end

@[GraphQL::Object]
class BlogPost < GraphQL::BaseObject
  # ...

  @[GraphQL::Field]
  def author(context : Context) : User
    context.user_loader(author_id)
  end
end
```

When you execute the query now, you will see something like

``` sql
SELECT * FROM blog_posts WHERE author_id IN ($1, $2, $3, ...)
```

in your database logs. :tada:

## Advanced topics

### Custom Cache

You can provide a custom cache for a loader like so:
`MyLoader.new(my_custom_cache)`. It will have to implement
[`Cache(K, V)`](src/graphql-dataloader/cache.cr). Reasons for doing this
include synchronized caches among server instances or longer lived caches if
stale data isn't an issue.

## Development

Run specs with `crystal spec`

## Contributing

1. Fork it (<https://github.com/graphql-crystal/dataloader/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Joakim Repomaa](https://github.com/repomaa) - creator and maintainer
