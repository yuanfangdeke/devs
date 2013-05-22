module DEVS
  # This class represent an event passing between simulators and is essential
  # to implement the DEVS communication protocol
  class Event
    include Comparable
    attr_reader :type, :time, :message

    # @!attribute [r] type
    #   Represent the type of event exchanged between a parent simulation
    #   component (either {Simulator} or {Coordinator}) and its subordinate.
    #   @return [Symbol] Returns the event type included in {Event.types}
    # @!attribute [r] time
    #   @return [Fixnum] Returns the simulation time at which the event was
    #     emitted
    # @!attribute [r] message
    #   @return [Message] Returns the message associated with this event

    # Returns a new {Event} instance.
    #
    # @param type [Symbol] the type of event
    # @param time [Numeric] the time at which the event was emitted
    # @param message [Message] the message carrying the payload
    # @raise [ArgumentError] if the given time is not in a correct range
    def initialize(type, time, message = nil)
      @type = type

      if (0..INFINITY).include?(time)
        @time = time
      else
        raise ArgumentError, "time attribute must be within 0 and INFINITY"
      end

      @message = message
    end

    # Comparison - Returns an integer (-1, 0 or +1) if this event is less than,
    # equal to, or greater than <i>other</i>. The comparison is based on the
    # time of each event (descending).
    #
    # @param other [Event] the event to compare to
    # @return [Integer]
    def <=>(other)
      other.time <=> @time
    end

    def to_s
      s = "event #{@type} at #{@time}"
      s = "#{s} with #{@message}" if message
      s
    end
  end
end
