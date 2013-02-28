module DEVS
  module Parallel
    class Coordinator < Classic::Coordinator
      #include Celluloid

      def initialize(model)
        super(model)
        @bag = []
        @synchronize = Set.new
      end

      def dispatch(event)
        super(event)

        case event.type
        when :'@' then handle_collect_event(event)
        end
      end

      protected

      def handle_collect_event(event)
        if event.time == @time_next
          @time_last = event.time
          # futures = imminent_children.map { |child| child.future.dispatch(event)}
          # futures.map(&:value)
          #:done
          imminent_children.each do |child|
            @synchronize << child
            child.dispatch(event)
          end
        else
          raise BadSynchronisationError,
                "time: #{event.time} should match time_next: #{@time_next}"
        end
      end

      def handle_output_event(event)
        payload, port = *event.message

        model.each_output_coupling(port) do |coupling|
          info "    found external output coupling #{coupling}"
          message = Message.new(payload, coupling.destination_port)
          new_event = Event.new(:y, event.time, message)
          info "    dispatching #{new_event}"
          #parent.async.dispatch(new_event)
          parent.dispatch(new_event)
        end

        futures = []
        model.each_internal_coupling(port) do |coupling|
          info "    found internal coupling #{coupling}"
          message = Message.new(payload, coupling.destination_port)
          new_event = Event.new(:x, event.time, message)
          info "    dispatching #{new_event}"
          #futures << coupling.destination.processor.future.dispatch(new_event)
          child = coupling.destination.processor
          @synchronize << child
          child.dispatch(new_event)
        end
        #futures.map(&:value)
      end

      def handle_input_event(event)
        @bag << event.message
        :done
      end

      def handle_star_event(event)
        if (@time_last..@time_next).include?(event.time)
          inputs = Hash.new { |hash, key| hash[key] = [] }
          @bag.each { |msg| inputs[msg.port] << msg.payload }

          inputs.each do |port, values|
            model.each_input_coupling(port) do |coupling|
              info "    #{self.model} found external input coupling #{coupling}"
              values.each do |payload|
                message = Message.new(payload, coupling.destination_port)
                child = coupling.destination.processor
                @synchronize << child
                child.dispatch(Event.new(:x, event.time, message))
              end
            end
          end
          @bag.clear
          #futures.map(&:value)

          #futures = selected.map do |child|
          @synchronize.each do |child|
            #child.future.dispatch(Event.new(:*, event.time))
            child.dispatch(Event.new(:*, event.time))
          end
          #futures.map(&:value)
          @synchronize.clear
          @time_last = event.time
          @time_next = min_time_next
          :done
        else
          raise BadSynchronisationError, "time: #{event.time} should be " \
              + "between time_last: #{@time_last} and time_next: #{@time_next}"
        end
      end

      # def handle_star_event(event)
      #   if event.time == @time_next
      #     imminent_children.each { |child| child.dispatch(event) }
      #     :done
      #   else
      #     raise BadSynchronisationError,
      #           "time: #{event.time} should match time_next: #{@time_next}"
      #   end
      # end

      # def handle_input_event(event)
      #   if (@time_last..@time_next).include?(event.time)
      #     payload, port = *event.message

      #     receivers = []
      #     model.each_input_coupling(port) do |coupling|
      #       info "    #{self.model} found external input coupling #{coupling}"
      #       child = coupling.destination.processor
      #       receivers << child
      #       message = Message.new(payload, coupling.destination_port)
      #       child.dispatch(Event.new(:x, event.time, message))
      #     end

      #   else
      #     raise BadSynchronisationError, "time: #{event.time} should be " \
      #         + "between time_last: #{@time_last} and time_next: #{@time_next}"
      #   end
      # end
    end
  end
end
