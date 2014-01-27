module DEVS
  # This class represent a simulator associated with an {CoupledModel},
  # responsible to route events to proper children
  class Coordinator < Processor
    attr_reader :children

    # @!attribute [r] children
    #   This attribute returns a list of all its children, composed
    #   of {Simulator}s or/and {Coordinator}s.
    #   @return [Array<Processor, Coordinator>] Returns a list of all its child
    #     processors

    # Returns a new instance of {Coordinator}
    #
    # @param model [CoupledModel] the managed coupled model
    def initialize(model)
      super(model)
      @children = []
    end

    def stats
      stats = {}
      stats[model.name] = super
      children.each { |child|
        if child.kind_of?(Coordinator)
          stats.update(child.stats)
        elsif child.kind_of?(Simulator)
          stats[child.model.name] = child.stats
        end
      }
      stats
    end

    # Append a child to {#children} list, ensuring that the child now has
    # self as parent.
    def <<(child)
      unless @children.include?(child)
        @children << child
        child.parent = self
      end
      child
    end
    alias_method :add_child, :<<
  end
end
