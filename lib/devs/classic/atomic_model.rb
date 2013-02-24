module DEVS
  module Classic
    class AtomicModel < Model
      attr_accessor :elapsed, :time
      attr_reader :sigma

      alias_method :clock, :time
      alias_method :t, :time
      alias_method :e, :elapsed

      class << self
        # DEVS functions
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
        alias_method :ta, :time_advance
        alias_method :lambda, :output

        # Hooks
        def post_simulation_hook(&block)
          define_method(:post_simulation_hook, &block) if block
        end
      end

      def initialize
        super

        @elapsed = 0.0
        @sigma = INFINITY
      end

      def atomic?
        true
      end

      def observer?
        self.respond_to? :post_simulation_hook
      end

      # observer method
      def update(hook, *args)
        self.send("#{hook}_hook", *args)
      end

      # Send an output value to the specified output {Port}
      #
      # @param value [Object] the output value
      # @param port [Port, String, Symbol] the output port or its name
      # @todo
      def post(value, port)
        raise ArgumentError, "port argument cannot be nil" if port.nil?
        if !port.respond_to?(:name)
          port = find_input_port_by_name(port)
          raise ArgumentError, "the given port doesn't exists" if port.nil?
        end

        unless port.host == self
          raise InvalidPortHostError, "The given port doesn't belong to this \
          model"
        end

        unless port.output?
          raise InvalidPortTypeError, "The given port isn't an output port"
        end

        port.outgoing = value
      end

      # Retrieve a {Message} from the specified input {Port}
      #
      # @param port [Port, String, Symbol] the port or its name
      # @return [Object] the input value if any, nil otherwise
      def retrieve(port)
        raise ArgumentError, "port argument cannot be nil" if port.nil?
        if !port.respond_to?(:name)
          port = find_input_port_by_name(port)
          raise ArgumentError, "the given port doesn't exists" if port.nil?
        end

        unless port.host == self
          raise InvalidPortHostError, "The given port doesn't belong to this \
          model"
        end

        unless port.input?
          raise InvalidPortTypeError, "The given port isn't an input port"
        end

        port.incoming
      end

      # Builds the outgoing messages added in the output function for the
      # current state
      #
      # @return [Array<Message>]
      def fetch_output
        self.output

        messages = []
        @output_ports.each do |port|
          value = port.outgoing
          messages << Message.new(value, port) unless value.nil?
        end

        messages
      end

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

      # DEVS functions
      def external_transition; end

      def internal_transition; end

      def time_advance
        @sigma
      end

      def output; end

      protected
      attr_writer :sigma
    end
  end
end
