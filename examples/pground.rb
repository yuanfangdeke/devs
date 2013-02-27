$:.push File.expand_path('../../lib', __FILE__)

require 'devs'
require 'gnuplot'
require 'csv'

class RandomGenerator < DEVS::Parallel::AtomicModel
  def initialize(min = 0, max = 10, min_step = 1, max_step = 1)
    super()

    @min = min
    @max = max
    @min_step = min_step
    @max_step = max_step
    self.sigma = 0
  end

  delta_int { self.sigma = (@min_step + rand * @max_step).round }

  output do
    messages_count = (1 + rand * output_ports.count).round
    selected_ports = output_ports.sample(messages_count)
    selected_ports.each { |port| post((@min + rand * @max).round, port) }
  end

  time_advance { self.sigma }
end

class Collector < DEVS::Parallel::AtomicModel
  def initialize
    super()
    @results = {}
  end

  external_transition do
    input_ports.each do |port|
      values = retrieve(port)

      if @results.has_key?(port.name)
        ary = @results[port.name]
      else
        ary = []
        @results[port.name] = ary
      end

      values.each { |v| ary << [self.time, v] } unless values.nil?
    end

    self.sigma = 0
  end

  internal_transition { self.sigma = DEVS::INFINITY }

  time_advance { self.sigma }
end

class PlotCollector < Collector
  post_simulation_hook do
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|
        plot.title  self.name
        plot.ylabel "events"
        plot.xlabel "time"

        @results.each { |key, value|
          x = []
          y = []
          @results[key].each { |a| x << a.first; y << a.last }
          plot.data <<  Gnuplot::DataSet.new([x, y]) do |ds|
            ds.with = "lines"
            ds.title = key
          end
        }
      end
    end
  end
end

class CSVCollector < Collector
  post_simulation_hook do
    content = CSV.generate do |csv|
      columns = []
      @results.keys.each { |column| columns << "time"; columns << column }
      csv << columns

      values = []
      @results.each { |key, value|
        y = []
        x = []
        @results[key].each { |a| x << a.first; y << a.last }
        values << x
        values << y
      }

      max = values.map { |column| column.size }.max || 0
      0.upto(max) do |i|
        row = []
        values.each { |column| row << (column[i].nil? ? 0 : column[i]) }
        csv << row
      end
    end
    File.open("#{self.name}.csv", 'w') { |file| file.write(content) }
  end
end

#DEVS.logger = nil

# require 'perftools'
# PerfTools::CpuProfiler.start("/tmp/ground_simulation") do
DEVS.psimulate do
  duration 100

  coupled do
    name :generator
    atomic(RandomGenerator, 0, 5) { name :random }
    add_external_output_coupling(:random, :output)
  end


  atomic do
    name :ground

    init do
      @pluviometrie = 0
      @cc = 40.0
      @out_flow = 5.0
      @ruissellement = 0
    end

    delta_ext do
      input_ports.each do |port|
        values = retrieve(port)
        @pluviometrie += values.reduce(0, &:+) unless values.nil?
      end

      @pluviometrie = [@pluviometrie - (@pluviometrie * (@out_flow / 100)), 0].max

      if @pluviometrie > @cc
        @ruissellement = @pluviometrie - @cc
        @pluviometrie = @cc
      end

      self.sigma = 0
    end

    delta_int {
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

    atomic(PlotCollector) { name :plot_output }
    atomic(CSVCollector) { name :csv_output }

    add_external_input_coupling(:plot_output, :pluviometrie, :pluviometrie)
    add_external_input_coupling(:csv_output, :pluviometrie, :pluviometrie)
    add_external_input_coupling(:plot_output, :ruissellement, :ruissellement)
    add_external_input_coupling(:csv_output, :ruissellement, :ruissellement)
  end

  add_internal_coupling(:generator, :ground, :output)
  add_internal_coupling(:ground, :collector, :pluviometrie, :pluviometrie)
  add_internal_coupling(:ground, :collector, :ruissellement, :ruissellement)
end
#end
