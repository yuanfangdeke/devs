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
      after_initialize if respond_to?(:after_initialize)
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
    #
    # @param child [Processor] the processor to append
    # @return [Processor] the newly added processor
    def <<(child)
      unless @children.include?(child)
        @children << child
        child.parent = self
      end
      child
    end
    alias_method :add_child, :<<

    # Deletes the specified child from {#children} list
    #
    # @param child [Processor] the child to remove
    # @return [Processor] the deleted child
    def remove_child(child)
      if @children.include?(child)
        @children.delete(child)
        child.parent = nil
      end
      child
    end

    # Returns a subset of {#children} including imminent children, e.g with
    # a time next value matching {#time_next}.
    #
    # @return [Array<Model>] the imminent children
    def imminent_children
      @children.select { |child| child.time_next == @time_next }
    end

    # Returns the minimum time next in all children
    #
    # @return [Numeric] the min time next
    def min_time_next
      min = DEVS::INFINITY
      i = 0
      while i < @children.size
        tn = @children[i].time_next
        min = tn if tn < min
        i += 1
      end
      min
    end

    # Returns the maximum time last in all children
    #
    # @return [Numeric] the max time last
    def max_time_last
      max = 0
      i = 0
      while i < @children.size
        tl = @children[i].time_last
        max = tl if tl > max
        i += 1
      end
      max
    end
  end
end
