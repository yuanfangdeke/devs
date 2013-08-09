module DEVS
  # This class represent a DEVS coupled model.
  class CoupledModel < Model
    include Enumerable

    attr_reader :children, :internal_couplings, :input_couplings,
                :output_couplings

    alias_method :components, :children

    # @!attribute [r] children
    #   This attribute returns a list of all its child models, composed of
    #   {AtomicModel}s or/and {CoupledModel}s.
    #   @return [Array<Model>] Returns a list of all its child models

    # @!attribute [r] internal_couplings
    #   This attribute returns a list of all its <i>internal couplings</i> (IC).
    #   An internal coupling connects two {#children}: an output {Port} of
    #   the first {Model} is thereby connected to an input {Port} of the
    #   second child.
    #   @see #add_internal_coupling
    #   @return [Array<Coupling>] Returns a list of all its
    #     <i>internal couplings</i> (IC)

    # @!attribute [r] input_couplings
    #   This attribute returns a list of all its
    #   <i>external input couplings</i> (EIC). Each of them links one of all
    #   {#children} to one of its own {Port}. More precisely, it links an
    #   input {Port} of <i>self</i> to an input {Port} of the child.
    #   @see #add_external_input_coupling
    #   @return [Array<Coupling>] Returns a list of all its
    #     <i>external input couplings</i> (EIC)

    # @!attribute [r] output_couplings
    #   This attribute returns a list of all its
    #   <i>external output couplings</i> (EOC). Each of them links one of all
    #   {#children} to one of its own {Port}. More precisely, it links an
    #   output {Port} of the child to an output {Port} of <i>self</i>.
    #   @see #add_external_input_coupling
    #   @return [Array<Coupling>] Returns a list of all its
    #     <i>external output couplings</i> (EOC)

    # Returns a new instance of {CoupledModel}
    def initialize
      super
      @children = []
      @internal_couplings = []
      @input_couplings = []
      @output_couplings = []
    end

    # Returns a boolean indicating if <tt>self</tt> is a coupled model
    #
    # @return [true]
    def coupled?
      true
    end

    # Append the specified child to children list if it's not already there
    #
    # @param child [Model] the new child
    # @return [Model] the added child
    def <<(child)
      unless @children.include?(child)
        @children << child
        child.parent = self
      end
      child
    end
    alias_method :add_child, :<<

    # Returns the children names
    #
    # @return [Array<String, Symbol>] the children names
    def children_names
      @children.map { |child| child.name }
    end

    # Find the component {Model} identified by the given <tt>name</tt>
    #
    # @param name [String, Symbol] the component name
    # @return [Model] the matching component, nil otherwise
    def [](name)
      @children.find { |model| model.name == name }
    end
    alias_method :find_child_by_name, :[]

    # Calls <tt>block</tt> once for each child in <tt>self</tt>, passing that
    # element as a parameter.
    #
    # If no block is given, an {Enumerator} is returned instead.
    # @overload each
    #   @yieldparam child [Model] the child that is yielded
    #   @return [nil]
    # @overload each
    #   @return [Enumerator<Model>]
    def each
      if block_given?
        @children.each { |child| yield(child) }
      else
        @children.each
      end
    end

    # Calls <tt>block</tt> once for each external input coupling (EIC) in
    # {#input_couplings}, passing that element as a parameter. If a port is
    # given, it is used to filter the couplings having this port as a source.
    #
    # @param port [Port, nil] the source port or nil
    # @yieldparam coupling [Coupling] the coupling that is yielded
    def each_input_coupling(port = nil, &block)
      each_coupling(@input_couplings, port, &block)
    end

    # Calls <tt>block</tt> once for each internal coupling (IC) in
    # {#internal_couplings}, passing that element as a parameter. If a port is
    # given, it is used to filter the couplings having this port as a source.
    #
    # @param port [Port, nil] the source port or nil
    # @yieldparam coupling [Coupling] the coupling that is yielded
    def each_internal_coupling(port = nil, &block)
      each_coupling(@internal_couplings, port, &block)
    end

    # Calls <tt>block</tt> once for each external output coupling (EOC) in
    # {#output_couplings}, passing that element as a parameter. If a port is
    # given, it is used to filter the couplings having this port as a source.
    #
    # @param port [Port, nil] the source port or nil
    # @yieldparam coupling [Coupling] the coupling that is yielded
    def each_output_coupling(port = nil, &block)
      each_coupling(@output_couplings, port, &block)
    end

    # The <i>Select</i> function as defined is the classic DEVS formalism.
    # Select one {Model} among all. By default returns the first. Override
    # if a different behavior is desired
    #
    # @param imminent_children [Array<Model>] the imminent children
    # @return [Model] the selected component
    # @example
    #   def select(imminent_children)
    #     imminent_children.sample
    #   end
    def select(imminent_children)
      imminent_children.first
    end

    # Adds an external input coupling (EIC) to self. Establish a relation between
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

      if !input_port.nil? && !child_port.nil?
        input_port = find_or_create_input_port_if_necessary(input_port)
        child_port = child.find_or_create_input_port_if_necessary(child_port)

        coupling = Coupling.new(input_port, child_port)
        @input_couplings << coupling unless @input_couplings.include?(coupling)
      end
    end
    alias_method :add_external_input, :add_external_input_coupling

    # Adds an external output coupling (EOC) to self. Establish a relation
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

      if !output_port.nil? && !child_port.nil?
        output_port = find_or_create_output_port_if_necessary(output_port)
        child_port = child.find_or_create_output_port_if_necessary(child_port)

        coupling = Coupling.new(child_port, output_port)
        @output_couplings << coupling unless @output_couplings.include?(coupling)
      end
    end
    alias_method :add_external_output, :add_external_output_coupling

    # Adds an internal coupling (IC) to self. Establish a relation between an
    # output {Port} of a first child and the input {Port} of a second child.
    #
    # If the ports parameters are ommited, they will be automatically
    # generated. Otherwise, the specified ports will be used. If a name is
    # given instead
    #
    # @param a [Model, String, Symbol] the first child or its name
    # @param b [Model, String, Symbol] the second child or its name
    # @param output_port [Port, String, Symbol] a's output port or its name
    # @param input_port [Port, String, Symbol] b's input port ot its name
    # @raise [FeedbackLoopError] if both given children are the same instance.
    #   Feeding a model's input port with one of its output ports is not allowed
    #   in the DEVS formalism
    def add_internal_coupling(a, b, output_port = nil, input_port = nil)
      a = ensure_child(a)
      b = ensure_child(b)
      raise FeedbackLoopError, "#{a} must be different than #{b}" if a == b

      output_port = a.find_or_create_output_port_if_necessary(output_port)
      input_port = b.find_or_create_input_port_if_necessary(input_port)

      coupling = Coupling.new(output_port, input_port)
      @internal_couplings << coupling unless @internal_couplings.include?(coupling)
    end

    private

    def ensure_child(child)
      if !child.respond_to?(:name)
        child = self[child]
      end
      raise NoSuchChildError, "the child argument cannot be nil" if child.nil?
      child
    end
  end
end
