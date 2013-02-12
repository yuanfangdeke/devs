$:.push File.expand_path('../../lib', __FILE__)

require 'devs'

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

class PlotGenerator < DEVS::AtomicModel
  def initialize
    super()
    @results = Hash.new { [] }
    @events = 0
  end

  external_transition do
    input_ports.each do |port|
      value = retrieve(port)
      @results[port] << [self.time, value]

      Gnuplot.open do |gp|
        Gnuplot::Plot.new(gp) do |plot|

          plot.title  self.name
          plot.ylabel "events"
          plot.xlabel "time"

          x = @results[port].map { |ary| ary.first }
          y = @results[port].map { |ary| ary.last }

          plot.data << Gnuplot::DataSet.new( [x, y] ) do |ds|
            ds.with = "linespoints"
            ds.notitle
          end
        end
      end
    end

    self.sigma = 0
  end

  internal_transition { self.sigma = INFINITY }

  time_advance { self.sigma }
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

  delta_int { @ruissellement = 0 }

  output do
    send(@pluviometrie, output_ports.first)
    send(@ruissellement, output_ports.last)
    self.sigma = INFINITY
  end

  time_advance { self.sigma }
end

DEVS.simulate do
  duration 20

  atomic(RandomGenerator, 0, 5) do
    name :random
  end

  atomic(Ground) do
    name :ground
  end

  atomic(PlotGenerator) do
    name :pluviometrie
  end

  atomic(PlotGenerator) do
    name :ruissellement
  end

  add_internal_coupling(:random, :ground)
  add_internal_coupling(:ground, :pluviometrie)
  add_internal_coupling(:ground, :ruissellement)
end
