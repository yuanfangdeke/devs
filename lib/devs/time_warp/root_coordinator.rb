module DEVS
  module TimeWarp
    class RootCoordinator < Classic::RootCoordinator
      def initialize(*args)
        super(*args)

        @input_events = []
        @output_events = []

        # the sent, not yet received output events
        @pending_output_events = []

        @time_last = 0
      end

      # @todo
      def dispatch(event)
        super(event)

        case event.type
        when :x then handle_input_event(event)
        when :y then handle_output_event(event)
        when :rollback then handle_rollback_event(event)
        end
      end

      def simulate
        @real_start_time = Time.now
        info "*** Beginning simulation at #{@real_start_time} with duration:" \
           + "#{duration}"

        child.dispatch(Event.new(:i, @time))
        @time_last = child.time_last
        #@time = child.time_next

        loop do
          info "* Tick at: #{@time}, #{Time.now - @real_start_time} secs elapsed"
          child.dispatch(Event.new(:'@', @time))
          child.dispatch(Event.new(:*, @time))
          @time = child.time_next
          break if @time >= @duration
        end

        msg = "*** Simulation ended after #{Time.now - @real_start_time} secs."
        DEVS.logger ? info(msg) : puts(msg)

        info "* Events stats :"
        stats = child.stats
        stats[:total] = stats.values.reduce(&:+)
        info "    OVERALL #{stats}"

        info "* Calling post simulation hooks"
        changed
        notify_observers(:post_simulation)
      end
    end

    protected

    def handle_input_event(event)

    end

    def handle_output_event(event)

    end

    def handle_rollback_event(event)

    end
  end
end
