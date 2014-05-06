module DEVS
  module Builders
    class SimulationBuilder < CoupledBuilder
      attr_accessor :duration
      attr_reader :root_coordinator

      def initialize(namespace, dsl_type, &block)
        @namespace = namespace
        @dsl_type = dsl_type

        @model = CoupledModel.new
        @model.name = :RootCoupledModel

        @processor = Coordinator.new(@model, namespace)
        @processor.after_initialize if @processor.respond_to?(:after_initialize)

        @model.processor = @processor

        @duration = RootCoordinator::DEFAULT_DURATION

        case dsl_type
        when :eval then instance_eval(&block)
        when :yield then block.call(self)
        end

        @root_coordinator = RootCoordinator.new(@processor, namespace::RootCoordinatorStrategy, @duration)

        hooks.each { |observer| @root_coordinator.add_observer(observer) }
      end

      def duration(duration)
        @duration = duration
      end

      def hooks(observers = [], model = @model)
        if model.is_a? CoupledModel
          model.each { |child| hooks(observers, child) }
        else
          observers << model if model.observer?
        end
        observers
      end
      private :hooks

      # Flatten the hierarchy recursively using direct connection algorithm
      def flatten(rm = @model, cm = @model)
        cm.each do |child|
          if child.coupled?
            # recursive invoke to direct connect all atomics
            flatten(cm, child)
          else
            # add the atomic of cm to the rm
            unless rm.include?(child)
              simulator = child.processor
              simulator.parent = rm.processor
              child.parent = rm

              rm << child
              rm.processor << simulator
            end
          end
        end

        # copy each internal couplings of cm to rm
        rm.internal_couplings.push(*cm.internal_couplings)

        # adjust ports
        cm.external_input_couplings.map do |eic|
          cm.each_internal_coupling do |ic|
            if ic.destination_port == eic.port_source
              rm.add_internal_coupling(ic.source, eic.destination,
                                       ic.port_source, eic.destination_port)
            end
          end
        end
        cm.external_output_couplings.map do |eoc|
          cm.each_internal_coupling do |ic|
            if ic.port_source == eoc.destination_port
              rm.add_internal_coupling(eoc.source, ic.destination,
                                       eoc.port_source, ic.destination_port)
            end
          end
        end
      end
    end
  end
end
