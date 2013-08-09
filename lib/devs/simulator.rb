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
      stats
    end
  end
end
