module GraphQL::DataLoader
  module Cache(K, V)
    # Try to get a value from the cache and call the block if it's not there
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

    # Override this method for caches where values expire for thread safety
    private def synchronize(&block : -> V) : V
      yield
    end
  end
end
