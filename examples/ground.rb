require 'devs'
#require 'devs/parallel'
require 'devs/models'
require 'ruby-progressbar'

Thread.abort_on_exception = true

DEVS.logger = Logger.new('logfile.log')
#DEVS.logger.level = Logger::INFO

obj = DEVS.simulate do
  duration 10000

  # algorithm [:classic, :parallel, :time_warp]

  add_coupled_model do
    name :generator
    add_model DEVS::Models::Generators::RandomGenerator, with_args: [0, 5], :name => :random
    plug_output_port :output, :with_child => 'random@output'
  end

  add_model do
    name :ground

    init do
      add_output_port :pluviometrie
      add_output_port :ruissellement
      add_input_port :input

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

      @sigma = 1
    end

    output do
      post @pluviometrie, :pluviometrie
      post @ruissellement, :ruissellement
    end

    after_output do
      @ruissellement = 0
      @sigma = DEVS::INFINITY
    end

    # if_transition_collides do |*messages|
    #   external_transition *messages
    #   internal_transition
    # end

    time_advance { @sigma }
  end

  add_coupled_model do
    name :collector

    add_model DEVS::Models::Collectors::PlotCollector, :name => :plot_output
    add_model DEVS::Models::Collectors::CSVCollector, :name => :csv_output

    plug_input_port :pluviometrie, with_children: ['csv_output@pluviometrie', 'plot_output@pluviometrie']
    plug_input_port :ruissellement, with_children: ['csv_output@ruissellement', 'plot_output@ruissellement']
  end

  plug 'generator@output', with: 'ground@input'
  plug 'ground@pluviometrie', with: 'collector@pluviometrie'
  plug 'ground@ruissellement', with: 'collector@ruissellement'
end

obj.wait
