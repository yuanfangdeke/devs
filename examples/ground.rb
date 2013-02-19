$:.push File.expand_path('../../lib', __FILE__)

require 'devs'
require 'gnuplot'
require 'csv'

class RandomGenerator < DEVS::AtomicModel
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
    selected_ports.each { |port| send((@min + rand * @max).round, port) }
  end

  time_advance { self.sigma }
end

class Collector < DEVS::AtomicModel
  def initialize
    super()
    @results = {}
  end

  external_transition do
    input_ports.each do |port|
      value = retrieve(port)

      if @results.has_key?(port.name)
        ary = @results[port.name]
      else
        ary = []
        @results[port.name] = ary
      end

      ary << [self.time, value] unless value.nil?
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

        #plot.terminal 'png'
        #plot.output File.expand_path("../#{self.name}.png", __FILE__)

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

      max = values.map { |column| column.size }.max
      0.upto(max) do |i|
        row = []
        values.each { |column| row << (column[i].nil? ? 0 : column[i]) }
        csv << row
      end
    end
    File.open("#{self.name}.csv", 'w') { |file| file.write(content) }
  end
end

class Ground < DEVS::AtomicModel
  def initialize(cc = 100.0, out_flow = 1.0)
    super()

    @pluviometrie = 0
    @cc = cc
    @out_flow = out_flow
    @ruissellement = 0
  end

  delta_ext do
    input_ports.each do |port|
      value = retrieve(port)
      @pluviometrie += value unless value.nil?
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
    send(@pluviometrie, output_ports.first)
    send(@ruissellement, output_ports.last)
  end

  time_advance { self.sigma }
end

#DEVS.logger = nil

# require 'perftools'
# PerfTools::CpuProfiler.start("/tmp/ground_simulation") do
DEVS.simulate do
  duration 100

  atomic(RandomGenerator, 0, 5) { name :random }

  atomic(Ground, 40.0, 5.0) do
    name :ground
    add_output_port(:pluviometrie)
    add_output_port(:ruissellement)
  end

  atomic(PlotCollector) do
    name :plot_output
    add_input_port :pluviometrie
    add_input_port :ruissellement
  end

  atomic(CSVCollector) do
    name :csv_output
    add_input_port :pluviometrie
    add_input_port :ruissellement
  end

  add_internal_coupling(:random, :ground)
  add_internal_coupling(:ground, :plot_output, :pluviometrie, :pluviometrie)
  add_internal_coupling(:ground, :plot_output, :ruissellement, :ruissellement)
  add_internal_coupling(:ground, :csv_output, :pluviometrie, :pluviometrie)
  add_internal_coupling(:ground, :csv_output, :ruissellement, :ruissellement)
end
#end

