module DEVS
  module Parallel
    class AtomicModel < Classic::AtomicModel
      class << self
        def confluent_transition(&block)
          define_method(:confluent_transition, &block) if block
        end
        alias_method :delta_con, :confluent_transition
      end

      def confluent_transition; end
    end
  end
end
