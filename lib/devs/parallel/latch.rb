module DEVS
  class Latch
    def initialize(count = 1)
      raise ArgumentError, "count should be positive" if count < 0
      @count = count
      @lock = Mutex.new
      @resource = ConditionVariable.new
    end

    def count=(count = 1)
      raise ArgumentError, "new count should be positive" if count < 0
      @lock.synchronize do
        raise "count should be 0 to reset the count" unless @count.zero?
        @count = count
      end
    end

    def count
      @lock.synchronize { @count }
    end

    def wait
      @lock.synchronize do
        @resource.wait(@lock) while @count > 0
      end
    end

    def release
      @lock.synchronize do
        @count -= 1 if @count > 0
        @resource.broadcast if @count.zero?
      end
    end
  end
end
