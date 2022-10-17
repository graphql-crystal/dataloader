module GraphQL::DataLoader
  struct MemoryCache(K, V)
    include Cache(K, V)

    private getter cache = Hash(K, V).new

    private def has_key?(key : K) : Bool
      cache.has_key?(key)
    end

    private def [](key : K) : V
      cache[key]
    end

    private def []=(key : K, value : V) : Nil
      cache[key] = value
    end
  end
end
