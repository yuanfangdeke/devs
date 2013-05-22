module DEVS
  class Dispatcher
    def initialize
      @queue = Queue.new
      @run = false
    end

    def dispatch(processor, event)
      @queue << [processor, event.dup]
    end

    def run!
      @run = true

      @thread = Thread.new do
        pool = ThreadPool.new(4) do |ary|
          processor, event = *ary
          processor.dispatch(event)
        end

        pool << @queue.pop while @run

        pool.shutdown
      end
    end

    def stop
      @run = false
    end
  end
end
