class PQueue
  def delete(v)
    idx = @que.index(v)
    unless idx.nil?
      @que.delete_at(idx)
    end
    self
  end

  def read_while
    return nil unless block_given? || empty?
    ary = []
    i = @que.size - 1

    loop do
      if yield(@que[i])
        ary << @que[i]
        i -= 1
      else
        break
      end
      break if i.zero?
    end

    ary
  end
end

module DEVS
  class Scheduler
    def initialize(children = nil)
      @pq = PQueue.new(children) { |a, b| a.time_next > b.time_next }
    end

    def schedule(model)
      @pq << model
    end

    def unschedule(model)
      @pq.delete(model)
    end

    def read
      top = @pq.top
      top.time_next if top
    end

    def reschedule
      @pq.send :sort!
    end

    def read_imminent(time)
      @pq.take_while { |m| m.time_next == time }
    end

    def imminent_children(time)
      children = []
      children << @pq.pop while @pq.top.time_next == time
      children
    end
  end
end
