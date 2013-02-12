module DEVS
  class CoupledModel < Model
    attr_reader :children, :ic, :eic, :eoc

    alias_method :components, :children
    alias_method :internal_couplings, :ic
    alias_method :external_input_couplings, :eic
    alias_method :external_output_couplings, :eoc

    def initialize
      super
      @children = []
      @ic = []
      @eic = []
      @eoc = []
    end

    def coupled?
      true
    end

    # Append the specified child to children list if it's not already there
    #
    # @param child [Model] the new child
    # @return [Model] the added child
    def add_child(child)
      unless @children.include?(child)
        @children << child
        child.parent = self
      end
      child
    end

    # Returns the children names
    def children_names
      @children.map { |child| child.name }
    end

    def find_child_by_name(name)
      @children.find { |model| model.name == name }
    end

    def find_child_with_path(path = '')
      model = self
      path.split('::').each do |name|
        model = find_child_by_name(name)
      end
    end

    def eic_with_port_source(port)
      @eic.select { |coupling| coupling.port_source == port }
    end

    def ic_with_port_source(port)
      @ic.select { |coupling| coupling.port_source == port }
    end

    def first_eoc_with_port_source(port)
      @eoc.select { |coupling|
        coupling.port_source == port
      }.first
    end

    def select(imminent_children)
      imminent_children.first
    end

    # Add an external input coupling (EIC) to self. Establish a relation between
    # a self input {Port} and an input {Port} of one of self's children.
    #
    # If the ports aren't provided, they will be automatically generated.
    #
    # @param child [Model, String, Symbol] the child or its name
    # @param input_port [Port, String, Symbol] specify the self input port or
    #   its name to connect to the child_port.
    # @param child_port [Port, String, Symbol] specify the child's input port
    #   or its name.
    def add_external_input_coupling(child, input_port = nil, child_port = nil)
      child = ensure_child(child)

      input_port = find_or_create_input_port_if_necessary(input_port)
      child_port = child.find_or_create_input_port_if_necessary(child_port)

      coupling = Coupling.new(input_port, child_port)
      @eic << coupling unless @eic.include?(coupling)
    end
    alias_method :add_external_input, :add_external_input_coupling

    # Add an external output coupling (EOC) to self. Establish a relation
    # between an output {Port} of one of self's children and one of self's
    # output ports.
    #
    # If the ports aren't provided, they will be automatically generated.
    #
    # @param child [Model, String, Symbol] the child or its name
    # @param output_port [Port, String, Symbol] specify the self output port or
    #   its name to connect to the child_port.
    # @param child_port [Port, String, Symbol] specify the child's output port
    #   or its name.
    def add_external_output_coupling(child, output_port = nil, child_port = nil)
      child = ensure_child(child)

      output_port = find_or_create_output_port_if_necessary(output_port)
      child_port = child.find_or_create_output_port_if_necessary(child_port)

      coupling = Coupling.new(output_port, child_port)
      @eoc << coupling unless @eoc.include?(coupling)
    end
    alias_method :add_external_output, :add_external_output_coupling

    # Add an internal coupling (IC) to self. Establish a relation between an
    # output {Port} of a first child and the input {Port} of a second child.
    #
    # If the ports parameters are ommited, they will be automatically generated.
    #
    # @param a [Model, String, Symbol] the first child or its name
    # @param b [Model, String, Symbol] the second child or its name
    # @param output_port [Port, String, Symbol] a's output port or its name
    # @param input_port [Port, String, Symbol] b's output port ot its name
    def add_internal_coupling(a, b, output_port = nil, input_port = nil)
      a = ensure_child(a)
      b = ensure_child(b)

      output_port = a.find_or_create_output_port_if_necessary(output_port)
      input_port = b.find_or_create_input_port_if_necessary(input_port)

      coupling = Coupling.new(output_port, input_port)
      @ic << coupling unless @ic.include?(coupling)
    end

    private
    def ensure_child(child)
      if !child.respond_to?(:name)
        child = find_child_by_name(child)
      end
      raise NoSuchChildError, "the child argument cannot be nil" if child.nil?
      child
    end
  end
end
