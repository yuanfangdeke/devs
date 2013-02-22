module DEVS
  module Classic
    class Simulator < Processor
      def post_simulation_hook
        model.post_simulation_hook
      end

      protected
      def handle_init_event(event)
        @time_last = model.time = event.time
        @time_next = @time_last + model.time_advance
        info "    set tl: #{@time_last}; tn: #{@time_next}"
      end

      def handle_input_event(event)
        unless @time_last <= event.time && event.time <= @time_next
          raise BadSynchronisationError, "time: #{event.time} should be between\
 time_last: #{@time_last} and time_next: #{@time_next}"
        end
        model.elapsed = event.time - @time_last
        info "    received #{event.message.payload} on port \
#{event.message.port.name}"
        model.add_input_message(event.message)
        model.external_transition
        @time_last = model.time = event.time
        @time_next = event.time + model.time_advance
        info "    set tl: #{@time_last}; tn: #{@time_next}"
      end

      def handle_star_event(event)
        if event.time != @time_next
          raise BadSynchronisationError, "time: #{event.time} should match\
          time_next: #{@time_next}"
        end
        model.output
        model.output_messages.each do |message|
          info "    sent #{message.payload} on port #{message.port.name}"
          parent.dispatch(Event.new(:y, event.time, message))
        end
        model.internal_transition
        @time_last = model.time = event.time
        @time_next = event.time + model.time_advance
        info "#{self.model.name} set tl: #{@time_last}; tn: #{@time_next}"
      end
    end
  end
end
