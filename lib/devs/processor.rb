module DEVS
  class Processor
    attr_accessor :parent
    attr_reader :model, :time_next, :time_last

    alias_method :tn, :time_next
    alias_method :tl, :time_last

    def initialize(model)
      @model = model
      @time_next = 0
      @time_last = 0
    end
  end
end
