module DEVS
  class LadderQueueScheduler
    def initialize(elements = nil)
      @queue = LadderQueue.new(elements)
    end

    def size
      @queue.size
    end

    def empty?
      @queue.size == 0
    end

    def read
      return nil if @queue.size == 0
      @queue.peek.time_next
    end

    def imminent(time)
      a = []
      a << @queue.pop while @queue.size > 0 && @queue.peek.time_next == time
      a
    end

    def insert(processor)
      @queue.push(processor)
    end

    def cancel(processor)
      @queue.delete(processor)
    end

    def reschedule!; end
  end
end
