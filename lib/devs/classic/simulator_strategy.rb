module DEVS
  module Classic
    # This class represent a simulator associated with an {AtomicModel},
    # responsible to trigger its transitions and dispatch its events.
    module SimulatorStrategy
      include Logging

      # Handles events of init type (i messages)
      #
      # @param context [Simulator] the simulator
      # @param event [Event] the init event
      def handle_init_event(context, event)
        context.time_last = context.model.time = event.time
        context.time_next = context.time_last + context.model.time_advance
        info "    time_last: #{context.time_last} | time_next: #{context.time_next}"
      end

      # Handles input events (x messages)
      #
      # @param context [Simulator] the simulator
      # @param event [Event] the input event
      # @raise [BadSynchronisationError] if the event time isn't in a proper
      #   range, e.g isn't between {#time_last} and {#time_next}
      def handle_input_event(context, event)
        model = context.model
        if (context.time_last..context.time_next).include?(event.time)
          model.elapsed = event.time - context.time_last
          info "    received #{event.message}"
          model.add_input_message(event.message)
          model.external_transition
          context.time_last = model.time = event.time
          context.time_next = event.time + model.time_advance
          info "    time_last: #{context.time_last} | time_next: #{context.time_next}"
        else
          raise BadSynchronisationError, "time: #{event.time} should be " \
              + "between time_last: #{context.time_last} and time_next: #{context.time_next}"
        end
      end

      # Handles star events (* messages)
      #
      # @param context [Simulator] the simulator
      # @param event [Event] the star event
      # @raise [BadSynchronisationError] if the event time is not equal to
      #   {#time_next}
      def handle_star_event(context, event)
        if event.time != context.time_next
          raise BadSynchronisationError, "time: #{event.time} should match" \
              + "time_next: #{context.time_next}"
        end
        model = context.model

        model.fetch_output! do |message|
          info "    sent #{message}"
          context.parent.dispatch(Event.new(:y, event.time, message))
        end

        model.internal_transition

        context.time_last = model.time = event.time
        context.time_next = event.time + model.time_advance
        info "#{model} time_last: #{context.time_last} | time_next: #{context.time_next}"
      end
    end
  end
end
