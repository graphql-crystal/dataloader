require "../spec_helper"

describe GraphQL::DataLoader::Request do
  it "allows setting and getting a result" do
    request = GraphQL::DataLoader::Request(String, String, String).new("foo", "bar")
    request.result = "baz"
    request.result.should eq("baz")
  end

  it "allows raising an exception" do
    request = GraphQL::DataLoader::Request(String, String, String).new("foo", "bar")
    exception = Exception.new("boom")
    request.raise(exception)
    expect_raises(Exception, "boom") { request.result }
  end

  it "allows setting a result only once" do
    request = GraphQL::DataLoader::Request(String, String, String).new("foo", "bar")
    request.result = "baz"
    expect_raises(Channel::ClosedError) { request.result = "qux" }
  end

  it "allows raising only once" do
    request = GraphQL::DataLoader::Request(String, String, String).new("foo", "bar")
    exception = Exception.new("boom")
    request.raise(exception)
    expect_raises(Channel::ClosedError) { request.raise(exception) }
  end

  it "caches the result" do
    request = GraphQL::DataLoader::Request(String, String, String).new("foo", "bar")
    request.result = "baz"
    request.result.should eq("baz")
    request.result.should eq("baz")

    request = GraphQL::DataLoader::Request(String, String, String?).new("foo", "bar")
    request.result = nil
    request.result.should eq(nil)
    request.result.should eq(nil)
  end

  it "caches the exception" do
    request = GraphQL::DataLoader::Request(String, String, String).new("foo", "bar")
    exception = Exception.new("boom")
    request.raise(exception)
    expect_raises(Exception, "boom") { request.result }
    expect_raises(Exception, "boom") { request.result }
  end
end
