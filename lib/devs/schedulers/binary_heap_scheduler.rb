module DEVS
  # Scheduler with array based heap.
  #
  # Each inserted elements is given a certain priority, based on the result of
  # the comparison. Also, retrieving an element will always return the one with
  # the highest priority. The internal queue is kept in the reverse order.
  #
  class BinaryHeapScheduler
    def initialize(elements = nil)
      @que = []
      replace(elements) if elements
    end

    protected
    attr_reader :que

    public

    def size
      @que.size
    end

    def schedule(processor)
      @que << processor
      reheap(@que.size - 1)
      self
    end

    def reschedule(processor)
      idx = index(processor)
      reheap(idx) unless idx.nil?
      self
    end

    def index(processor)
      idx = nil
      i = @que.size - 1
      while i >= 0
        if @que[i] == processor
          idx = i
          break
        end
        i -= 1
      end
      idx
    end
    private :index

    def unschedule(processor)
      i = @que.size - 1
      elmt = nil
      while i >= 0
        if @que[i] == processor
          elmt = @que.delete_at(i)
          break
        end
        i -= 1
      end
      elmt
    end

    def read
      return nil if empty?
      @que.last.time_next
    end

    def imminent(time)
      a = []
      a << @que.pop while !@que.empty? && @que.last.time_next == time
      a
    end

    def read_imminent(time)
      ary = []
      i = @que.size - 1

      while i >= 0
        elt = @que[i]
        if elt.time_next == time
          ary << elt
          i -= 1
        else
          break
        end
      end

      ary
    end

    def empty?
      @que.empty?
    end

    def to_a
      @que.dup
    end

    def reschedule!
      @que.sort! { |a,b| b.time_next <=> a.time_next }
      self
    end

    def concat(elements)
      if empty?
        if elements.kind_of?(BinaryHeapScheduler)
          initialize_copy(elements)
        else
          replace(elements)
        end
      else
        if elements.kind_of?(BinaryHeapScheduler)
          @que.concat(elements.que)
          reschedule!
        else
          @que.concat(elements.to_a)
          reschedule!
        end
      end
      return self
    end

    def replace(elements)
      if elements.kind_of?(BinaryHeapScheduler)
        initialize_copy(elements)
      else
        @que.replace(elements.to_a)
        reschedule!
      end
      self
    end

    def inspect
      "<#{self.class}: size=#{size}, top=#{top || "nil"}>"
    end

    def ==(other)
      size == other.size && to_a == other.to_a
    end

    private

    def initialize_copy(other)
      @que  = other.que.dup
      reschedule!
    end

    def reheap(k)
      return self if size <= 1

      que = @que.dup

      v = que.delete_at(k)
      i = binary_index(que, v)

      que.insert(i, v)

      @que = que

      return self
    end

    def binary_index(que, target)
      upper = que.size - 1
      lower = 0

      while(upper >= lower) do
        idx  = lower + (upper - lower) / 2
        comp = que[idx].time_next <=> target.time_next

        case comp
        when 0, nil
          return idx
        when 1, true
          lower = idx + 1
        when -1, false
          upper = idx - 1
        else
        end
      end
      lower
    end
  end
end
