module DEVS
  module TimeWarp
    module RootCoordinatorStrategy
      def after_initialize
        # queue to store input events
        @input_events = PQueue.new
        # queue to store output events
        @output_events = PQueue.new

        # the sent, not yet received output events
        @pending_output_events = PQueue.new

        @time_last = 0
      end

      def run
        child.dispatch(Event.new(:init, @time))
        @time_last = child.time_last

        loop do
          debug "* Tick at: #{@time}, #{Time.now - @real_start_time} secs elapsed"
          input_event = @input_events.pop

          if input_event.time <= child.time_next
            @time = input_event.time
            child.dispatch(Event.new(:input, @time))
          else
            @time = child.time_next
            child.dispatch(Event.new(:internal, @time))
          end

          @time_last = child.time_last

          # global virtual time
          gvt = [child.min_time_last, @pending_output_events.top.time].min
          child.fossil_collection(gvt)

          break if @time >= @duration
        end
      end

      def handle_output_event(event)
        @output_events << event
        # send request to put (y, t) into global pending IOq
        super(event)
      end

      def handle_input_event(event)
        # send request to remove output (y, t) correlating to input event (x, t)
        #   from pending IOq
        @input_events << event

        # rollback
        child.dispatch(Event.new(:rollback, event.time)) if @time_last < child.time_next

        events = output_ahead(event.time)
        # todo to influenced processors (neighbors ?)
        events.each { |ev| child.dispatch(Event.new(:anti_output, ev.time)) }
      end

      def handle_anti_input(event)
        # rollback
        child.dispatch(Event.new(:rollback, event.time)) if event.time < child.time_next

        events = output_ahead(event.time)
        # todo to influenced processors (neighbors ?)
        events.each { |ev| child.dispatch(Event.new(:anti_output, ev.time)) }

        @input_events.delete(event)
      end

      protected

      def output_ahead(time)
        @output_events.pop_while { |event| event.time > time }
      end
    end
  end
end
