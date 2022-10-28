module GraphQL::DataLoader
  struct MemoryCache(K, V)
    include Cache(K, V)

    private getter cache = Hash(K, V).new

    def has_key?(key : K) : Bool
      cache.has_key?(key)
    end

    def [](key : K) : V
      cache[key]
    end

    def []?(key : K) : V?
      cache[key]?
    end

    def []=(key : K, value : V) : Nil
      cache[key] = value
    end

    def clear : Nil
      cache.clear
    end

    def delete(key : K) : Nil
      cache.delete(key)
    end
  end
end
