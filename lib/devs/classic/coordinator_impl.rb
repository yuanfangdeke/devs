module DEVS
  module Classic
    module CoordinatorImpl

      # Handles events of init type (i messages)
      #
      # @param event [Event] the init event
      def handle_init_event(event)
        @children.each { |child| child.dispatch(event) }
        @scheduler.reschedule
        @time_last = max_time_last
        @time_next = min_time_next
        debug "#{model} set tl: #{@time_last}; tn: #{@time_next}"
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

        children = read_imminent_children
        children_models = children.map(&:model)
        child_model = model.select(children_models)
        debug "\tselected #{child_model} in #{children_models.map(&:name)}"
        child = children[children_models.index(child_model)]

        @scheduler.unschedule(child)
        child.dispatch(event)
        @scheduler.schedule(child)

        @time_last = event.time
        @time_next = min_time_next
        debug "#{model} time_last: #{@time_last} | time_next: #{@time_next}"
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
            debug "\t#{model} found external input coupling #{coupling}"
            child = coupling.destination.processor
            message = Message.new(payload, coupling.destination_port)
            @scheduler.unschedule(child)
            child.dispatch(Event.new(:input, event.time, [message]))
            @scheduler.schedule(child)
          end

          @time_last = event.time
          @time_next = min_time_next
          debug "#{model} time_last: #{@time_last} | time_next: #{@time_next}"
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
          debug "\t#{model} found external output coupling #{coupling}"
          message = Message.new(payload, coupling.destination_port)
          new_event = Event.new(:output, event.time, [message])
          debug "\tdispatching #{new_event}"
          parent.dispatch(new_event)
        end

        model.each_internal_coupling(port) do |coupling|
          debug "\t#{model} found internal coupling #{coupling}"
          message = Message.new(payload, coupling.destination_port)
          new_event = Event.new(:input, event.time, [message])
          debug "\tdispatching #{new_event}"
          coupling.destination.processor.dispatch(new_event)
        end
      end
    end
  end
end
