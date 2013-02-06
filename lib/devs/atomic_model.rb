module DEVS
  class AtomicModel < Model
    class << self
      def external_transition(&block)
        define_method(:external_transition, &block) if block
      end

      def internal_transition(&block)
        define_method(:internal_transition, &block) if block
      end

      def time_advance(&block)
        define_method(:time_advance, &block) if block
      end

      def lambda(&block)
        define_method(:lambda, &block) if block
      end

      alias_method :ext_transition, :external_transition
      alias_method :delta_ext, :external_transition
      alias_method :int_transition, :internal_transition
      alias_method :delta_int, :internal_transition
      alias_method :ta, :time_advance
      alias_method :output, :lambda
    end

    def initialize(*args)
      super(*args)
    end

    def external_transition; end
    alias_method :ext_transition, :external_transition
    alias_method :delta_ext, :external_transition

    def internal_transition; end
    alias_method :int_transition, :internal_transition
    alias_method :delta_int, :internal_transition

    def time_advance
      INFINITY
    end
    alias_method :ta, :time_advance

    def lambda; end
    alias_method :output, :lambda
  end
end
