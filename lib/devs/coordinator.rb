module DEVS
  class Coordinator < Processor
    attr_reader :children

    def initialize(model)
      super(model)
      @children = []
    end

    def add_child(child)
      unless @children.include?(child)
        @children << child
        child.parent = self
      end
      child
    end

    # variables:
    #   tl // time of last event
    #   tn // time of next event
    #   y = (y.value, y.port) // current output of the DEVS coordinator
    #   D // list of children
    #   IC // list of connections of the form [(di,portx),(dj,porty)]
    #   EIC // list of connections of the form [(N,portx),(dj,porty)]
    #   EOC // list of connections of the form [(di, portx), (N, porty)]
    # when i–message (i, t) is received at time t
    #   send i–message (i, t) to all children
    #   d∗ = arg[mind∈D(d.tn)]
    #   tl = t
    #   tn = d∗.tn
    # when ∗–message (∗, t) is received at time t
    #   send ∗–message (∗, t) to d∗
    #   d∗ = arg[mind∈D(d.tn)]
    #   tl = t
    #   tn = d∗.tn
    # when x–message ((x.value, x.port), t) is received at time t
    #   (v, p) = (x.value, x.port)
    #   for each connection [(N, p), (d, q)]
    #     send x–message ((v, q),t) to child d
    #   d∗ = arg[mind∈D(d.tn)]
    #   tl = t
    #   tn = d∗.tn
    # when y–message ((y.value, y.port),t) is received from d∗
    #   if a connection [(d∗, y.port), (N, q)] exists
    #     send y–message ((y.value, q),t) to parent coordinator
    #   for each connection [(d∗, y.port), (d, q)]
    #     send x–message ((y.value, q),t) to child d
    def receive(event)
      puts "#{self.model.name} received event at time #{event.time} of type #{event.type}"
      case event.type
      when :i
        children.each { |child| child.dispatch(event) }
        @time_last = event.time
        @time_next = min_time_next
      when :*
        if event.time != @time_next
          raise BadSynchronisationError,
                "time: #{event.time} should match time_next: #{@time_next}"
        end

        children = imminent_children
        children_models = children.map { |processor| processor.model }
        child_model = model.select(children_models)
        puts "    selected #{child_model.name} in \
[#{children_models.map { |model| model.name }.join(' ,')}]"
        child = children[children_models.index(child_model)]

        child.dispatch(event)

        @time_last = event.time
        @time_next = child.time_next
      when :x
        unless @time_last <= event.time && event.time <= @time_next
          raise BadSynchronisationError, "time: #{event.time} should be between\
 time_last: #{@time_last} and time_next: #{@time_next}"
        end

        payload = event.message.payload
        port = event.message.port

        model.eic_with_port_source(port).each do |coupling|
          puts "    #{self.model.name} found external input coupling \
[(#{port.host.name}, #{port.name}), (#{coupling.destination.name}, \
#{coupling.destination_port.name})]"
          child = child_with_model(coupling.destination)
          message = Message.new(payload, coupling.destination_port)
          child.dispatch(Event.new(:x, event.time, message))
        end

        @time_last = event.time
        @time_next = min_time_next
      when :y
        payload = event.message.payload
        port = event.message.port

        child = child_with_model(port.host)
        c = model.first_eoc_with_port_source(port)

        unless c.nil?
          puts "    found external output coupling [(#{port.host.name}, \
#{port.name}), (#{coupling.destination.name}, \
#{coupling.destination_port.name})]"
           puts "    dispatching event of type x with message #{payload} to \
#{coupling.destination.name} on port #{coupling.destination_port.name}"
          message = Message.new(payload, c.destination_port)
          parent.dispatch(Event.new(:y, event.time, message))
        end

        model.ic_with_port_source(port).each do |coupling|
          puts "    found internal coupling [(#{port.host.name}, #{port.name}),\
 (#{coupling.destination.name}, #{coupling.destination_port.name})]"
           puts "    dispatching event of type x with message #{payload} to \
#{coupling.destination.name} on port #{coupling.destination_port.name}"
          message = Message.new(payload, coupling.destination_port)
          new_event = Event.new(:x, event.time, message)
          child_with_model(coupling.destination).dispatch(new_event)
        end
      end
    end
    alias_method :dispatch, :receive

    protected
    attr_writer :children

    def child_with_model(model)
      @children.find { |child| child.model == model }
    end

    def min_time_next
      @children.map { |child| child.time_next }.min
    end

    def imminent_children
      @children.select { |child| child.time_next == time_next }
    end
  end
end
