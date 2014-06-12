module DEVS
  class LadderQueueScheduler
    def initialize(elements = nil)
      @queue = LadderQueue.new(elements)
    end

    def size
      @queue.size
    end

    def empty?
      @queue.size.zero?
    end

    def read
      return nil if empty?
      @queue.peek.time_next
    end

    def imminent(time)
      a = []
      a << @queue.pop while @queue.peek.time_next == time
      a
    end

    def schedule(processor)
      @queue.push(processor)
    end

    def unschedule(processor)
      @queue.delete(processor)
    end
  end
end
