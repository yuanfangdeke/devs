module DEVS
  class RootCoordinator
    DEFAULT_DURATION = 60

    attr_reader :time, :duration, :child

    alias_method :clock, :time

    def initialize(child, duration = DEFAULT_DURATION)
      @duration = duration
      @time = 0
      @child = child
    end

    def simulate
      puts "*** Beginning simulation with duration: #{duration}; clock: #{@time}"
      child.dispatch(Event.new(:i, @time))
      @time = child.time_next
      puts "* Next tick at: #{@time}"
      loop do
        child.dispatch(Event.new(:*, @time))
        @time = child.time_next
        puts "Next tick at: #{@time}"
        break if @time >= @duration
      end
      puts "*** Simulation ended"
    end
  end
end
