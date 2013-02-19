module DEVS
  class Model
    attr_accessor :name, :parent
    attr_reader :input_ports, :output_ports

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

    # Returns the full path name
    #
    # @example
    #   "CoupledModel_1::AtomicModel_1"
    def path
      if parent.nil?
        name
      else
        "#{parent.path}::#{name}"
      end
    end

    def add_input_port(name = "input_port_#{self.input_ports.size}")
      port = Port.new(self, :input, name)
      @input_ports << port
      port
    end

    def add_output_port(name = "output_port_#{self.output_ports.size}")
      port = Port.new(self, :output, name)
      @output_ports << port
      port
    end

    def input_ports_names
      @input_ports.map { |port| port.name }
    end

    def find_input_port_by_name(name)
      @input_ports.each { |port| return port if port.name == name }
    end

    def output_ports_names
      @output_ports.map { |port| port.name }
    end

    def find_output_port_by_name(name)
      @output_ports.each { |port| return port if port.name == name }
    end

    def output_messages
      messages = []
      @output_ports.each do |port|
        value = port.outgoing
        messages << Message.new(value, port) unless value.nil?
      end
      messages
    end

    def add_input_messages(*messages)
      messages.each do |message|
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
    end
    alias_method :add_input_message, :add_input_messages

    protected
    def find_or_create_input_port_if_necessary(port)
      if port.nil?
        port = add_input_port
      else
        if !port.respond_to?(:name)
          port = find_input_port_by_name(port)
        end
      end
      port
    end

    def find_or_create_output_port_if_necessary(port)
      if port.nil?
        port = add_output_port
      else
        if !port.respond_to?(:name)
          port = find_output_port_by_name(port)
        end
      end
      port
    end
  end
end
