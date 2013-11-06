require 'csv'

module DEVS
  module Models
    module Generators
      class CSVRowGenerator < DEVS::AtomicModel
        def initialize(input_file = 'csv_input.csv', col_sep = nil, step = 1)
          super()

          opts = col_sep.nil? ? nil : { col_sep: col_sep }
          File.open(input_file, 'r') do |file|
            @csv = CSV.parse(file.read, opts)
          end
          @csv.shift #headers

          @step = step
          self.sigma = 0
        end

        def internal_transition
          self.sigma = @last_row.nil? ? DEVS::INFINITY : @step
        end

        def output
          @last_row = @csv.shift
          unless @last_row.nil?
            @last_row.map! { |v| v.gsub(',', '.').to_f }
            post(@last_row, output_ports.first)
          end
        end
      end
    end
  end
end
