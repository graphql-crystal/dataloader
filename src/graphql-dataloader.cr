module GraphQL
  # GraphQL::DataLoader is a batch loader to prevent N+1 queries
  module DataLoader
    VERSION = "0.1.0"
  end
end

require "./graphql-dataloader/cache"
require "./graphql-dataloader/memory_cache"
require "./graphql-dataloader/request"
require "./graphql-dataloader/loader"
