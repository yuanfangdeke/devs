module DEVS
  module CoordinatorStrategy
    include Logging

    # Handles events of init type (i messages)
    #
    # @param context [Coordinator] the coordinator
    # @param event [Event] the init event
    def handle_init_event(context, event)
      context.children.each { |child| child.dispatch(event) }
      context.time_last = context.max_time_last
      context.time_next = context.min_time_next
      info "#{context.model} set tl: #{context.time_last}; tn: #{context.time_next}"
    end

    # Handles star events (* messages)
    #
    # @param context [Coordinator] the coordinator
    # @param event [Event] the star event
    # @raise [BadSynchronisationError] if the event time is not equal to
    #   {#time_next}
    def handle_star_event(context, event)
      if event.time != context.time_next
        raise BadSynchronisationError,
              "time: #{event.time} should match time_next: #{context.time_next}"
      end

      children = context.imminent_children
      children_models = children.map(&:model)
      child_model = context.model.select(children_models)
      info "    selected #{child_model} in #{children_models.map(&:name)}"
      child = context.children[children_models.index(child_model)]

      child.dispatch(event)

      context.time_last = event.time
      context.time_next = context.min_time_next
      info "#{context.model} time_last: #{context.time_last} | time_next: #{context.time_next}"
    end

    # Handles input events (x messages)
    #
    # @param context [Coordinator] the coordinator
    # @param event [Event] the input event
    # @raise [BadSynchronisationError] if the event time isn't in a proper
    #   range, e.g isn't between {#time_last} and {#time_next}
    def handle_input_event(context, event)
      if (context.time_last..context.time_next).include?(event.time)
        payload, port = *event.message

        context.model.each_input_coupling(port) do |coupling|
          info "    #{context.model} found external input coupling #{coupling}"
          child = coupling.destination.processor
          message = Message.new(payload, coupling.destination_port)
          child.dispatch(Event.new(:x, event.time, message))
        end

        context.time_last = event.time
        context.time_next = context.min_time_next
        info "#{context.model} time_last: #{context.time_last} | time_next: #{context.time_next}"
      else
        raise BadSynchronisationError, "time: #{event.time} should be " \
            + "between time_last: #{context.time_last} and time_next: #{context.time_next}"
      end
    end

    # Handles output events (y messages)
    #
    # @param context [Coordinator] the coordinator
    # @param event [Event] the output event
    def handle_output_event(context, event)
      payload, port = *event.message

      context.model.each_output_coupling(port) do |coupling|
        info "    found external output coupling #{coupling}"
        message = Message.new(payload, coupling.destination_port)
        new_event = Event.new(:y, event.time, message)
        info "    dispatching #{new_event}"
        context.parent.dispatch(new_event)
      end

      context.model.each_internal_coupling(port) do |coupling|
        info "    found internal coupling #{coupling}"
        message = Message.new(payload, coupling.destination_port)
        new_event = Event.new(:x, event.time, message)
        info "    dispatching #{new_event}"
        coupling.destination.processor.dispatch(new_event)
      end
    end
  end
end
