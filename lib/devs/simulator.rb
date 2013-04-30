module DEVS
  class Simulator
    include Logging
    attr_accessor :parent, :time_next, :time_last
    attr_reader :model

    # @!attribute [rw] parent
    #   @return [Processor] Returns the parent {Processor}

    # @!attribute [r] model
    #   @return [Model] Returns the model associated with <i>self</i>

    # @!attribute [rw] time_next
    #   @return [Fixnum] Returns the next simulation time at which the
    #     associated {Model} should be activated

    # @!attribute [rw] time_last
    #   @return [Fixnum] Returns the last simulation time at which the
    #     associated {Model} was activated

    # Returns a new {Processor} instance.
    #
    # @param model [Model] the model associated with this processor
    # @param [#handle_init_event, #handle_star_event, #handle_input_event,
    #   #handle_output_event] strategy the strategy handling dispatched events
    def initialize(model, strategy)
      @model = model
      @strategy = strategy
      @time_next = 0
      @time_last = 0
      @events_count = Hash.new(0)
    end

    def stats
      stats = @events_count.dup
      stats[:total] = stats.values.reduce(&:+)
      info "    #{self.model}: #{stats}"
      @events_count
    end

    # Handles an incoming event
    #
    # @param event [Event] the incoming event
    def dispatch(event)
      @events_count[event.type] += 1
      info "#{self.model} received #{event}"

      case event.type
      when :i then @strategy.handle_init_event(self, event)
      when :* then @strategy.handle_star_event(self, event)
      when :x then @strategy.handle_input_event(self, event)
      when :y then @strategy.handle_output_event(self, event)
      end
    end
  end
end
