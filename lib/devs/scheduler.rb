module DEVS
  class Scheduler
    def initialize(children = nil)
      @pq = PQueue.new(children) { |a, b| a.time_next > b.time_next }
    end

    def schedule(model)
      @pq << model
    end

    def read
      top = @pq.top
      top.time_next if top
    end

    def reschedule
      @pq.send :sort!
    end

    def imminent_children(time)
      children = []
      children << @pq.pop while @pq.top.time_next == time
      children
    end
  end
end
