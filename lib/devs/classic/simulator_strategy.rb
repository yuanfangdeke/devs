module DEVS
  module Classic
    # This class represent a simulator associated with an {AtomicModel},
    # responsible to trigger its transitions and dispatch its events.
    module SimulatorStrategy
      # Handles events of init type (i messages)
      #
      # @param event [Event] the init event
      def handle_init_event(event)
        @time_last = model.time = event.time
        @time_next = @time_last + model.time_advance
        info "    time_last: #{@time_last} | time_next: #{@time_next}"
      end

      # Handles input events (x messages)
      #
      # @param event [Event] the input event
      # @raise [BadSynchronisationError] if the event time isn't in a proper
      #   range, e.g isn't between {Simulator#time_last} and {Simulator#time_next}
      def handle_input_event(event)
        if (@time_last..@time_next).include?(event.time)
          model.elapsed = event.time - @time_last
          info "    received #{event.message}"
          model.external_transition(ensure_input_message(event.message).freeze)
          @time_last = model.time = event.time
          @time_next = event.time + model.time_advance
          info "    time_last: #{@time_last} | time_next: #{@time_next}"
        else
          raise BadSynchronisationError, "time: #{event.time} should be " \
              + "between time_last: #{@time_last} and time_next: #{@time_next}"
        end
      end

      # Handles star events (* messages)
      #
      # @param event [Event] the star event
      # @raise [BadSynchronisationError] if the event time is not equal to
      #   {Simulator#time_next}
      def handle_star_event(event)
        if event.time != @time_next
          raise BadSynchronisationError, "time: #{event.time} should match" \
              + "time_next: #{@time_next}"
        end

        model.fetch_output! do |message|
          info "    sent #{message}"
          parent.dispatch(Event.new(:output, event.time, message))
        end

        model.internal_transition

        @time_last = model.time = event.time
        @time_next = event.time + model.time_advance
        info "#{model} time_last: #{@time_last} | time_next: #{@time_next}"
      end
    end
  end
end
