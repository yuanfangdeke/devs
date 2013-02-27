module DEVS
  module Classic
    class Coordinator < Processor
      attr_reader :children

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

      def <<(child)
        unless @children.include?(child)
          @children << child
          child.parent = self
        end
        child
      end
      alias_method :add_child, :<<

      protected
      def handle_init_event(event)
        @children.each { |child| child.dispatch(event) }
        @time_last = max_time_last
        @time_next = min_time_next
        info "#{self.model} set tl: #{@time_last}; tn: #{@time_next}"
      end

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

      def handle_output_event(event)
        payload, port = *event.message

        model.each_output_coupling(port) do |coupling|
          info "    found external output coupling #{coupling}"
          message = Message.new(payload, c.destination_port)
          new_event = Event.new(:y, event.time, message)
          info "    dispatching #{new_event}"
          parent.dispatch(event)
        end

        model.each_internal_coupling(port) do |coupling|
          info "    found internal coupling #{coupling}"
          message = Message.new(payload, coupling.destination_port)
          new_event = Event.new(:x, event.time, message)
          info "    dispatching #{new_event}"
          coupling.destination.processor.dispatch(new_event)
        end
      end

      def min_time_next
        @children.map { |child| child.time_next }.min
      end

      def max_time_last
        @children.map { |child| child.time_last }.max
      end

      def imminent_children
        @children.select { |child| child.time_next == time_next }
      end
    end
  end
end
