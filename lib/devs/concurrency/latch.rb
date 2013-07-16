module DEVS
  module Concurrency
    # This class is an implementation of a latch. It allows to coordinate the
    # starting and stopping of threads.
    #
    # In concurrent programming, a <b>latch</b> is a type of "switch" or "trigger".
    # The latch is set up with a particular <i>count</i> value. The count is then
    # <i>counted down</i>, and at strategic moments, a thread or threads waits for
    # the countdown to reach zero before continuing to perform some process.
    class Latch

      # Returns a new {Latch} instance.
      #
      # @param count [Numeric] the specified count
      # @raise [ArgumentError] if count is not a positive value
      def initialize(count = 1)
        raise ArgumentError, "count should be positive" if count < 0
        @count = count
        @lock = Mutex.new
        @resource = ConditionVariable.new
      end

      # Reset the count to the given value.
      #
      # @note The count should have reached zero in order to reset the count and
      #   reuse the latch.
      # @param count [Numeric] the new count
      # @raise [ArgumentError] if count is not a positive value
      # @raise [StandardError] if the count is not equal to zero
      def count=(count = 1)
        raise ArgumentError, "new count should be positive" if count < 0
        @lock.synchronize do
          raise "count should be 0 to reset the count" unless @count.zero?
          @count = count
        end
      end

      # Returns the count value
      #
      # @return [Numeric] the count value
      def count
        @lock.synchronize { @count }
      end

      # Block the current thread and wait for the latch to reach zero.
      def wait
        @lock.synchronize do
          @resource.wait(@lock) while @count > 0
        end
      end

      # Release the latch and decrement the count by one. When the count reaches
      # zero, the waiting threads are waken up.
      def release
        @lock.synchronize do
          @count -= 1 if @count > 0
          @resource.broadcast if @count.zero?
        end
      end
    end
  end
end
