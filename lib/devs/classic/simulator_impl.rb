module DEVS
  module Classic
    module SimulatorImpl
      # Handles events of init type (i messages)
      #
      # @param event [Event] the init event
      def handle_init_event(event)
        @time_last = model.time = event.time
        @time_next = @time_last + model.time_advance
        debug "\t\ttime_last: #{@time_last} | time_next: #{@time_next}"
      end

      # Handles internal events (* messages)
      #
      # @param event [Event] the internal event
      # @raise [BadSynchronisationError] if the event time is not equal to
      #   {Coordinator#time_next}
      def handle_internal_event(event)
        if event.time != @time_next
          raise BadSynchronisationError, "time: #{event.time} should match time_next: #{@time_next}"
        end

        model.fetch_output! do |message|
          debug "\t\tsent #{message}"
          parent.dispatch(Event.new(:output, event.time, [message]))
        end

        model.internal_transition

        @time_last = model.time = event.time
        @time_next = event.time + model.time_advance
        debug "\t\t#{model} time_last: #{@time_last} | time_next: #{@time_next}"
      end

      # Handles input events (x messages)
      #
      # @param event [Event] the input event
      # @raise [BadSynchronisationError] if the event time isn't in a proper
      #   range, e.g isn't between {Coordinator#time_last} and
      #   {Coordinator#time_next}
      def handle_input_event(event)
        if (@time_last..@time_next).include?(event.time)
          model.elapsed = event.time - @time_last
          debug "\t\t#{model} external transition"
          bag = event.bag.map { |msg| ensure_input_message(msg).freeze }
          model.external_transition(bag)
          @time_last = model.time = event.time
          @time_next = event.time + model.time_advance
          debug "\t\ttime_last: #{@time_last} | time_next: #{@time_next}"
        else
          raise BadSynchronisationError, "time: #{event.time} should be between time_last: #{@time_last} and time_next: #{@time_next}"
        end
      end
    end
  end
end
