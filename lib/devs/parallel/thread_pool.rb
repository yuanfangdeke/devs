module DEVS
  class ThreadPool
    attr_reader :spawned, :completed, :waiting, :keep_alive_time,
                :min_pool_size, :max_pool_size

    attr_accessor :trim_requests

    class AutoTrim
      attr_accessor :timeout

      def initialize(pool, timeout)
        @pool = pool
        @timeout = timeout
        @running = false
      end

      def run!
        @running = true

        @thread = Thread.new do
          while @running
            @pool.trim
            sleep @timeout
          end
        end
      end

      def stop
        @running = false
        @thread.wakeup
      end

      def timeout=(value)
        @timeout = value
        @thread.wakeup
      end
    end

    def initialize(min = 1, max = nil, &block)
      @block = block

      @lock = Mutex.new
      @resource = ConditionVariable.new
      @queue = []

      @spawned = 0
      @waiting = 0
      @completed = 0
      @trim_requests = 0

      @shutdown = false
      @auto_trim = nil

      @keep_alive_time = 60

      min = 0 if min < 0
      max = min if max.nil? || max < min
      @min_pool_size = min
      @max_pool_size = max

      Thread.abort_on_exception = true
      @workers = ThreadGroup.new

      @lock.synchronize do
        @min_pool_size.times { spawn_thread }
      end
    end

    def spawn_thread
      @spawned += 1

      thread = Thread.new do
        loop do
          work = nil
          run = true

          @lock.synchronize do
            while @queue.empty?
              if @trim_requests > 0
                @trim_requests -= 1
                run = false
                break
              end

              if @shutdown
                run = false
                break
              end

              @waiting += 1
              @resource.wait @lock
              @waiting -= 1

              if @shutdown
                run = false
                break
              end
            end

            work = @queue.pop if run
          end

          break unless run
          @block.call work
          @completed += 1
        end

        @lock.synchronize do
          @spawned -= 1
        end
      end

      @workers.add(thread)
      thread
    end
    private :spawn_thread

    def backlog
      @lock.synchronize { @queue.count }
    end

    def <<(work)
      @lock.synchronize do
        raise "Unable to add work, pool shutted down" if @shutdown
        @queue << work
        spawn_thread if @waiting.zero? && @spawned < @max_pool_size
        @resource.signal
      end
    end

    def trim(force = false)
      @lock.synchronize do
        remaining = @spawned - @trim_requests
        if (force || @waiting > 0) && remaining > @min_pool_size
          @trim_requests += 1
          @resource.signal
        end
      end
    end

    def resize(min = 1, max = nil)
      min = 0 if min < 0
      max = min if max < min || max.nil?
      @min_pool_size = min
      @max_pool_size = max

      trim
    end

    def auto_trim?
      @auto_trim != nil
    end

    def auto_trim=(auto)
      if auto && !@auto_trim
        @auto_trim = AutoTrim.new(self, @keep_alive_time)
        @auto_trim.run!
      elsif !auto && @auto_trim
        @auto_trim.stop
        @auto_trim = nil
      end
    end

    def keep_alive_time=(value)
      @keep_alive_time = value
      @auto_trim.timeout = value if @auto_trim
    end

    def shutdown
      @lock.synchronize do
        @shutdown = true
        @resource.broadcast

        @auto_trim.stop if @auto_trim
      end

      @workers.list.each { |thread| thread.join }
    end
  end
end
