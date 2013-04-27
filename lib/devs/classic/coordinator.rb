module DEVS
  module Classic
    # This class represent a simulator associated with an {CoupledModel},
    # responsible to route events to proper children
    class Coordinator < Processor
      attr_reader :children

      # @!attribute [r] children
      #   This attribute returns a list of all its child {Processor}s, composed
      #   of {Simulator}s or/and {Coordinator}s.
      #   @return [Array<Processor>] Returns a list of all its child processors

      # Returns a new instance of {Coordinator}
      #
      # @param model [CoupledModel] the managed coupled model
      def initialize(model)
        super(model)
        @children = []
      end

      def stats
        super
        hsh = Hash.new(0)
        hsh.update(@events_count)
        children.each do |child|
          child.stats.each { |key, value| hsh[key] += value }
        end
        hsh
      end

      # Append a child to {#children} list, ensuring that the child now has
      # self as parent.
      def <<(child)
        unless @children.include?(child)
          @children << child
          child.parent = self
        end
        child
      end
      alias_method :add_child, :<<

      protected

      # Handles events of init type (i messages)
      #
      # @param event [Event] the init event
      def handle_init_event(event)
        @children.each { |child| child.dispatch(event) }
        @time_last = max_time_last
        @time_next = min_time_next
        info "#{self.model} set tl: #{@time_last}; tn: #{@time_next}"
      end

      # Handles star events (* messages)
      #
      # @param event [Event] the star event
      # @raise [BadSynchronisationError] if the event time is not equal to
      #   {#time_next}
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
        info "#{self.model} time_last: #{@time_last} | time_next: #{@time_next}"
      end

      # Handles input events (x messages)
      #
      # @param event [Event] the input event
      # @raise [BadSynchronisationError] if the event time isn't in a proper
      #   range, e.g isn't between {#time_last} and {#time_next}
      def handle_input_event(event)
        if (@time_last..@time_next).include?(event.time)
          payload, port = *event.message

          model.each_input_coupling(port) do |coupling|
            info "    #{self.model} found external input coupling #{coupling}"
            child = coupling.destination.processor
            message = Message.new(payload, coupling.destination_port)
            child.dispatch(Event.new(:x, event.time, message))
          end

          @time_last = event.time
          @time_next = min_time_next
          info "#{self.model} time_last: #{@time_last} | time_next: #{@time_next}"
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

      # Returns the minimum time next in all children
      #
      # @return [Numeric] the min time next
      def min_time_next
        @children.map { |child| child.time_next }.min
      end

      # Returns the maximum time last in all children
      #
      # @return [Numeric] the max time last
      def max_time_last
        @children.map { |child| child.time_last }.max
      end

      # Returns a subset of {#children} including imminent children, e.g with
      # a time next value matching {#time_next}.
      #
      # @return [Array<Model>] the imminent children
      def imminent_children
        @children.select { |child| child.time_next == time_next }
      end
    end
  end
end
