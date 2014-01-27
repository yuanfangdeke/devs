module DEVS
  class Simulator < Processor
    def stats
      stats = @events_count.dup
      stats[:total] = stats.values.reduce(&:+)
      stats
    end
  end
end
