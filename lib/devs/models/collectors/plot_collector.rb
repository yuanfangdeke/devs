require 'gnuplot'

module DEVS
  module Models
    module Collectors
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
    end
  end
end
