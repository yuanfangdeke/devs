module DEVS
  module Builders
    class SimulationBuilder < CoupledBuilder
      attr_accessor :duration
      attr_reader :root_coordinator

      def initialize(namespace, dsl_type, &block)
        @maintain_hierarchy = false
        @generate_graph = false
        @graph_file = 'model_hierarchy'
        @graph_format = 'png'

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

        flatten! unless @maintain_hierarchy
        generate_graph if @generate_graph
        hooks.each { |observer| @root_coordinator.add_observer(observer) }
      end

      def generate_graph!(file = nil, format = nil)
        @graph_file = file if file
        @graph_format = format if format
        @generate_graph = true
      end

      def maintain_hierarchy!
        @maintain_hierarchy = true
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

      def flatten!
        rm = @model
        rm.find_all { |m| m.coupled? }
          .each { |cm| _flatten!(rm, cm) }
      end
      private :flatten!

      # Flatten the hierarchy recursively using direct connection algorithm
      def _flatten!(rm, cm)
        cm.each do |child|
          if child.coupled?
            # recursive invoke to direct connect all atomics
            _flatten!(rm, child)
          else
            # add the atomic of cm to the rm
            rm << child
            rm.processor << child.processor
          end
        end

        # copy each internal couplings of cm to rm
        rm.internal_couplings.push(*cm.internal_couplings)

        # adjust ports
        parent = cm.parent
        cm.each_input_coupling do |eic|
          parent.each_internal_coupling do |ic|
            if ic.destination_port == eic.port_source
              rm.add_internal_coupling(ic.source, eic.destination,
                                       ic.port_source, eic.destination_port)
            end
          end
        end
        cm.each_output_coupling do |eoc|
          parent.each_internal_coupling do |ic|
            if ic.port_source == eoc.destination_port
              rm.add_internal_coupling(eoc.source, ic.destination,
                                       eoc.port_source, ic.destination_port)
            end
          end
        end

        # remove cm childs
        cm.each do |child|
          cm.remove_child(child)
          cm.processor.remove_child(child)
        end
        # remove cm
        rm.remove_child(cm)
        rm.processor.remove_child(cm.processor)
      end
      private :_flatten!

      def generate_graph(file, format)
        # require optional dependency
        require 'graph'
        graph = Graph.new
        graph.boxes
        fill_graph(graph, @model)
        graph.save(file, format)
      rescue LoadError
        DEVS.logger.warn  "Unable to generate a graph representation of the model"
                        + " hierarchy. Please install graphviz on your system and"
                        + " 'gem install graph'."
      end
      private :generate_graph

      def fill_graph(graph, cm)
        cm.each do |model|
          if model.coupled?
            subgraph = graph.cluster(model.name.to_s)
            subgraph.label model.name.to_s
            fill_graph(subgraph, model)
          else
            graph.node(model.name.to_s)
          end
        end
      end
      private :fill_graph
    end
  end
end
