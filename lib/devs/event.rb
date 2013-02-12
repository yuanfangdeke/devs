module DEVS
  class Event
    include Comparable

    # Represent the list of possible events exchanged between a parent
    # simulation component (either {Simulator} or {Coordinator}) and its
    # subordinate.
    #
    # 1. the :i represent the initialization
    # 2. the :x represent an input message
    # 3. the :* represent the internal transition
    # 4. the :y represent an output message
    #
    # The first three types are sent respectively from a parent to its children.
    # The last one is sent from a child to its parent.
    TYPES = [:i, :x, :*, :y]

    attr_reader :type, :time, :message

    def initialize(type, time, message = nil)
      if TYPES.include?(type)
        @type = type
      else
        raise ArgumentError, "type attribute must be either one in #{TYPES}"
      end

      if (0..INFINITY).include?(time)
        @time = time
      else
        raise ArgumentError, "time attribute must be within 0 and INFINITY"
      end

      @message = message
    end

    def <=>(other)
      other.time <=> @time
    end
  end
end
