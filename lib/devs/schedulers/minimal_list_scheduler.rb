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
      if processor.time_next == @min
        min = DEVS::INFINITY
        @ary.each { |p| min = p.time_next if p.time_next < min }
        @min = min
      end
    end

    def reschedule!
      min = DEVS::INFINITY
      @ary.each { |p| min = p.time_next if p.time_next < min }
      @min = min
    end

    def read
      @min
    end

    def imminent(time)
      a = []
      @ary.each { |p| a.push(p) if p.time_next == time }
      a
    end
    alias_method :read_imminent, :imminent
  end
end
