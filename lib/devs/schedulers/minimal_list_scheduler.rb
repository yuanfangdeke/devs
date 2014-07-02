module DEVS
  class MinimalListScheduler
    def initialize(elements = nil)
      @ary = elements.dup if elements
      @min = DEVS::INFINITY
      reschedule!
    end

    def schedule(processor)
      @ary << processor
      @min = processor.time_next if @min > processor.time_next
    end

    def unschedule(processor)
      @ary.delete(processor)
      search_min! if processor.time_next == @min
    end

    def reschedule!
      min = DEVS::INFINITY
      i = 0
      while i < @ary.size
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
        a << @ary.delete_at(i) if p.time_next == time
        i += 1
      end
      a
    end
  end
end
