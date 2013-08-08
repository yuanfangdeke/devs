$:.push File.expand_path('../../lib', __FILE__)

# require 'pry'
# require 'pry-nav'
# require 'pry-stack_explorer'

require 'devs'
require 'devs/models'

DEVS.logger = Logger.new(STDOUT)
DEVS.logger.level = Logger::INFO

# Uncomment this line to use P-DEVS instead of classic simulators
#require 'devs/parallel'

# require 'perftools'
# PerfTools::CpuProfiler.start("/tmp/ground_simulation") do
DEVS.simulate do
  duration 100

  coupled do
    name :generator
    atomic(DEVS::Models::Generators::RandomGenerator, 0, 5) { name :random }
    add_external_output_coupling(:random, :output, :output)
  end

  select { |imm| imm.sample }

  atomic do
    name :ground

    init do
      @pluviometrie = 0
      @cc = 40.0
      @out_flow = 5.0
      @ruissellement = 0
    end

    external_transition do |*messages|
      messages.each do |message|
        value = message.payload
        @pluviometrie += value unless value.nil?
      end

      @pluviometrie = [@pluviometrie - (@pluviometrie * (@out_flow / 100)), 0].max

      if @pluviometrie > @cc
        @ruissellement = @pluviometrie - @cc
        @pluviometrie = @cc
      end

      self.sigma = 0
    end

    internal_transition {
      @ruissellement = 0
      self.sigma = DEVS::INFINITY
    }

    output do
      post(@pluviometrie, output_ports.first)
      post(@ruissellement, output_ports.last)
    end

    time_advance { self.sigma }
  end

  coupled do
    name :collector

    atomic(DEVS::Models::Collectors::PlotCollector) { name :plot_output }
    atomic(DEVS::Models::Collectors::CSVCollector) { name :csv_output }

    add_external_input_coupling(:plot_output, :pluviometrie, :pluviometrie)
    add_external_input_coupling(:csv_output, :pluviometrie, :pluviometrie)
    add_external_input_coupling(:plot_output, :ruissellement, :ruissellement)
    add_external_input_coupling(:csv_output, :ruissellement, :ruissellement)
  end

  add_internal_coupling(:generator, :ground, :output, :input)
  add_internal_coupling(:ground, :collector, :pluviometrie, :pluviometrie)
  add_internal_coupling(:ground, :collector, :ruissellement, :ruissellement)
end
#end
