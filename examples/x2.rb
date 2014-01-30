require 'devs'
#require 'devs/parallel'
require 'devs/models'

DEVS.logger = Logger.new(STDOUT)
#DEVS.logger.level = Logger::INFO

obj = DEVS.simulate do
  duration DEVS::INFINITY

  add_model DEVS::Models::Generators::SequenceGenerator, with_args: [1, 5, 1], :name => :sequence

  add_model do
    name 'x^x'
    # reverse_confluent_transition!

    init do
      add_output_port :out_1
      add_input_port :in_1
    end

    when_input_received do |messages|
      messages.each do |message|
        value = message.payload
        @result = value ** value
      end
      @sigma = 0
    end

    output do
      post @result, :out_1
    end

    after_output { @sigma = DEVS::INFINITY }
    # time_advance { @sigma }
  end

  add_coupled_model do
    name :collector

    add_model DEVS::Models::Collectors::PlotCollector, :name => :plot
    add_model DEVS::Models::Collectors::CSVCollector, :name => :csv

    plug_input_port :a, with_children: ['csv@x', 'plot@x']
    plug_input_port :b, :with_children ['csv@x^x', 'plot@x^x']
  end

  plug 'sequence@value', with: 'x^x@in_1'
  # plug 'sequence@value', with: 'collector@a'
  plug 'x^x@out_1', with: 'collector@a'
end

# status = obj.status
# while status != :done
#   puts "status: #{status}"
#   puts "percentage: #{obj.percentage}"
#   status = obj.status
# end

obj.wait
