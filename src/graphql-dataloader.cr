# TODO: Write documentation for `Graphql::Dataloader`
module GraphQL
  module DataLoader
    VERSION = "0.1.0"
  end
end

require "./graphql-dataloader/cache"
require "./graphql-dataloader/memory_cache"
require "./graphql-dataloader/request"
require "./graphql-dataloader/loader"
