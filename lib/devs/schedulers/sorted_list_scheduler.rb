module DEVS
  class SortedListScheduler
    def initialize(elements = nil)
      if elements
        @ary = elements.dup
        reschedule!
      end
    end

    def size
      @ary.size
    end

    def empty?
      @ary.empty?
    end

    def read
      return nil if @ary.empty?
      @ary.last.time_next
    end

    def imminent(time)
      a = []
      a << @ary.pop while !@ary.empty? && @ary.last.time_next == time
      a
    end

    def read_imminent(time)
      ary = []
      i = @ary.size - 1

      while i >= 0
        elt = @ary[i]
        if elt.time_next == time
          ary << elt
          i -= 1
        else
          break
        end
      end

      ary
    end

    def insert(processor)
      @ary.push(processor)
      reschedule!
    end

    def cancel(processor)
      i = @ary.size - 1
      elmt = nil
      while i >= 0
        if @ary[i] == processor
          elmt = @ary.delete_at(i)
          break
        end
        i -= 1
      end
      elmt
    end

    def reschedule!
      @ary.sort! { |a,b| b.time_next <=> a.time_next }
      self
    end
  end
end
