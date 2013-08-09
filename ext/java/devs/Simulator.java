package devs;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyHash;
import org.jruby.RubyInteger;
import org.jruby.RubyNumeric;
import org.jruby.RubyObject;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;

import devs.DevsService;

@JRubyClass(name = "DEVS::Simulator")
public class Simulator extends RubyObject {
    public Simulator(Ruby rb, RubyClass klass) {
        super(rb, klass);
    }

    @JRubyMethod
    public IRubyObject dispatch(ThreadContext context, IRubyObject event) {
        Ruby rb = context.getRuntime();
        IRubyObject result = rb.getNil();
        RubySymbol type = (RubySymbol) ((RubyObject)event).getInstanceVariable("@type");
        RubyHash hsh = (RubyHash) getInstanceVariable("@events_count");
        IRubyObject model = getInstanceVariable("@model");
        long count = ((RubyInteger) hsh.get(type)).getLongValue();

        hsh.fastASet(type, RubyFixnum.newFixnum(rb, count + 1));
        //DEVS_DEBUG("%s received %s", RSTRING_PTR(rb_any_to_s(model)), RSTRING_PTR(rb_any_to_s(event)));

        String handler = "handle_" + type.asJavaString() + "_event";

        if (this.respondsTo(handler)) {
            result = callMethod(handler, event);
        } else {
            rb.newRuntimeError("simulator doesn't handle " + type.asJavaString() + " events");
        }

        return result;
    }

    @JRubyMethod(name = "ensure_input_message", visibility = Visibility.PROTECTED)
    public IRubyObject ensureInputMessage(ThreadContext context, IRubyObject msg) {
        Ruby rb = context.getRuntime();
        RubyObject model = (RubyObject) getInstanceVariable("@model");
        RubyObject port = (RubyObject) ((RubyObject) msg).getInstanceVariable("@port");
        RubyObject host = (RubyObject) port.getInstanceVariable("@host");
        IRubyObject ret;

        if (host != model) {
            rb.newRaiseException(DevsService.sInvalidPortHostError,
                    "the port associated with the given msg " + msg.asJavaString() + " doesn't belong to this model");
        }

        ret = port.callMethod("input?");
        if (ret == rb.getFalse()) {
            rb.newRaiseException(DevsService.sInvalidPortTypeError,
                    "the port associated with the given msg " + msg.asJavaString() + " should be an input port");
        }

        return msg;
    }
}
