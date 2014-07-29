module DEVS
  module Classic
    module CoordinatorImpl

      # Handles events of init type (i messages)
      #
      # @param event [Event] the init event
      def handle_init_event(event)
        i = 0
        selected = []
        min = DEVS::INFINITY
        while i < @children.size
          child = @children[i]
          child.dispatch(event)
          tn = child.time_next
          selected.push(child) if tn < DEVS::INFINITY
          min = tn if tn < min
          i += 1
        end
        @scheduler = if DEVS.scheduler == MinimalListScheduler
          DEVS.scheduler.new(@children)
        else
          DEVS.scheduler.new(selected)
        end

        @time_last = max_time_last
        @time_next = min
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

        imm = if DEVS.scheduler == MinimalListScheduler
          read_imminent_children
        else
          imminent_children
        end

        child = if imm.size > 1
          children_models = imm.map(&:model)
          child_model = model.select(children_models)
          imm[children_models.index(child_model)]
        else
          imm.first
        end

        if DEVS.scheduler == MinimalListScheduler
          child.dispatch(event)
          @scheduler.reschedule!
        else
          i = 0
          while i < imm.size
            c = imm[i]
            @scheduler.insert(c) unless c == child
            i += 1
          end
          child.dispatch(event)
          @scheduler.insert(child) if child.time_next < DEVS::INFINITY
        end

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
        if @time_last <= event.time && event.time <= @time_next
          msg = event.bag
          payload = msg.payload
          port = msg.port

          eic = @model.input_couplings(port)
          i = 0
          while i < eic.size
            coupling = eic[i]
            child = coupling.destination.processor
            message = Message.new(payload, coupling.destination_port)
            new_event = Event.new(:input, event.time, message)
            if DEVS.scheduler == MinimalListScheduler
              child.dispatch(new_event)
              @scheduler.reschedule!
            else
              @scheduler.cancel(child) if child.time_next < DEVS::INFINITY
              child.dispatch(new_event)
              @scheduler.insert(child) if child.time_next < DEVS::INFINITY
            end
            i += 1
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
        msg = event.bag
        payload = msg.payload
        port = msg.port

        eoc = @model.output_couplings(port)
        i = 0
        while i < eoc.size
          coupling = eoc[i]
          message = Message.new(payload, coupling.destination_port)
          new_event = Event.new(:output, event.time, message)
          parent.dispatch(new_event)
          i += 1
        end

        ic = @model.internal_couplings(port)
        i = 0
        while i < ic.size
          coupling = ic[i]
          message = Message.new(payload, coupling.destination_port)
          new_event = Event.new(:input, event.time, message)
          child = coupling.destination.processor
          if DEVS.scheduler == MinimalListScheduler
            child.dispatch(new_event)
          else
            @scheduler.cancel(child) if child.time_next < DEVS::INFINITY
            child.dispatch(new_event)
            @scheduler.insert(child) if child.time_next < DEVS::INFINITY
          end
          i += 1
        end
      end
    end
  end
end
