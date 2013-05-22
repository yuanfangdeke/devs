module DEVS
  module Concurrency
    # This class is an implementation of the thread pool pattern
    class ThreadPool
      attr_reader :spawned, :completed, :waiting, :keep_alive_time,
                  :min_pool_size, :max_pool_size

      attr_accessor :trim_requests

      # This class spawns a thread responsible for cleaning up worker threads
      # that are no longer necessary to the pool (see {ThreadPool#trim} and
      # {ThreadPool#auto_trim=})
      class AutoTrim
        attr_accessor :timeout

        # Returns a new {AutoTrim} instance.
        #
        # @param pool [ThreadPool] the associate thread pool
        # @param timeout [Fixnum] the frequency (in seconds) at which the thread
        #   will attempt to release unecessary worker threads
        def initialize(pool, timeout)
          @pool = pool
          @timeout = timeout
          @running = false
        end

        # Spawn a new thread responsible for cleaning up worker threads
        def run!
          @running = true

          @thread = Thread.new do
            while @running
              @pool.trim
              sleep @timeout
            end
          end
        end

        # Stop the thread
        def stop
          @running = false
          @thread.wakeup
        end

        # Update the frequency (in seconds) at which the thread will attempt to
        # release release unecessary worker threads
        #
        # @param value [Fixnum] the frequency (in seconds)
        def timeout=(value)
          @timeout = value
          @thread.wakeup
        end
      end

      # Returns a new {ThreadPool} instance.
      #
      # @param min [Fixnum] the minimum number of threads waiting to do some work
      # @param max [Fixnum] the maximum number of threads to spawn when the pool
      #   is overloaded
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

      # Spawn a new thread
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

      # Returns the remaining amount of work.
      #
      # @return [Fixnum] the amount
      def backlog
        @lock.synchronize { @queue.count }
      end

      # Append a resource to the queue that will be consumed by a thread at some
      # point.
      #
      # @param work [Object] the resource
      def <<(work)
        @lock.synchronize do
          raise "Unable to add work, pool shutted down" if @shutdown
          @queue << work
          spawn_thread if @waiting.zero? && @spawned < @max_pool_size
          @resource.signal
        end
      end

      # Trim a spawned thread if the number of threads is above its minimal value.
      #
      # @param force [Boolean] a boolean value indicating if the trim requested
      #   should be considered even if the pool size reached its minimal value.
      def trim(force = false)
        @lock.synchronize do
          remaining = @spawned - @trim_requests
          if (force || @waiting > 0) && remaining > @min_pool_size
            @trim_requests += 1
            @resource.signal
          end
        end
      end

      # Resize the thread pool according to the given values.
      #
      # @param min [Fixnum] the new minimum number of waiting threads
      # @param max [Fixnum] the maximum number of spawned threads
      def resize(min = 1, max = nil)
        min = 0 if min < 0
        max = min if max < min || max.nil?
        @min_pool_size = min
        @max_pool_size = max

        trim
      end

      # Returns a boolean indicating if the auto trim feature is active.
      #
      # @return [Boolean] true if <i>self</i> the auto trim feature is active,
      #   false otherwise
      def auto_trim?
        @auto_trim != nil
      end

      # Activate or deactivate the auto trim feature.
      #
      # @param auto [Boolean] true to activate the feature, false otherwise
      def auto_trim=(auto)
        if auto && !@auto_trim
          @auto_trim = AutoTrim.new(self, @keep_alive_time)
          @auto_trim.run!
        elsif !auto && @auto_trim
          @auto_trim.stop
          @auto_trim = nil
        end
      end

      # Change the time to keep alive extra worker threads.
      #
      # @param value [Fixnum] the value in seconds to keep alive extra worker
      #   threads
      def keep_alive_time=(value)
        @keep_alive_time = value
        @auto_trim.timeout = value if @auto_trim
      end

      # Shutdown <i>self</i>, killing all threads.
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
end
