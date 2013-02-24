module DEVS
  class Message
    attr_reader :payload, :port

    def initialize(payload, port)
       @payload = payload
       @port = port
    end

    def ==(other)
      @port == other.port
    end

    def to_a
      [@payload, @port]
    end

    def to_s
      "message #{@payload} to #{port.host}@#{port}"
    end
  end
end
