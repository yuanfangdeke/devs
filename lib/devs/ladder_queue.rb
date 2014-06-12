module DEVS
  # Multilist-based priority queue structure which achieve O(1) performance,
  # especially designed for managing the pending event set in discrete event
  # simulation. Its name, <i>LadderQueue</i>, arises from the semblance of the
  # structure to a ladder with rungs.
  #
  # Basically, the structure consists of three tiers: a sorted list called
  # <i>Bottom</i>; the middle layer, called <i>Ladder</i>, consisting of several
  # rungs of buckets where each bucket may contain an unsorted list; and a simple
  # unsorted list called <i>Top</i>.
  class LadderQueue

    # This class represent a general error for the {LadderQueue}.
    class LadderQueueError < StandardError; end

    # This class represent an error raised if the number of {Rung}s in
    # <i>Ladder</i> is equal to {#max_rungs} when an attempt to add a new rung
    # is made.
    class RungOverflowError < LadderQueueError; end

    # This class represent an error raised when an attempt to reset an active
    # {Rung} is made.
    class RungInUseError < LadderQueueError; end

    # This class represent a rung used in the <i>Ladder</i> tier of a
    # {LadderQueue}.
    #
    # Consist of buckets where each bucket may contain an unsorted list.
    class Rung
      attr_accessor :current, :current_bucket, :start, :total_event_count
      attr_reader   :bucket_count, :bucket_width

      # @!attribute [rw] start
      #   Starting timestamp threshold of the first bucket. Used for calculating
      #   the bucket-index when inserting an event.

      # @!attribute [rw] current
      #   Starting timestamp threshold of the first valid bucket which subsequent
      #   dequeue operations will start. Minimum timestamp threshold of events
      #   which can be enqueued.

      # @!attribute [r] bucket_count
      #   This attribute returns the number of buckets in <i>self</i>.
      #   @return [Fixnum] Returns the number of buckets in <i>self</i>

      def initialize
        @buckets = nil

        @start = 0
        @current = 0
        @current_bucket = 0
        @bucket_width = 0
        @total_event_count = 0
      end

      def inspect
        "<#{self.class}: start=#{@start}, current=#{@current}>, current_bucket=#{@current_bucket}, bucket_width=#{@bucket_width}, buckets=#{@buckets ? @buckets.map(&:size) : 'nil'}>"
      end

      def event_count(index)
        @buckets[index].size
      end

      def bucket_count
        @buckets.size
      end

      def clear
        @buckets.clear
        @start = 0
        @current = 0
        @current_bucket = 0
        @bucket_width = 0
        @total_event_count = 0
      end

      def [](index)
        @buckets[index]
      end

      def clear_bucket_at(index)
        bucket = @buckets[index]
        events = bucket.dup
        @total_event_count -= bucket.size
        bucket.clear
        events
      end

      def reset(bucket_width, bucket_count)
        raise RungInUseError unless @total_event_count.zero?

        @bucket_width = bucket_width
        @buckets = Array.new(bucket_count) { [] }
        @total_event_count = 0
        @current_bucket = 0
        @start = 0
        @current = 0
      end

      def delete(obj)
        item = bucket_for(obj).delete(obj)
        @total_event_count -= 1 if item
        item
      end

      def push(obj)
        bucket_for(obj).push(obj)
        @total_event_count += 1
      end

      def concat(list)
        list.each { |obj| push(obj) }
      end

      private
      def bucket_for(obj)
        index = if @bucket_width.zero?
          0
        else
          (obj.time_next - @start) / @bucket_width
        end

        if obj.time_next == Float::INFINITY
          @buckets.last
        else
          @buckets[index]
        end
      end
    end

    # The default number of events in a bucket or bottom to not exceed. If so,
    # a spawning action would be initiated.
    DEFAULT_THRESHOLD = 50

    # The default max number of rungs in the middle layer
    DEFAULT_MAX_RUNGS = 8

    attr_reader :top_size, :bottom_size, :active_rungs, :size, :threshold,
                :max_rungs, :top_max, :top_min, :top_start

    # @!attribute [r] top_size
    #   This attribute returns the number of events in <i>Top</i>
    #   @return [Fixnum] Returns the number of events in <i>Top</i>

    # @!attribute [r] bottom_size
    #   This attribute returns the number of events in <i>Bottom</i>
    #   @return [Fixnum] Returns the number of events in <i>Bottom</i>

    # @!attribute [r] active_rungs
    #   This attribute returns the number of rungs currently in active use
    #   @return [Fixnum] Returns the number of active rungs

    # @!attribute [r] size
    #   This attribute returns the total number of events in <i>self</i>.
    #   @return [Fixnum] Returns the total number of events

    # @!attribute [r] threshold
    #   This attribute returns the number of events in a bucket or bottom to not
    #   exceed. If so, a spawning action would be initiated.
    #   @return [Fixnum] Returns the number of events threshold

    # @!attribute [r] top_min
    #   This attribute returns the minimum timestamp of all events in <i>Top</i>.
    #   Its value is updated as events are enqueued into <i>Top</i>.
    #   @return [Fixnum] Returns the minimum timestamp in <i>Top</i>

    # @!attribute [r] top_max
    #   This attribute returns the maximum timestamp of all events in <i>Top</i>.
    #   Its value is updated as events are enqueued into <i>Top</i>.
    #   @return [Fixnum] Returns the maximum timestamp in <i>Top</i>

    # @!attribute [r] top_start
    #   This attribute returns the minimum timestamp threshold of events which
    #   must be enqueued in <i>Top</i>
    #   @return [Fixnum] Returns the minimum timestamp threshold of events which
    #     must be enqueued in <i>Top</i>

    # @!attribute [r] max_rungs
    #   This attribute returns the maximum number of rungs that can be spawned.
    #   @return [Fixnum] Returns the maximum number of rungs in <i>self</i>

    def initialize(elements = nil, threshold = DEFAULT_THRESHOLD, max_rungs = DEFAULT_MAX_RUNGS)
      @threshold = threshold
      @max_rungs = max_rungs
      @active_rungs = 0
      @size = 0

      # Sorted list
      @top = []
      # The middle layer (ladder) consisting of several rungs of buckets where
      # each bucket may contain an unsorted list
      @rungs = Array.new(max_rungs) { Rung.new }
      # Unsorted list
      @bottom = []

      # Maximum timestamp of all events in top. Its value is updated as events are
      # enqueued into top
      @top_max = 0
      # Minimum timestamp of all events in top. Its value is updated as events are
      # enqueued into top
      @top_min = Float::INFINITY
      # Minimum timestamp threshold of events which must be enqueued in top
      @top_start = 0

      push(*elements) if elements
    end

    def inspect
      "<#{self.class}: size=#{@size}, top=#{@top.size}, bottom=#{@bottom.size}>, rungs=#{@rungs}, active_rungs=#{@active_rungs}}, threshold=#{@threshold}, max_rungs=#{@max_rungs}, top_start=#{@top_start}, top_min=#{@top_min}, top_max=#{@top_max}"
    end

    def top_size
      @top.size
    end

    def bottom_size
      @bottom.size
    end

    def ladder_size
      @size - (@top.size + @bottom.size)
    end

    def size
      @size
    end

    def push(*args)
      args.each do |obj|
        timestamp = obj.time_next

        if timestamp >= @top_start
          @top.push(obj)
          @top_min = timestamp if timestamp < @top_min
          @top_max = timestamp if timestamp > @top_max
        else
          # check whether event should be in ladder or bottom
          active_rungs = @active_rungs
          x = 0
          while timestamp < @rungs[x].current && x < active_rungs
            x += 1
          end

          if x < active_rungs
            @rungs[x].push(obj)
          else
            if @bottom.size > @threshold
              rung = add_rung(@bottom.size)
              @bottom.push(obj)
              rung.concat(@bottom)
              @bottom.clear
            else
              push_bottom(obj)
            end
          end
        end

        @size += 1
      end
      self
    end

    def delete(obj)
      timestamp = obj.time_next
      item = nil

      if timestamp >= @top_start && !@top.empty?
        item = @top.delete(obj)
      else
        active_rungs = @active_rungs
        x = 0
        while timestamp < @rungs[x].current && x < active_rungs
          x += 1
        end

        item = @rungs[x].delete(obj) if x < active_rungs
        item = @bottom.delete(obj) unless item
      end

      @size -= 1 if item
      item
    end

    def peek
      prepare!
      @bottom.first
    end

    def pop
      prepare!
      # return next event from bottom
      @size -= 1
      @bottom.shift
    end

    def clear
      @top.clear
      @bottom.clear
      @rungs.clear

      @active_rungs = 0
      @size = 0
    end

    private
    def prepare!
      while @bottom.empty?
        if @active_rungs > 0
          rung = @rungs[@active_rungs - 1]
          bucket = rung[recurse_rungs]

          # sort bucket into bottom
          bucket.each { |obj| push_bottom(obj) }
          # update counts
          rung.total_event_count -= bucket.size
          bucket.clear

          # invalidate rung if empty
          while @active_rungs > 0 && rung.total_event_count <= 0
            @active_rungs -= 1
            rung = @rungs[@active_rungs - 1]
          end
        else
          break if @top.size.zero?

          if @top_max == @top_min
            # no sort required
            @bottom.concat(@top)
            @top.clear
            @top_start = 0
          else
            rung = @rungs.first
            max = @top_max == Float::INFINITY ? Float::MAX : @top_max
            rung.reset((max - @top_min) / @top.size, @top.size + 1)
            rung.start = rung.current = @top_min
            @top_start = max
            @active_rungs = 1
            rung.concat(@top)
            @top.clear
            @top_max = 0
            @top_min = Float::INFINITY
          end
        end
      end

      self
    end

    def push_bottom(obj)
      if @bottom.empty?
        @bottom.push(obj)
      else
        index = 0
        max = @bottom.size - 1
        item = @bottom[index]

        while item.time_next < obj.time_next
          break if index == max
          index += 1
          item = @bottom[index]
        end

        if item.time_next < obj.time_next && index == max
          @bottom.push(obj)
        else
          @bottom.insert(index, obj)
        end
      end
    end

    def recurse_rungs
      lowest = @rungs[@active_rungs - 1]
      found = false

      # until an acceptable bucket is found
      until found
        # find next non-empty bucket from lowest rung
        while lowest.event_count(lowest.current_bucket).zero?
          lowest.current_bucket += 1
          lowest.current += lowest.bucket_width

          if lowest.current_bucket >= lowest.bucket_count
           @active_rungs -= 1
           raise LadderQueueError, 'Empty rung' if @active_rungs <= 0
           lowest = @rungs[@active_rungs - 1]
          end
        end

        # create a new rung if bucket gets too big
        event_count = lowest.event_count(lowest.current_bucket)
        if event_count > @threshold
          rung = add_rung(event_count)

          events = lowest.clear_bucket_at(lowest.current_bucket)
          rung.concat(events)

          lowest = rung
        else
          found = true
        end
      end

      lowest.current_bucket
    end

    def add_rung(n)
      raise RungOverflowError if @active_rungs == @max_rungs
      current = @rungs[@active_rungs-1]
      rung = @rungs[@active_rungs]
      width = current.bucket_width / n

      # set bucket width to current rung's bucket width / thres
      rung.reset(width, n+1)
      # set start and current of the new rung to current marking of the current bucket
      rung.start = rung.current = current.current

      @active_rungs += 1
      rung
    end
  end
end
