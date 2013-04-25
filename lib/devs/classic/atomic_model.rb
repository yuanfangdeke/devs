module DEVS
  module Classic
    class AtomicModel < Model
      attr_accessor :elapsed, :time
      attr_reader :sigma

      # syntax sugaring
      class << self
        # @!group DEVS functions
        def external_transition(&block)
          define_method(:external_transition, &block) if block
        end

        def internal_transition(&block)
          define_method(:internal_transition, &block) if block
        end

        def time_advance(&block)
          define_method(:time_advance, &block) if block
        end

        def output(&block)
          define_method(:output, &block) if block
        end

        alias_method :ext_transition, :external_transition
        alias_method :delta_ext, :external_transition
        alias_method :int_transition, :internal_transition
        alias_method :delta_int, :internal_transition
        alias_method :lambda, :output

        # @!endgroup

        # @!group Hook methods

        def post_simulation_hook(&block)
          define_method(:post_simulation_hook, &block) if block
        end

        # @!endgroup
      end

      def initialize
        super

        @elapsed = 0.0
        @sigma = INFINITY
      end

      # Returns a boolean indicating if <i>self</i> is an atomic model
      #
      # @return [true]
      def atomic?
        true
      end

      # Returns a boolean indicating if <i>self</i> is an observer of hooks
      # events
      #
      # @return [Boolean] true if a hook method is defined, false otherwise
      def observer?
        self.respond_to? :post_simulation_hook
      end

      # Observer callback method. Dispatches the hook event to the appropriate
      # method
      def update(hook, *args)
        self.send("#{hook}_hook", *args)
      end

      # Send an output value to the specified output {Port}
      #
      # @param value [Object] the output value
      # @param port [Port, String, Symbol] the output port or its name
      # @todo
      def post(value, port)
        ensure_output_port(port).outgoing = value
      end

      # Retrieve a {Message} from the specified input {Port}
      #
      # @param port [Port, String, Symbol] the port or its name
      # @return [Object] the input value if any, nil otherwise
      def retrieve(port)
        ensure_input_port(port).incoming
      end

      # Builds the outgoing messages added in the output function for the
      # current state
      #
      # @return [Array<Message>]
      def fetch_output!
        self.output

        @output_ports.each do |port|
          value = port.outgoing
          yield(Message.new(value, port)) unless value.nil?
        end
      end

      # Append an incoming message to the appropriate port's mailbox.
      #
      # @param message [Message] the incoming message
      # @raise [InvalidPortHostError] if <i>self</i> is not the correct host
      #   for this message
      # @raise [InvalidPortTypeError] if the {Message#port} is not an input
      #   port
      def add_input_message(message)
        if message.port.host != self
          raise InvalidPortHostError, "The port associated with the given\
message #{message} doesn't belong to this model"
        end

        unless message.port.input?
          raise InvalidPortTypeError, "The port associated with the given\
message #{message} isn't an input port"
        end

        message.port.incoming = message.payload
      end

      # @!group DEVS functions

      # External transition function (δext)
      def external_transition; end

      # Internal transition function (δint)
      def internal_transition; end

      # Time advance function (ta)
      def time_advance
        @sigma
      end

      # Output function (λ)
      def output; end

      # @!endgroup

      protected
      attr_writer :sigma

      def ensure_port(port)
        raise ArgumentError, "port argument cannot be nil" if port.nil?
        if !port.respond_to?(:name)
          port = find_input_port_by_name(port)
          raise ArgumentError, "the given port doesn't exists" if port.nil?
        end

        unless port.host == self
          raise InvalidPortHostError, "The given port doesn't belong to this \
          model"
        end

        port
      end

      def ensure_input_port(port)
        port = ensure_port(port)
        unless port.input?
          raise InvalidPortTypeError, "The given port isn't an input port"
        end
        port
      end

      def ensure_output_port(port)
        port = ensure_port(port)
        unless port.output?
          raise InvalidPortTypeError, "The given port isn't an output port"
        end
        port
      end
    end
  end
end
