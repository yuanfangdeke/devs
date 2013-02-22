module DEVS
  class Message
    attr_reader :payload, :port
    alias_method :value, :payload

    def initialize(payload, port)
       @payload = payload
       @port = port
    end

    def ==(other)
      @port == other.port
    end
  end
end
