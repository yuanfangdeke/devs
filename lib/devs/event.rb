module DEVS
  # This class represent an event passing between simulators and is essential
  # to implement the DEVS communication protocol
  class Event
    include Comparable
    attr_reader :type, :time, :bag

    # @!attribute [r] type
    #   Represent the type of event exchanged between a parent simulation
    #   component (either {Simulator} or {Coordinator}) and its subordinate.
    #   @return [Symbol] Returns the event type included in {Event.types}
    # @!attribute [r] time
    #   @return [Numeric] Returns the simulation time at which the event was
    #     emitted
    # @!attribute [r] bag
    #   @return [Array<Message>] Returns the bag associated with this event

    # Returns a new {Event} instance.
    #
    # @param type [Symbol] the type of event
    # @param time [Numeric] the time at which the event was emitted
    # @param bag [Array<Message>] the bag carrying the messages
    def initialize(type, time, bag = nil)
      @type = type
      @time = time
      @bag = bag
    end

    # Comparison - Returns an integer (-1, 0 or +1) if this event is less than,
    # equal to, or greater than <tt>other</tt>. The comparison is based on the
    # time of each event (descending).
    #
    # @param other [Event] the event to compare to
    # @return [Integer]
    def <=>(other)
      other.time <=> @time
    end

    def ==(other)
      @type == other.type && @time == other.time
    end

    # Append the given message(s) on to the bag
    #
    # @param args [Message] a variable list of messages
    def <<(*args)
      (@bag ||= []).push(*args)
    end

    def inspect
      "<#{self.class}: type:#{@type}, time:#{@time}>"
    end
  end
end
