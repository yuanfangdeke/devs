module DEVS
  module Classic
    module CoordinatorImpl

      # Handles events of init type (i messages)
      #
      # @param event [Event] the init event
      def handle_init_event(event)
        @children.each { |child| child.dispatch(event) }
        @scheduler = DEVS.scheduler.new(@children.select{ |c| c.time_next < DEVS::INFINITY })
        @time_last = max_time_last
        @time_next = min_time_next
      end

      # Handles internal events (* messages)
      #
      # @param event [Event] the internal event
      # @raise [BadSynchronisationError] if the event time is not equal to
      #   {Coordinator#time_next}
      def handle_internal_event(event)
        if event.time != @time_next
          raise BadSynchronisationError,
                "time: #{event.time} should match time_next: #{@time_next}"
        end

        children = imminent_children

        child = if children.count > 1
          children_models = children.map(&:model)
          child_model = model.select(children_models)
          children[children_models.index(child_model)]
        else
          children.first
        end

        imminent_children.each { |c| @scheduler.schedule(c) unless c == child }
        child.dispatch(event)
        @scheduler.schedule(child)

        @time_last = event.time
        @time_next = min_time_next
      end

      # Handles input events (x messages)
      #
      # @param event [Event] the input event
      # @raise [BadSynchronisationError] if the event time isn't in a proper
      #   range, e.g isn't between {Coordinator#time_last} and
      #   {Coordinator#time_next}
      def handle_input_event(event)
        if (@time_last..@time_next).include?(event.time)
          payload, port = *event.bag.first

          model.each_input_coupling(port) do |coupling|
            child = coupling.destination.processor
            message = Message.new(payload, coupling.destination_port)
            @scheduler.cancel(child)
            child.dispatch(Event.new(:input, event.time, [message]))
            @scheduler.insert(child)
          end

          @time_last = event.time
          @time_next = min_time_next
        else
          raise BadSynchronisationError, "time: #{event.time} should be between time_last: #{@time_last} and time_next: #{@time_next}"
        end
      end

      # Handles output events (y messages)
      #
      # @param event [Event] the output event
      def handle_output_event(event)
        payload, port = *event.bag.first

        model.each_output_coupling(port) do |coupling|
          message = Message.new(payload, coupling.destination_port)
          new_event = Event.new(:output, event.time, [message])
          parent.dispatch(new_event)
        end

        model.each_internal_coupling(port) do |coupling|
          message = Message.new(payload, coupling.destination_port)
          new_event = Event.new(:input, event.time, [message])
          child = coupling.destination.processor
          @scheduler.cancel(child)
          child.dispatch(new_event)
          @scheduler.insert(child)
        end
      end
    end
  end
end
