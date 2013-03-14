module DEVS
  module TimeWarp
    class Simulator < Classic::Simulator
      def initialize(model)
        super(model)

        @queue = []
      end

      def dispatch(event)
        super(event)

        case event.type
        when :rollback then handle_rollback_event(event)
        end
      end

      class State
        attr_reader :time_last, :time_next, :instance_variables

        def initialize(time_last, time_next, instance_variables)
          @time_last, @time_next = time_last, time_next
          @instance_variables = instance_variables
        end
      end

      private

      def handle_init_event(event)
        super(event)
        save_current_state
      end

      def handle_rollback_event(event)
        restore_state(event.time)
      end

      def handle_input_event(event)
        super(event)
        save_current_state
      end

      def handle_star_event(event)
        super(event)
        save_current_state
      end

      def save_current_state
        hash = Hash.new

        @model.instance_variables.each do |name|
          hash[name] = @model.instance_variable_get(name)
        end

        @queue << State.new(@time_last, @time_next, hash)
      end

      def restore_state(time)
        state = nil
        state = @queue.pop until state.time_last == time

        hash = state.instance_variables

        # delete variables that doesn't existed yet
        (@model.instance_variables - hash.keys).each do |name|
          @model.remove_instance_variable(name)
        end

        # restore old values
        hash.each do |name, value|
          @model.instance_variable_set(name, value)
        end

        @time_last = state.time_last
        @time_next = state.time_next
      end
    end
  end
end
