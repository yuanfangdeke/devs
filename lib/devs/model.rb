module DEVS
  # @abstract Base model class for {AtomicModel} and {CoupledModel} classes
  class Model
    attr_accessor :name, :parent, :processor
    attr_reader :input_ports, :output_ports

    # @!attribute name
    #   This attribute represent the name of the model.
    #   @return [Symbol] Returns the name of the model

    # @!attribute parent
    #   This attribute represent the parent {CoupledModel}.
    #   @return [CoupledModel] Returns the parent model.

    # @!attribute parent
    #   This attribute represent the associated {Processor}.
    #   @return [Processor] Returns the associated processor.

    # @!attribute [r] input_ports
    #   This attribute represent the list of input {Port}s.
    #   @return [Array<Port>] Returns the array of input ports.

    # @!attribute [r] output_ports
    #   This attribute represent the list of output {Port}s.
    #   @return [Array<Port>] Returns the array of output ports.

    # Returns a new {Model} instance.
    #
    # @param name [String, Symbol] the name of the model
    def initialize(name = nil)
      @name = name.to_sym unless name == nil
      @input_ports = []
      @output_ports = []
    end

    def name=(name)
      name = name.to_sym
      @parent.rename_child(name, @name) if @parent && @name
      @name = name
    end

    # Returns a boolean indicating if <tt>self</tt> is an atomic model
    #
    # @return [false]
    def atomic?
      false
    end

    # Returns a boolean indicating if <tt>self</tt> is an atomic model
    #
    # @return [false]
    def coupled?
      false
    end

    def inspect
      "<#{self.class}: name=#{@name}>"
    end

    # Adds an input port to <tt>self</tt>.
    #
    # @param name [String, Symbol]
    # @return [Port, Array<Port>] the created port or the list of created ports
    def add_input_port(*names)
      add_port(:input, *names)
    end

    # Adds an output port to <tt>self</tt>.
    #
    # @param name [String, Symbol] the port name
    # @return [Port, Array<Port>] the created port or the list of created ports
    def add_output_port(*names)
      add_port(:output, *names)
    end

    # Returns the list of input ports' names
    #
    # @return [Array<String, Symbol>] the name list
    def input_ports_names
      @input_ports.map { |port| port.name }
    end

    # Find the input {Port} identified by the given <tt>name</tt>
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

    # Find the output {Port} identified by the given <tt>name</tt>
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

    # @return [String]
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
      find_or_create_port_if_necessary(:input, port)
    end

    # Find or create an output port if necessary. If the given argument is nil,
    # an output port is created with a default name. Otherwise, an attempt to
    # find the matching port is made. If the given port doesn't exists, it is
    # created with the given name.
    #
    # @param port [String, Symbol] the output port name
    # @return [Port] the matching port or the newly created port
    def find_or_create_output_port_if_necessary(port)
      find_or_create_port_if_necessary(:output, port)
    end

    private

    def find_or_create_port_if_necessary(type, port)
      unless port.kind_of?(Port)
        name = port
        port = case type
        when :output then find_output_port_by_name(name)
        when :input then find_input_port_by_name(name)
        end

        if port.nil?
          port = add_port(type, name)
          DEVS.logger.warn("specified #{type} port #{name} doesn't exist for #{self}. creating it") if DEVS.logger
        end
      end
      port
    end

    def add_port(type, *names)
      ivar, existing = case type
      when :input  then [@input_ports, input_ports_names]
      when :output then [@output_ports, output_ports_names]
      end

      ports = []
      names.each do |n|
        if existing.include?(n.to_sym)
          DEVS.logger.warn(
            "specified #{type} port #{n} already exists for #{self}. skipping..."
          ) if DEVS.logger
        else
          ports << Port.new(self, type, n)
        end
      end

      ivar.concat(ports)
      ports.size == 1 ? ports.first : ports
    end
  end
end
