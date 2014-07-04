module DEVS
  module Parallel
    # This module represent the interface with {Simulation}. It it responsible for
    # coordinating the simulation.
    module Simulable
      def initialize_state(time)
        dispatch(Event.new(:init, @time))
        @time_next
      end

      def step(time)
        dispatch(Event.new(:collect, time))
        dispatch(Event.new(:internal, time))
        @time_next
      end
    end
  end
end
