require "../src/graphql-dataloader"

record User, id : Int32, name : String

USERS = [
  User.new(1, "John"),
  User.new(2, "Jane"),
  User.new(3, "Jack"),
]

class RecordLoader(I, M) < GraphQL::DataLoader::Loader(I, I, M?)
  private getter records

  def initialize(@records : Array(M))
    super()
  end

  def fetch(batch ids : Array(I)) : Array(M?)
    puts "SELECT * FROM #{M.name.underscore} WHERE id IN (#{ids.join(", ")})"
    ids.map { |id| records.find { |record| record.id == id } }
  end
end

USER_LOADER = RecordLoader(Int32, User).new(USERS)

def load_users(ids : Array(Int32)) : Array(User?)
  results = ids.map do |id|
    Channel(User?).new(1).tap do |channel|
      spawn { channel.send(USER_LOADER.load(id)) }
    end
  end

  results.map(&.receive)
end

load_users([1, 2, 1, 0]).each do |user|
  pp user
end

load_users([1, 2, 3]).each do |user|
  pp user
end
