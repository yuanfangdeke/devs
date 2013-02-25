module DEVS

  # This class represents a port that belong to a {Model} (the {#host}).
  class Port
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

      @incoming = []
      @outgoing = []
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

    # Append the given <i>message</i> to incoming messages
    #
    # @param message [Message] the received message
    # @return [Message] the incoming message
    def add_incoming(message)
      @incoming << message
    end

    # Pop a {Message} from incoming messages
    #
    # @return [Message] an incoming message
    def pop_incoming
      @incoming.pop
    end

    # Append the given <i>message</i> to outgoing messages
    #
    # @param message [Message] the posted message
    # @return [Message] the outgoing message
    def add_outgoing(message)
      if @outgoing.count == 1
        raise MessageAlreadySentError, "An outgoing message already exists on "\
            + "this port"
      else
        @outgoing << message
      end
    end

    # Pop a {Message} from outgoing messages
    #
    # @return [Message] an outgoing message
    def pop_outgoing
      @outgoing.pop
    end
  end
end
