module GraphQL::DataLoader
  struct Request(O, K, V)
    getter key : K
    getter object : O
    private getter result_channel = Channel(V).new(1)
    private getter exception_channel = Channel(Exception).new(1)

    def initialize(@key : K, @object : O)
    end

    def result=(value : V)
      exception_channel.close
      result_channel.send(value)
      result_channel.close
    end

    def raise(exception : Exception)
      result_channel.close
      exception_channel.send(exception)
      exception_channel.close
    end

    def result : V
      exception = exception_channel.receive?
      raise exception if exception

      result_channel.receive
    end
  end
end
