require 'logger'
# require 'highline/import'
# require 'graphviz'


module DEVS
  INFINITY = Float::INFINITY
end

require 'devs/version'
require 'devs/errors'
require 'devs/logging'

require 'devs/event'
require 'devs/message'
require 'devs/coupling'
require 'devs/port'
require 'devs/model'
require 'devs/atomic_model'
require 'devs/coupled_model'

require 'devs/processor'
require 'devs/root_coordinator'
require 'devs/simulator'
require 'devs/coordinator'

module DEVS

  # Runs a simulation
  # @todo
  # @example
  #   simulate do
  #     duration = 200
  #
  #   end
  #
  def self.simulate(&block)
    root_coordinator = SimulationBuilder.new(&block).root_coordinator

    # response = ask("Build the graph of the simulation? (yes, no): ") do |q|
    #   q.default = 'yes'
    #   q.validate = /(yes)|(no)/i
    # end
    # case response
    # when /yes/
    #   GraphBuilder.new(root_coordinator.child.model)
    # end

    root_coordinator.simulate
  end

  class AtomicBuilder
    attr_reader :model, :processor

    def initialize(klass, *args, &block)
      @model = klass.new(*args)
      @processor = Simulator.new(@model)
      instance_eval(&block) if block
    end

    def add_input_port(*args)
      @model.add_input_port(*args)
    end

    def add_output_port(*args)
      @model.add_output_port(*args)
    end

    def name(name)
      @model.name = name
    end
  end

  class CoupledBuilder < AtomicBuilder
    def initialize(&block)
      @model = CoupledModel.new
      @processor = Coordinator.new(@model)
      instance_eval(&block) if block
    end

    def coupled(&block)
      coordinator = CoupledBuilder.new(&block).processor
      coordinator.parent = @processor
      coordinator.model.parent = @model
      @model.add_child(coordinator.model)
      @processor.add_child(coordinator)
    end

    def atomic(type, *args, &block)
      simulator = AtomicBuilder.new(type, *args, &block).processor
      simulator.parent = @processor
      simulator.model.parent = @model
      @model.add_child(simulator.model)
      @processor.add_child(simulator)
    end

    def select(&block)
      @model.define_singleton_method(:select, &block) if block
    end

    def add_internal_coupling(*args)
      @model.add_internal_coupling(*args)
    end

    def add_external_output_coupling(*args)
      @model.add_external_output_coupling(*args)
    end
    alias_method :add_external_output, :add_external_output_coupling

    def add_external_input_coupling(*args)
      @model.add_external_input_coupling(*args)
    end
    alias_method :add_external_input, :add_external_input_coupling
  end

  class SimulationBuilder < CoupledBuilder
    attr_accessor :duration
    attr_reader :root_coordinator

    def initialize(&block)
      @model = CoupledModel.new
      @model.name = :RootCoupledModel
      @model.parent = self
      @processor = Coordinator.new(@model)
      @duration = RootCoordinator::DEFAULT_DURATION
      instance_eval(&block) if block
      @root_coordinator = RootCoordinator.new(@processor, @duration)
    end

    def duration(duration)
      @duration = duration
    end
  end

  # Returns the current version of the gem
  def version
    VERSION
  end
  module_function :version
end
