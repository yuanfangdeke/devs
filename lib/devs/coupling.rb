module DEVS
  # This class represent a coupling between two DEVS models.
  class Coupling
    attr_reader :source, :destination, :port_source, :destination_port, :type

    # @!attribute [r] source
    #   @return [Model] Returns the source model
    # @!attribute [r] destination
    #   @return [Model] Returns the receiver model
    # @!attribute [r] port_source
    #   @return [Port] Returns the source port
    # @!attribute [r] destination_port
    #   @return [Port] Returns the receiver port
    # @!attribute [r] type
    #   @return [Symbol] Returns the type of coupling: either <tt>:ic</tt>,
    #     <tt>:eic</tt> or <tt>:eoc</tt>.

    # Returns a new {Coupling} instance.
    #
    # @param port_source [Port] the output source port attached to a model
    # @param destination_port [Port] the input destination port attached to
    #   a model
    # @raise [InvalidPortTypeError] if the port_source is not an output port or
    #   if the destination_port is not an input port
    def initialize(port_source, destination_port, type)
      @port_source = port_source
      @destination_port = destination_port
      @type = type
    end

    # Check if <tt>self</tt> is an internal coupling (IC)
    #
    # @return [Boolean] <tt>true</tt> if <tt>self</tt> is an internal coupling,
    #   <tt>false</tt> otherwise
    def internal?
      @type == :ic
    end

    # Check if <tt>self</tt> is an external input coupling (EIC)
    #
    # @return [Boolean] <tt>true</tt> if <tt>self</tt> is an external input
    #   coupling, <tt>false</tt> otherwise
    def input?
      @type == :eic
    end

    # Check if <tt>self</tt> is an external output coupling (EOC)
    #
    # @return [Boolean] <tt>true</tt> if <tt>self</tt> is an external output
    #   coupling, <tt>false</tt> otherwise
    def output?
      @type == :eoc
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
      @port_source == other.port_source && @destination_port == other.destination_port
    end

    # @return [Array]
    def to_a
      [[source, port_source], [destination, destination_port]]
    end

    # @return [String]
    def to_s
      "[#{source.name}@#{port_source.name}, #{destination.name}@#{destination_port.name}]"
    end

    def inspect
      "<#{self.class}: port_src=#{@port_source}, dest_port=#{@destination_port}>"
    end
  end
end
