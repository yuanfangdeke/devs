module DEVS
  module TimeWarp
    module SimulatorStrategy
      def after_initialize
        super
        @queue = []
      end

      # This class encapsulate the state of a {Model} for the current simulation
      # time. All instance variables values of the model are preserved along
      # with the {Simulator#time_next} and {Simulator#time_last} values.
      class State
        attr_reader :time_last, :time_next, :instance_variables

        # @!attribute [r] time_last
        #   @return [Numeric] Returns the saved time last value

        # @!attribute [r] time_next
        #   @return [Numeric] Returns the saved time next value

        # @!attribute [r] instance_variables
        #   @return [Hash<Symbol, Object>] Returns a hash associating each value
        #     for each variable name

        # Returns a new instance of {State}
        #
        # @param time_last [Numeric] the current {Simulator#time_last} value
        # @param time_next [Numeric] the current {Simulator#time_next} value
        # @param instance_variables [Hash<Symbol, Object>] a hash associating
        #   each value for each variable name
        def initialize(time_last, time_next, instance_variables)
          @time_last, @time_next = time_last, time_next
          @instance_variables = instance_variables
        end
      end

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

      def handle_internal_event(event)
        super(event)
        save_current_state
      end

      # Save the current state of the associated {Model} into a {State} object
      # and push this state in an internal queue.
      def save_current_state
        hash = Hash.new

        @model.instance_variables.each do |name|
          hash[name] = @model.instance_variable_get(name)
        end

        @queue << State.new(@time_last, @time_next, hash)
      end

      # Restore the state of the associated {Model} at a given time.
      #
      # @param time [Numeric] the time at which the model state should be
      #   restored
      # @raise [BadSynchronisationError] if no state were saved at the given
      #   time
      def restore_state(time)
        state = @queue.pop
        state = @queue.pop until state == nil || state.time_last == time

        raise BadSynchronisationError, "No state at given time were saved" if state.nil?

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

      # Perform a fossil collection based on the given global virtual time. All
      # events prior to GVT can be freed so we can clean up saved states.
      #
      # @param gvt [Numeric] the global virtual time, computed as the minimum of
      #   the last event times in all processors and the minimum of the pending
      #   events
      # @return [Array<State>] the deleted states
      def fossil_collection(gvt)
        @queue.delete_if { |state| state.time_next < gvt }
      end
    end
  end
end
