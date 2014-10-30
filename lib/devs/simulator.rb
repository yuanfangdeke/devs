module DEVS
  class Simulator < Processor
    def initialize(model)
      super(model)
      @transition_count = Hash.new(0)
    end

    def transition_stats
      @transition_count
    end
  end
end
