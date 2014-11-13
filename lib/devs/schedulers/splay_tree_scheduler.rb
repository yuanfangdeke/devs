module DEVS
  class SplayTreeScheduler
    def initialize(elements = nil)
      @tree = SplayTree.new(elements)
    end

    def size
      @tree.size
    end

    def empty?
      @tree.empty?
    end

    def read
      return nil if @tree.size == 0
      @tree.find_min.time_next
    end

    def imminent(time)
      a = []
      a << @tree.pop while @tree.size > 0 && @tree.find_min.time_next == time
      a
    end

    def insert(processor)
      @tree << processor
    end

    def cancel(processor)
      @tree.delete(processor)
    end

    def reschedule!; end
  end
end
