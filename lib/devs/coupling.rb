module DEVS
  class Coupling
    attr_reader :source, :destination, :port_source, :destination_port

    def initialize(port_source, destination_port)
      @port_source = port_source
      @destination_port = destination_port
    end

    def source
      @port_source.host
    end

    def destination
      @destination_port.host
    end

    def ==(other)
      @source == other.source && @destination == other.destination
    end

    def to_a
      [[source, port_source], [destination, destination_port]]
    end

    def to_s
      "[#{source.name}@#{port_source.name}, #{destination.name}@#{destination}]"
    end
  end
end
