module DEVS

  # This class represents a port that belong to a {Model} (the {#host}).
  class Port
    attr_reader :type, :name, :host

    # Represent the list of possible type of ports.
    #
    # 1. :input for an input port
    # 2. :output for an output port
    #
    # @return [Array<Symbol>] the port types
    def self.types
      [:input, :output]
    end

    # Returns a new {Port} instance.
    #
    # @param host [Model] the owner of self
    # @param type [Symbol] the type of port, either `:input` or `:output`
    # @param name [String, Symbol] the name given to identify the port
    # @raise [ArgumentError] if the specified type is unknown
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

    # Read the incoming {Message} if any and empty the mailbox.
    #
    # @return [Message] the incoming message or nil
    def incoming
      message = @incoming
      @incoming = nil
      message
    end

    # Read the outgoing {Message} if any and empty the mailbox.
    #
    # @return [Message] the outgoing message or nil
    def outgoing
      message = @outgoing
      @outgoing = nil
      message
    end

    # Put an outgoing {Message} into the mailbox.
    #
    # @param value [Message] the message to send
    # @raise [MessageAlreadySentError] if an outgoing {Message} is already
    #   waiting to be picked up
    def outgoing=(value)
      unless @outgoing.nil?
        raise MessageAlreadySentError, "An outgoing message already exists"
      end
      @outgoing = value
    end

    # Put an incoming {Message} into the mailbox.
    #
    # @param value [Message] the input message
    def incoming=(value)
      @incoming = value
    end
  end
end
