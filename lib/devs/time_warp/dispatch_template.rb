module DEVS
  module TimeWarp
    module DispatchTemplate
      def dispatch(event)
        super(event)

        case event.type
        when :i then handle_init_event(event)
        when :* then handle_star_event(event)
        when :x then handle_input_event(event)
        when :y then handle_output_event(event)
        when :rollback then handle_rollback_event(event)
        end
      end
    end
  end
end
