module DEVS
  class Simulator < Processor
    # Returns a new instance of {Coordinator}
    #
    # @param model [CoupledModel] the managed coupled model
    # @param namespace [Module] the namespace providing template method
    #   implementation
    def initialize(model, namespace)
      super(model)
      extend namespace::SimulatorImpl
      after_initialize if respond_to?(:after_initialize)
    end
  end
end
