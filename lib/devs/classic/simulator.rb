module DEVS
  module Classic
    class Simulator < Processor
      protected

      def handle_init_event(event)
        @time_last = model.time = event.time
        @time_next = @time_last + model.time_advance
        info "    time_last: #{@time_last} | time_next: #{@time_next}"
      end

      def handle_input_event(event)
        if (@time_last..@time_next).include?(event.time)
          model.elapsed = event.time - @time_last
          info "    received #{event.message}"
          model.add_input_message(event.message)
          model.external_transition
          @time_last = model.time = event.time
          @time_next = event.time + model.time_advance
          info "    time_last: #{@time_last} | time_next: #{@time_next}"
        else
          raise BadSynchronisationError, "time: #{event.time} should be " \
              + "between time_last: #{@time_last} and time_next: #{@time_next}"
        end
      end

      def handle_star_event(event)
        if event.time != @time_next
          raise BadSynchronisationError, "time: #{event.time} should match" \
              + "time_next: #{@time_next}"
        end

        model.fetch_output! do |message|
          info "    sent #{message}"
          parent.dispatch(Event.new(:y, event.time, message))
        end

        model.internal_transition

        @time_last = model.time = event.time
        @time_next = event.time + model.time_advance
        info "#{self.model} time_last: #{@time_last} | time_next: #{@time_next}"
      end
    end
  end
end
