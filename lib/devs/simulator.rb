module DEVS
  class Simulator < Processor
    # Returns a new instance of {Coordinator}
    #
    # @param model [CoupledModel] the managed coupled model
    def initialize(model)
      super(model)
      after_initialize if respond_to?(:after_initialize)
    end
  end
end
