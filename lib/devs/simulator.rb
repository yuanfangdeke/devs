module DEVS
  class Simulator
    include Logging
    attr_accessor :parent
    attr_reader :model, :time_next, :time_last

    # @!attribute [rw] parent
    #   @return [Coordinator] Returns the parent {Coordinator}

    # @!attribute [r] model
    #   @return [Model] Returns the model associated with <tt>self</tt>

    # @!attribute [r] time_next
    #   @return [Numeric] Returns the next simulation time at which the
    #     associated {Model} should be activated

    # @!attribute [r] time_last
    #   @return [Numeric] Returns the last simulation time at which the
    #     associated {Model} was activated

    # Returns a new {Simulator} instance.
    #
    # @param model [Model] the model associated with this processor
    def initialize(model)
      @model = model
      @time_next = 0
      @time_last = 0
      @events_count = Hash.new(0)
    end

    def stats
      stats = @events_count.dup
      stats[:total] = stats.values.reduce(&:+)
      debug "    #{self.model}: #{stats}"
      @events_count
    end

    # Handles an incoming event
    #
    # @param event [Event] the incoming event
    # @raise [RuntimeError] if the processor cannot handle the given event
    #   ({Event#type})
    # def dispatch(event)
    #   @events_count[event.type] += 1
    #   debug "#{self.model} received #{event}"

    #   name = "handle_#{event.type}_event".to_sym
    #   if respond_to?(name)
    #     __send__(name, event)
    #   else
    #     raise RuntimeError, "#{self} doesn't respond to #{event.type} events"
    #   end
    # end

    # Ensure the given {Message} is an input {Port} and belongs to {#model}.
    # @param message [Message] the incoming message
    # @raise [InvalidPortHostError] if {#model} is not the correct host
    #   for this message
    # @raise [InvalidPortTypeError] if the {Message#port} is not an input port
#     def ensure_input_message(message)
#       if message.port.host != model
#         raise InvalidPortHostError, "The port associated with the given\
# message #{message} doesn't belong to this model"
#       end

#       unless message.port.input?
#         raise InvalidPortTypeError, "The port associated with the given\
# message #{message} isn't an input port"
#       end

#       message
#     end
#     protected :ensure_input_message
  end
end
