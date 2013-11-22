require 'devs'
require 'devs/models'

DEVS.logger = Logger.new(STDOUT)
DEVS.logger.level = Logger::INFO

DEVS.simulate do
  duration 10_000

  # algorithm [:classic, :parallel, :time_warp]

  add_coupled_model do
    name :generator
    add_model DEVS::Models::Generators::RandomGenerator, with_params: [0, 5], :name => :random
    plug_output_port :output, :with_child => :random, :and_child_port => :output
  end

  add_model do
    name :ground

    init do
      @pluviometrie = 0
      @cc = 40.0
      @out_flow = 5.0
      @ruissellement = 0
    end

    when_input_received do |messages|
      messages.each do |message|
        value = message.payload
        @pluviometrie += value unless value.nil?
      end

      @pluviometrie = [@pluviometrie - (@pluviometrie * (@out_flow / 100)), 0].max

      if @pluviometrie > @cc
        @ruissellement = @pluviometrie - @cc
        @pluviometrie = @cc
      end

      self.next_activation = 0
    end

    output do
      post(@pluviometrie, output_ports.first)
      post(@ruissellement, output_ports.last)
    end

    after_output do
      @ruissellement = 0
      self.next_activation = DEVS::INFINITY
    end

    time_advance do
      self.next_activation
    end
  end

  add_coupled_model do
    name :collector

    #add_model DEVS::Models::Collectors::PlotCollector, :name => :plot_output
    add_model DEVS::Models::Collectors::CSVCollector, :name => :csv_output

    plug_input_port :pluviometrie, :with_child => :csv_output, :and_child_port => :pluviometrie
    plug_input_port :ruissellement, :with_child => :csv_output, :and_child_port => :ruissellement

    #add_external_input_coupling(:plot_output, :pluviometrie, :pluviometrie)
    #add_external_input_coupling(:plot_output, :ruissellement, :ruissellement)
  end

  plug :generator, :with => :ground, :from => :output, :to => :input
  plug :ground, :with => :collector, :from => :pluviometrie, :to => :pluviometrie
  plug :ground, :with => :collector, :from => :ruissellement, :to => :ruissellement
end
