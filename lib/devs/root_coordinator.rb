module DEVS
  class RootCoordinator
    include Logging
    DEFAULT_DURATION = 60

    attr_reader :time, :duration, :child

    alias_method :clock, :time

    def initialize(child, duration = DEFAULT_DURATION)
      @duration = duration
      @time = 0
      @child = child
    end

    def simulate
      @real_start_time = Time.now
      info "*** Beginning simulation at #{@real_start_time} with duration:\
 #{duration}"
      child.dispatch(Event.new(:i, @time))
      @time = child.time_next
      loop do
        info "* Tick at: #{@time}, #{Time.now - @real_start_time} secs elapsed"
        child.dispatch(Event.new(:*, @time))
        @time = child.time_next
        break if @time >= @duration
      end
      info "*** Simulation ended after #{Time.now - @real_start_time} secs."
      info "* Events stats :"
      stats = child.stats
      stats[:total] = stats.values.reduce(&:+)
      info "    OVERALL #{stats}"
      info "* Calling post simulation hooks"
      child.post_simulation_hook
    end
  end
end
