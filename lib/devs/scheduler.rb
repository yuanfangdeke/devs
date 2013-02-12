module DEVS
  class Scheduler
    def initialize
      @priority_queue = PQueue.new
    end

    def take_events_at_time(time)
      events = []
      while top.time == time
        events << @priority_queue.pop
      end
      events
    end

    def method_missing(method, *args)
      if @priority_queue.respond_to?(method)
        @priority_queue.send(method, *args)
      else
        super
      end
    end
  end
end
