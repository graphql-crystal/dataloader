module GraphQL::DataLoader
  module Cache(K, V)
    def get(key : K, &block : -> V)
      synchronize do
        if has_key?(key)
          self[key]
        else
          yield.tap { |value| self[key] = value }
        end
      end
    end

    private abstract def has_key?(key : K) : Bool
    private abstract def [](key : K) : V
    private abstract def []=(key : K, value : V) : Nil

    private def synchronize(&block : -> V) : V
      yield
    end
  end
end
