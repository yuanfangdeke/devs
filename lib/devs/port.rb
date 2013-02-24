module DEVS

  # This class represents a port that belong to a {Model} (the {#host}).
  class Port
    attr_accessor :incoming, :outgoing
    attr_reader :type, :name, :host

    def self.types
      [:input, :output]
    end

    # Returns a new {Port} instance.
    #
    # @param host [Model] the owner of self
    # @param type [Symbol] the type of port, either `:input` or `:output`
    # @param name [String, Symbol] the name given to identify the port
    def initialize(host, type, name)
      type = type.downcase.to_sym unless type.nil?
      if Port.types.include?(type)
        @type = type
      else
        raise ArgumentError, "type attribute must be either of #{Port.types}"
      end
      @name = name.to_sym
      @host = host

      @incoming = nil
      @outgoing = nil
    end

    # Check if self is an input port
    #
    # @return [Boolean] true if self is an input port, false otherwise
    def input_port?
      type == :input
    end
    alias_method :input?, :input_port?

    # Check if self is an output port
    #
    # @return [Boolean] true if self is an output port, false otherwise
    def output_port?
      type == :output
    end
    alias_method :output?, :output_port?

    def to_s
      input? ? "-->#{name}" : "#{name}-->"
    end

    def incoming
      message = @incoming
      @incoming = nil
      message
    end

    def outgoing
      message = @outgoing
      @outgoing = nil
      message
    end

    def outgoing=(value)
      unless @outgoing.nil?
        raise MessageAlreadySentError, "An outgoing message already exists"
      end
      @outgoing = value
    end

    def incoming=(value)
      @incoming = value
    end
  end
end
