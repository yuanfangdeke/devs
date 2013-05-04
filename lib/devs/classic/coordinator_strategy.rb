module DEVS
  module Classic
    module CoordinatorStrategy

      # Handles events of init type (i messages)
      #
      # @param event [Event] the init event
      def handle_init_event(event)
        @children.each { |child| child.dispatch(event) }
        @time_last = max_time_last
        @time_next = min_time_next
        info "#{model} set tl: #{@time_last}; tn: #{@time_next}"
      end

      # Handles star events (* messages)
      #
      # @param event [Event] the star event
      # @raise [BadSynchronisationError] if the event time is not equal to
      #   {Coordinator#time_next}
      def handle_star_event(event)
        if event.time != @time_next
          raise BadSynchronisationError,
                "time: #{event.time} should match time_next: #{@time_next}"
        end

        children = imminent_children
        children_models = children.map(&:model)
        child_model = model.select(children_models)
        info "    selected #{child_model} in #{children_models.map(&:name)}"
        child = children[children_models.index(child_model)]

        child.dispatch(event)

        @time_last = event.time
        @time_next = min_time_next
        info "#{model} time_last: #{@time_last} | time_next: #{@time_next}"
      end

      # Handles input events (x messages)
      #
      # @param event [Event] the input event
      # @raise [BadSynchronisationError] if the event time isn't in a proper
      #   range, e.g isn't between {Coordinator#time_last} and
      #   {Coordinator#time_next}
      def handle_input_event(event)
        if (@time_last..@time_next).include?(event.time)
          payload, port = *event.message

          model.each_input_coupling(port) do |coupling|
            info "    #{model} found external input coupling #{coupling}"
            child = coupling.destination.processor
            message = Message.new(payload, coupling.destination_port)
            child.dispatch(Event.new(:x, event.time, message))
          end

          @time_last = event.time
          @time_next = min_time_next
          info "#{model} time_last: #{@time_last} | time_next: #{@time_next}"
        else
          raise BadSynchronisationError, "time: #{event.time} should be " \
              + "between time_last: #{@time_last} and time_next: #{@time_next}"
        end
      end

      # Handles output events (y messages)
      #
      # @param event [Event] the output event
      def handle_output_event(event)
        payload, port = *event.message

        model.each_output_coupling(port) do |coupling|
          info "    found external output coupling #{coupling}"
          message = Message.new(payload, coupling.destination_port)
          new_event = Event.new(:y, event.time, message)
          info "    dispatching #{new_event}"
          parent.dispatch(new_event)
        end

        model.each_internal_coupling(port) do |coupling|
          info "    found internal coupling #{coupling}"
          message = Message.new(payload, coupling.destination_port)
          new_event = Event.new(:x, event.time, message)
          info "    dispatching #{new_event}"
          coupling.destination.processor.dispatch(new_event)
        end
      end
    end
  end
end
