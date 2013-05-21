require 'csv'

module DEVS
  module Models
    module Collectors
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
    end
  end
end
