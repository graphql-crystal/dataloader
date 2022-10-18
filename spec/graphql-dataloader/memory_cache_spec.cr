require "../spec_helper"

describe GraphQL::DataLoader::MemoryCache do
  it "caches values" do
    cache = GraphQL::DataLoader::MemoryCache(String, String).new
    cache.get("key") { "value" }.should eq("value")
    cache.get("key") { raise "should not be called" }.should eq("value")
  end
end
