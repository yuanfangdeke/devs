module DEVS
  class MinimalListScheduler
    def initialize(elements = nil)
      @ary = elements.dup || []
      @min = DEVS::INFINITY
      reschedule!
    end

    def insert(processor)
      @ary << processor
      @min = processor.time_next if processor.time_next < @min
    end

    def cancel(processor)
      index = @ary.index(processor)
      unless index.nil?
        @ary.delete_at(index)
        reschedule! if processor.time_next == @min
      end
    end

    def reschedule!
      min = DEVS::INFINITY
      i = 0
      while i < @ary.size && min > 0
        p = @ary[i]
        min = p.time_next if p.time_next < min
        i += 1
      end
      @min = min
    end

    def read
      @min
    end

    def read_imminent(time)
      a = []
      i = 0
      while i < @ary.size
        p = @ary[i]
        a << p if p.time_next == time
        i += 1
      end
      a
    end

    def imminent(time)
      a = []
      i = 0
      while i < @ary.size
        p = @ary[i]
        a << (@ary.delete_at(i)) if p.time_next == time
        i += 1
      end
      a
    end
  end
end
