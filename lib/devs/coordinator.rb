module DEVS
  # This class represent a simulator associated with an {CoupledModel},
  # responsible to route events to proper children
  class Coordinator < Simulator
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
      super
      hsh = Hash.new(0)
      hsh.update(@events_count)
      children.each do |child|
        child.stats.each { |key, value| hsh[key] += value }
      end
      hsh
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

    # Returns the minimum time next in all children
    #
    # @return [Numeric] the min time next
    def min_time_next
      @children.map { |child| child.time_next }.min
    end

    # Returns the maximum time last in all children
    #
    # @return [Numeric] the max time last
    def max_time_last
      @children.map { |child| child.time_last }.max
    end

    # Returns a subset of {#children} including imminent children, e.g with
    # a time next value matching {#time_next}.
    #
    # @return [Array<Model>] the imminent children
    def imminent_children
      @children.select { |child| child.time_next == time_next }
    end
  end
end
