module DEVS
  module Classic
    module SimulatorImpl
      # Handles events of init type (i messages)
      #
      # @param event [Event] the init event
      def handle_init_event(event)
        @time_last = model.time = event.time
        @time_next = @time_last + model.time_advance
        debug "\t#{model} initialization (time_last: #{@time_last}, time_next: #{@time_next})" if DEVS.logger
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

        bag = model.fetch_output!
        i = 0
        while i < bag.size
          parent.dispatch(Event.new(:output), event.time, [bag[i]])
          i += 1
        end

        debug "\tinternal transition: #{model}" if DEVS.logger
        model.internal_transition

        @time_last = model.time = event.time
        @time_next = event.time + model.time_advance
        debug "\t\ttime_last: #{@time_last} | time_next: #{@time_next}" if DEVS.logger
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
          debug "\texternal transition: #{model}" if DEVS.logger
          bag = event.bag.map { |msg| ensure_input_message(msg).freeze }
          model.external_transition(bag)
          @time_last = model.time = event.time
          @time_next = event.time + model.time_advance
          debug "\t\ttime_last: #{@time_last} | time_next: #{@time_next}" if DEVS.logger
        else
          raise BadSynchronisationError, "time: #{event.time} should be between time_last: #{@time_last} and time_next: #{@time_next}"
        end
      end
    end
  end
end
