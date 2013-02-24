module DEVS
  module Classic
    class CoupledModel < Model
      include Enumerable

      attr_reader :children, :internal_couplings, :input_couplings,
                  :output_couplings

      alias_method :components, :children

      def initialize
        super
        @children = []
        @internal_couplings = []
        @input_couplings = []
        @output_couplings = []
      end

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

      # Find the component {Model} identified by the given <i>name</i>
      #
      # @param name [String, Symbol] the component name
      # @return [Model] the matching component, nil otherwise
      def [](name)
        @children.find { |model| model.name == name }
      end
      alias_method :find_child_by_name, :[]

      def find_child_with_path(path = '')
        model = self
        path.split('::').each do |name|
          model = self[name]
        end
      end

      def each
        if block_given?
          @children.each { |child| yield(child) }
        else
          @children.each
        end
      end

      def each_input_coupling(port = nil)
        each_coupling(@input_couplings, port)
      end

      def each_internal_coupling(port = nil)
        each_coupling(@internal_couplings, port)
      end

      def each_output_coupling(port = nil)
        each_coupling(@output_couplings, port)
      end

      # The <i>Select</i> function as defined is the classic DEVS formalism.
      # Select one {Model} among all. By default returns the first. Override
      # if a different behavior is desired
      #
      # @param imminent_children [Array<Model>] the imminent children
      # @return [Model] the selected component
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
        @input_couplings << coupling unless @input_couplings.include?(coupling)
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
        @output_couplings << coupling unless @output_couplings.include?(coupling)
      end
      alias_method :add_external_output, :add_external_output_coupling

      # Add an internal coupling (IC) to self. Establish a relation between an
      # output {Port} of a first child and the input {Port} of a second child.
      #
      # If the ports parameters are ommited, they will be automatically
      # generated. Otherwise, the specified ports will be used. If a name is
      # given instead
      #
      # @param a [Model, String, Symbol] the first child or its name
      # @param b [Model, String, Symbol] the second child or its name
      # @param output_port [Port, String, Symbol] a's output port or its name
      # @param input_port [Port, String, Symbol] b's output port ot its name
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

      def each_coupling(ary, port = nil)
        couplings = port ? ary.select { |c| c.port_source == port } : ary
        couplings.each { |coupling| yield(coupling) } if block_given?
      end
    end
  end
end
