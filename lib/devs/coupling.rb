module DEVS
  # This class represent the coupling between two DEVS models.
  class Coupling
    attr_reader :source, :destination, :port_source, :destination_port

    # Returns a new {Coupling} instance.
    #
    # @param port_source [Port] the output source port attached to a model
    # @param destination_port [Port] the input destination port attached to
    #   a model
    # @raise [InvalidPortTypeError] if the port_source is not an output port or
    #   if the destination_port is not an input port
    def initialize(port_source, destination_port)
      unless port_source.output?
        raise InvalidPortTypeError, 'port_source must be an output port'
      end
      unless destination_port.input?
        raise InvalidPortTypeError, 'destination_port must be an input port'
      end
      @port_source = port_source
      @destination_port = destination_port
    end

    # Returns the model attached to the output source port
    #
    # @return [Model] the source model
    def source
      @port_source.host
    end

    # Returns the model attacbed to the input destination port
    #
    # @return [Model] the destination model
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
      "[#{source.name}@#{port_source.name}, " \
      + "#{destination.name}@#{destination_port.name}]"
    end
  end
end
