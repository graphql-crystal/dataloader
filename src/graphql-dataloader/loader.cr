module GraphQL::DataLoader
  abstract class Loader(O, K, V)
    VERSION = "0.1.0"

    private getter current_batch = Array(Request(O, K, V)).new
    private getter batch_mutex = Mutex.new
    private property? batch_running = false
    private getter cache : Cache(K, V)

    def initialize(@cache = MemoryCache(K, V).new)
    end

    def key_for(object : O) : K
      object
    end

    def load(object : O) : V
      key = key_for(object)

      cache.get(key) do
        enqueue_and_wait(key, object)
      end
    end

    def load(objects : Array(O)) : Array(V)
      objects.map { |object| load(object) }
    end

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
