module GraphQL::DataLoader
  struct Request(O, K, V)
    record Result(V), value : V

    getter key : K
    getter object : O
    private getter result_channel = Channel(V).new(1)
    private getter exception_channel = Channel(::Exception).new(1)
    private property cached_result : Result(V)?
    private property cached_exception : ::Exception?

    def initialize(@key : K, @object : O)
    end

    def result=(value : V)
      exception_channel.close
      result_channel.send(value)
      result_channel.close
    end

    def raise(exception : ::Exception)
      result_channel.close
      exception_channel.send(exception)
      exception_channel.close
    end

    def result : V
      exception = self.cached_exception ||= exception_channel.receive?
      ::raise exception if exception
      result = self.cached_result ||= Result.new(result_channel.receive)
      result.value
    end
  end
end
