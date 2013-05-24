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
          info "* Tick at: #{@time}, #{Time.now - @real_start_time} secs elapsed"
          child.dispatch(Event.new(:collect, @time))
          child.dispatch(Event.new(:internal, @time))
          @time = child.time_next
          break if @time >= @duration
        end
      end
    end
  end
end
