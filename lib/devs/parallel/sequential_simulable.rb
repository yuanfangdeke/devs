module DEVS
  module SequentialParallel
    # This module represent the interface with {Simulation}. It it responsible for
    # coordinating the simulation.
    module Simulable
      def initialize_state(time)
        init(time)
      end

      def step(time)
        remainder(time, collect(time))
      end
    end
  end
end
