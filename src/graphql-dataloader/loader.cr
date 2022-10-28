module GraphQL::DataLoader
  # Abstract base class for all loaders
  #
  # The first type parameter `O` is the type of the objects passed to `#load`.
  # The second type parameter `K` is the type of keys for caching and determining uniqueness.
  # The third type parameter `V` is the type of values returned by the loader.
  #
  # You will need to override `fetch` to provide the actual batch loading behavior.
  # If `O` differs from `K` you will also need to override `#key_for`.
  abstract class Loader(O, K, V)
    VERSION = "0.1.0"

    private getter current_batch = Array(Request(O, K, V)).new
    private getter batch_mutex = Mutex.new
    private property? batch_running = false
    private getter cache : Cache(K, V)

    # You can use a custom *cache* by implementing `Cache(K, V)` and passing it here.
    def initialize(@cache = MemoryCache(K, V).new)
    end

    # Get the key for an object passed to `#load`.
    # Override this if `O` differs from `K`
    def key_for(object : O) : K
      object
    end

    # Load a value for an object.
    def load(object : O) : V
      key = key_for(object)

      cache.get(key) do
        enqueue_and_wait(key, object)
      end
    end

    # Load multiple values at once.
    def load(objects : Array(O)) : Array(V)
      objects.map { |object| load(object) }
    end

    def prime(object : O, value : V) : self
      cache[key_for(object)] ||= value
      self
    end

    def clear(object : O) : self
      cache.delete(key_for(object))
      self
    end

    def clear : self
      cache.clear
      self
    end

    # The batch loading method.
    # Gets called with all objects that have been passed to `#load` in the current batch.
    # A batch is fetched after 1 microsecond since the first call to `#load`.
    protected abstract def fetch(batch : Array(O)) : Array(V)

    private def enqueue_and_wait(key : K, object : O) : V
      request = Request(O, K, V).new(key, object)

      batch_mutex.synchronize do
        current_batch << request
        start_batch
      end

      request.result
    end

    private def start_batch
      return if batch_running?
      self.batch_running = true

      spawn do
        sleep 1.microsecond
        fetch
      end
    end

    private def fetch
      batch_mutex.synchronize do
        requests = current_batch.group_by(&.key)
        unique_requests = current_batch.uniq { |request| request.key }
        results = fetch(unique_requests.map(&.object))

        unique_requests.zip(results).each do |request, result|
          requests[request.key].each { |r| r.result = result }
        end
      rescue ex
        current_batch.each { |request| request.raise(ex) }
      ensure
        current_batch.clear
        self.batch_running = false
      end
    end
  end
end
