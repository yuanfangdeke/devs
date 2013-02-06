module DEVS
  class Model
    attr_accessor :name
    attr_reader :input_ports, :output_ports

    def initialize(name = self.class.name)
      @name = name
      @input_ports = []
      @output_ports = []
    end
  end
end
