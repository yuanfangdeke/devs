package devs.classic;

import org.jruby.*;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyNumeric;
import org.jruby.RubyObject;
import org.jruby.RubySymbol;
import org.jruby.RubyFloat;
import org.jruby.anno.JRubyMethod;
import org.jruby.anno.JRubyModule;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import devs.DevsService;

@JRubyModule(name="DEVS::Classic::CoordinatorStrategy")
public class CoordinatorStrategy extends RubyModule {
    public CoordinatorStrategy(Ruby rb, RubyClass klass) {
        super(rb, klass);
    }

    /*
    * call-seq:
    *   handle_init_event(event)
    *
    * Handles events of init type (i messages)
    *
    * @param event [Event] the init event
    */
    @JRubyMethod(name = "handle_init_event", required = 1)
    public IRubyObject handleInitEvent(ThreadContext context, IRubyObject event) {
        RubyArray children = (RubyArray) getInstanceVariable("@children");
        RubyObject model = (RubyObject) getInstanceVariable("@model");

        for (int i = 0; i < children.getLength(); i++) {
            RubyObject child = (RubyObject) children.entry(i);
            child.callMethod(context, "dispatch", event);
        }

        RubyNumeric tl = (RubyNumeric) callMethod("max_time_last");
        RubyNumeric tn = (RubyNumeric) callMethod("min_time_next");
        setInstanceVariable("@time_last", tl);
        setInstanceVariable("@time_next", tn);

        // debug "#{model} set tl: #{@time_last}; tn: #{@time_next}"

        return getRuntime().getNil();
    }

    /*
    * call-seq:
    *   handle_input_event(event)
    *
    * Handles input events (x messages)
    *
    * @param event [Event] the input event
    * @raise [BadSynchronisationError] if the event time isn't in a proper
    *   range, e.g isn't between {Coordinator#time_last} and
    *   {Coordinator#time_next}
    */
    @JRubyMethod(name = "handle_input_event", required = 1)
    public IRubyObject handleInputEvent(ThreadContext context, IRubyObject event) {
        Ruby rb = getRuntime();
        RubyObject model = (RubyObject) getInstanceVariable("@model");
        RubyObject msg = (RubyObject) ((RubyObject) event).getInstanceVariable("@message");
        RubyObject port = (RubyObject) msg.getInstanceVariable("@port");
        RubyObject payload = (RubyObject) msg.getInstanceVariable("@payload");
        double timeLast = ((RubyNumeric) getInstanceVariable("@time_last")).getDoubleValue();
        double timeNext = ((RubyNumeric) getInstanceVariable("@time_next")).getDoubleValue();
        double eventTime = ((RubyNumeric) ((RubyObject) event).getInstanceVariable("@time")).getDoubleValue();

        if (eventTime >= timeLast && eventTime <= timeNext) {
            RubyArray ret = (RubyArray) model.callMethod(context, "each_input_coupling", port);

            for (int i = 0; i < ret.getLength(); i++) {
                RubyObject coupling = (RubyObject) ret.entry(i);
                RubyObject mdl_dst = (RubyObject) coupling.callMethod(context, "destination");
                RubyObject child = (RubyObject) mdl_dst.callMethod(context, "processor");
                IRubyObject prt_dst = coupling.getInstanceVariable("@destination_port");

                // debug "    #{model} found external input coupling #{coupling}"

                IRubyObject msg2 = DevsService.sMessage.newInstance(context, new IRubyObject[] {
                    payload,
                    prt_dst
                }, null);

                IRubyObject ev = DevsService.sEvent.newInstance(context, new IRubyObject[] {
                        RubySymbol.newSymbol(rb, "input"),
                        RubyFloat.newFloat(rb, eventTime),
                        msg2
                }, null);

                child.callMethod(context, "dispatch", ev);
            }

            setInstanceVariable("@time_last", RubyFloat.newFloat(rb, eventTime));
            RubyNumeric tn = (RubyNumeric) callMethod("min_time_next");
            setInstanceVariable("@time_next", tn);
            //   debug "#{model} time_last: #{@time_last} | time_next: #{@time_next}"
        } else {
            rb.newRaiseException(DevsService.sBadSyncError, "time: " + eventTime + " should be between time_last: " +
                    timeLast + " and time_next: " + timeNext);
        }

        return rb.getNil();
    }


    /*
    * call-seq:
    *   handle_output_event(event)
    *
    * Handles output events (y messages)
    *
    * @param event [Event] the output event
    */
    @JRubyMethod(name = "handle_output_event", required = 1)
    public IRubyObject handleOutputEvent(ThreadContext context, IRubyObject event) {
        Ruby rb = getRuntime();
        RubyObject model = (RubyObject) getInstanceVariable("@model");
        RubyObject msg = (RubyObject) ((RubyObject) event).getInstanceVariable("@message");
        RubyObject port = (RubyObject) msg.getInstanceVariable("@port");
        RubyObject payload = (RubyObject) msg.getInstanceVariable("@payload");
        RubyObject parent = (RubyObject) getInstanceVariable("@parent");
        RubyNumeric time = (RubyNumeric) ((RubyObject) event).getInstanceVariable("@time");

        RubyArray ret = (RubyArray) model.callMethod(context, "each_output_coupling", port);
        for (int i = 0; i < ret.getLength(); i++) {
            RubyObject coupling = (RubyObject) ret.entry(i);
            IRubyObject prt_dst = coupling.getInstanceVariable("@destination_port");
            // debug "    found external output coupling #{coupling}"

            IRubyObject msg2 = DevsService.sMessage.newInstance(context, new IRubyObject[] {
                    payload,
                    prt_dst
            }, null);

            IRubyObject ev = DevsService.sEvent.newInstance(context, new IRubyObject[] {
                    RubySymbol.newSymbol(rb, "output"),
                    time,
                    msg2
            }, null);

            parent.callMethod(context, "dispatch", ev);
        }

        ret = (RubyArray) model.callMethod(context, "each_internal_coupling", port);
        for (int i = 0; i < ret.getLength(); i++) {
            RubyObject coupling = (RubyObject) ret.entry(i);
            RubyObject mdl_dst = (RubyObject) coupling.callMethod(context, "destination");
            RubyObject child = (RubyObject) mdl_dst.callMethod(context, "processor");
            IRubyObject prt_dst = coupling.getInstanceVariable("@destination_port");

            // DEVS_DEBUG("found internal coupling");

            IRubyObject msg2 = DevsService.sMessage.newInstance(context, new IRubyObject[] {
                    payload,
                    prt_dst
            }, null);

            IRubyObject ev = DevsService.sEvent.newInstance(context, new IRubyObject[] {
                    RubySymbol.newSymbol(rb, "input"),
                    time,
                    msg2
            }, null);

            child.callMethod(context, "dispatch", ev);
        }

        return rb.getNil();
    }

    /*
    * call-seq:
    *   handle_internal_event(event)
    *
    * Handles star events (* messages)
    *
    * @param event [Event] the star event
    * @raise [BadSynchronisationError] if the event time is not equal to
    *   {Coordinator#time_next}
    */
    @JRubyMethod(name = "handle_internal_event", required = 1)
    public IRubyObject handleInternalEvent(ThreadContext context, IRubyObject event) {
        Ruby rb = getRuntime();
        double timeNext = ((RubyNumeric) getInstanceVariable("@time_next")).getDoubleValue();
        double eventTime = ((RubyNumeric) ((RubyObject) event).getInstanceVariable("@time")).getDoubleValue();
        RubyObject model = (RubyObject) getInstanceVariable("@model");

        if (eventTime != timeNext) {
            rb.newRaiseException(DevsService.sBadSyncError, "time: " + eventTime + " should match time_next: " + timeNext);
        }

        RubyArray children = (RubyArray) callMethod(context, "imminent_children");
        RubyArray children_models = RubyArray.newArray(rb, children.getLength());
        for (int i = 0; i < children.getLength(); i++) {
            RubyObject child = (RubyObject) children.entry(i);
            children_models.append(child.getInstanceVariable("@model"));
        }
        RubyObject child_model = (RubyObject) model.callMethod(context, "select", children_models);
        //   debug "    selected #{child_model} in #{children_models.map(&:name)}"
        int index;
        for (index = 0; index < children.getLength(); index++) {
            if (child_model == children_models.entry(index)) {
                break;
            }
        }
        RubyObject child = (RubyObject) children.entry(index);

        child.callMethod(context, "dispatch", event);

        setInstanceVariable("@time_last", RubyFloat.newFloat(rb, eventTime));
        RubyNumeric tn = (RubyNumeric) callMethod("min_time_next");
        setInstanceVariable("@time_next", tn);
        //   debug "#{model} time_last: #{@time_last} | time_next: #{@time_next}"

        return rb.getNil();
    }
}