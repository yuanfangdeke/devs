package devs.classic;

import org.jruby.*;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyFloat;
import org.jruby.RubyModule;
import org.jruby.RubyNumeric;
import org.jruby.RubyArray;
import org.jruby.RubyObject;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyMethod;
import org.jruby.anno.JRubyModule;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.ThreadContext;

import devs.DevsService;

@JRubyModule(name="DEVS::Classic::SimulatorStrategy")
public class SimulatorStrategy extends RubyModule {
    public SimulatorStrategy(Ruby rb, RubyClass klass) {
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
    @JRubyMethod(name="handle_init_event", required=1)
    public IRubyObject handleInitEvent(ThreadContext context, IRubyObject event) {
        Ruby rb = getRuntime();
        IRubyObject model = getInstanceVariable("@model");
        double timeNext = ((RubyNumeric) getInstanceVariable("@time_next")).getDoubleValue();
        RubyNumeric eventTime = ((RubyNumeric) ((RubyObject) event).getInstanceVariable("@time"));

        ((RubyObject) model).setInstanceVariable("@time", eventTime);
        setInstanceVariable("@time_last", eventTime);

        double ta = ((RubyNumeric) model.callMethod(context, "time_advance")).getDoubleValue();
        setInstanceVariable("@time_next", RubyFloat.newFloat(rb, eventTime.getDoubleValue() + ta));
        //DEVS_DEBUG("    time_last: %f | time_next: %f", ev_time, ev_time + ta);

        return rb.getNil();
    }

    /*
    * call-seq:
    *   handle_input_event(event)
    *
    * Handles input events (x messages)
    *
    * @param event [Event] the input event
    * @raise [BadSynchronisationError] if the event time isn't in a proper
    *   range, e.g isn't between {Simulator#time_last} and {Simulator#time_next}
    */
    @JRubyMethod(name="handle_input_event", required=1)
    public IRubyObject handleInputEvent(ThreadContext context, IRubyObject event) {
        Ruby rb = getRuntime();
        RubyObject model = (RubyObject) getInstanceVariable("@model");
        IRubyObject msg = ((RubyObject) event).getInstanceVariable("@message");
        double timeLast = ((RubyNumeric) getInstanceVariable("@time_last")).getDoubleValue();
        double timeNext = ((RubyNumeric) getInstanceVariable("@time_next")).getDoubleValue();
        double eventTime = ((RubyNumeric) ((RubyObject) event).getInstanceVariable("@time")).getDoubleValue();

        if (eventTime >= timeLast && eventTime <= timeNext) {
            model.setInstanceVariable("@elapsed", RubyFloat.newFloat(rb, eventTime - timeLast));
            // debug "    received #{event.message}"
            msg = callMethod(context, "ensure_input_message", msg);
            msg.setFrozen(true);
            model.callMethod(context, "external_transition", msg);

            model.setInstanceVariable("@time", RubyFloat.newFloat(rb, eventTime));
            setInstanceVariable("@time_last", RubyFloat.newFloat(rb, eventTime));
            double ta = ((RubyNumeric) model.callMethod(context, "time_advance")).getDoubleValue();
            setInstanceVariable("@time_next", RubyFloat.newFloat(rb, eventTime + ta));
            // DEVS_DEBUG("    time_last: %f | time_next: %f", ev_time, ev_time + ta);
        } else {
            rb.newRaiseException(DevsService.sBadSyncError, "time: " + eventTime + " should be between time_last: " +
                    timeLast + " and time_next: " + timeNext);
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
    *   {Simulator#time_next}
    */
    @JRubyMethod(name="handle_internal_event", required=1)
    public IRubyObject handleInternalEvent(ThreadContext context, IRubyObject event) {
        Ruby rb = getRuntime();
        RubyObject model = (RubyObject) getInstanceVariable("@model");
        RubyObject parent = (RubyObject) getInstanceVariable("@parent");
        double timeNext = ((RubyNumeric) getInstanceVariable("@time_next")).getDoubleValue();
        double eventTime = ((RubyNumeric) ((RubyObject) event).getInstanceVariable("@time")).getDoubleValue();

        if (eventTime != timeNext) {
            rb.newRaiseException(DevsService.sBadSyncError,
                    "time: " + eventTime + " should match time_next: " + timeNext);
        }

        RubyArray ret = (RubyArray) model.callMethod(context, "fetch_output!");

        for (int i = 0; i < ret.getLength(); i++) {
            IRubyObject msg = ret.entry(i);
            IRubyObject ev = DevsService.sEvent.newInstance(context, new IRubyObject[] {
                    RubySymbol.newSymbol(rb, "output"),
                    RubyFloat.newFloat(rb, eventTime),
                    msg
            }, null);
            // debug "    sent #{message}"
            parent.callMethod(context, "dispatch", event);
        }

        model.callMethod(context, "internal_transition");

        model.setInstanceVariable("@time", RubyFloat.newFloat(rb, eventTime));
        setInstanceVariable("@time_last", RubyFloat.newFloat(rb, eventTime));
        double ta = ((RubyNumeric) model.callMethod(context, "time_advance")).getDoubleValue();
        setInstanceVariable("@time_next", RubyFloat.newFloat(rb, eventTime + ta));
        // DEVS_DEBUG("    time_last: %f | time_next: %f", ev_time, ev_time + ta);

        return rb.getNil();
    }
}