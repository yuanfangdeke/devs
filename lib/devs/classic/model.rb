module DEVS
  module Classic
    class Model
      attr_accessor :name, :parent, :processor
      attr_reader :input_ports, :output_ports

      # Returns a new {Model} instance.
      def initialize
        @name = "#{self.class}_#{self.object_id}"
        @input_ports = []
        @output_ports = []
      end

      # Check if self is an atomic model
      #
      # @return [Boolean]
      def atomic?
        false
      end

      # Check if self is a coupled model
      #
      # @return [Boolean]
      def coupled?
        false
      end

      # Adds an input port to <i>self</i>.
      #
      # @param name [String, Symbol]
      # @return [Port] the newly created port
      def add_input_port(name = "input_port_#{self.input_ports.size}")
        port = Port.new(self, :input, name)
        @input_ports << port
        port
      end

      # Adds an output port to <i>self</i>.
      #
      # @param name [String, Symbol] the port name
      # @return [Port] the newly created port
      def add_output_port(name = "output_port_#{self.output_ports.size}")
        port = Port.new(self, :output, name)
        @output_ports << port
        port
      end

      # Returns the list of input ports' names
      #
      # @return [Array<String, Symbol>] the name list
      def input_ports_names
        @input_ports.map { |port| port.name }
      end

      # Find the input {Port} identified by the given <i>name</i>
      #
      # @param name [String, Symbol] the port name
      # @return [Port] the matching port, nil otherwise
      def find_input_port_by_name(name)
        @input_ports.find { |port| port.name == name }
      end

      # Returns the list of output ports' names
      #
      # @return [Array<String, Symbol>] the name list
      def output_ports_names
        @output_ports.map { |port| port.name }
      end

      # Find the output {Port} identified by the given <i>name</i>
      #
      # @param name [String, Symbol] the port name
      # @return [Port] the matching port, nil otherwise
      def find_output_port_by_name(name)
        @output_ports.find { |port| port.name == name }
      end

      # Find any {Port} identified by the given <i>name</i>
      #
      # @return [Port] the matching port if any, nil otherwise
      def [](name)
        find_input_port_by_name(name) || find_output_port_by_name(name)
      end

      def to_s
        name.to_s
      end

      protected

      # Find or create an input port if necessary. If the given argument is nil,
      # an input port is created with a default name. Otherwise, an attempt to
      # find the matching port is made. If the given port doesn't exists, it is
      # created with the given name.
      #
      # @param port [String, Symbol] the input port name
      # @return [Port] the matching port or the newly created port
      def find_or_create_input_port_if_necessary(port)
        if port.nil?
          port = add_input_port
        elsif !port.respond_to?(:name)
          name = port
          port = find_input_port_by_name(name)
          port = add_input_port(name) if port.nil?
        end
        port
      end

      # Find or create an output port if necessary. If the given argument is nil,
      # an output port is created with a default name. Otherwise, an attempt to
      # find the matching port is made. If the given port doesn't exists, it is
      # created with the given name.
      #
      # @param port [String, Symbol] the output port name
      # @return [Port] the matching port or the newly created port
      def find_or_create_output_port_if_necessary(port)
        if port.nil?
          port = add_output_port
        elsif !port.respond_to?(:name)
          name = port
          port = find_output_port_by_name(name)
          port = add_output_port(name) if port.nil?
        end
        port
      end
    end
  end
end
