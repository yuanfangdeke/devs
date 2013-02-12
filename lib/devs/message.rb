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
  end
end
