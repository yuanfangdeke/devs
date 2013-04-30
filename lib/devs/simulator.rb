module DEVS
  class Simulator
    include Logging
    attr_accessor :parent
    attr_reader :model, :time_next, :time_last

    # @!attribute [rw] parent
    #   @return [Coordinator] Returns the parent {Coordinator}

    # @!attribute [r] model
    #   @return [Model] Returns the model associated with <i>self</i>

    # @!attribute [r] time_next
    #   @return [Fixnum] Returns the next simulation time at which the
    #     associated {Model} should be activated

    # @!attribute [r] time_last
    #   @return [Fixnum] Returns the last simulation time at which the
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
      when :i then handle_init_event(event)
      when :* then handle_star_event(event)
      when :x then handle_input_event(event)
      when :y then handle_output_event(event)
      end
    end
  end
end
