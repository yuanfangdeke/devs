package devs.classic;

import org.jruby.*;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyNumeric;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyMethod;
import org.jruby.anno.JRubyModule;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.RubySymbol;

import devs.DevsService;

@JRubyModule(name = "DEVS::Classic::RootCoordinatorStrategy")
public class RootCoordinatorStrategy extends RubyModule {
    public RootCoordinatorStrategy(Ruby rb, RubyClass klass) {
        super(rb, klass);
    }

    @JRubyMethod
    public IRubyObject run(ThreadContext context) {
        Ruby rb = getRuntime();
        RubyNumeric time = (RubyNumeric) getInstanceVariable("@time");
        RubyObject child = (RubyObject) getInstanceVariable("@child");
        double duration = ((RubyNumeric) getInstanceVariable("@duration")).getDoubleValue();

        IRubyObject event = DevsService.sEvent.newInstance(context, new IRubyObject[] {
                RubySymbol.newSymbol(rb, "init"),
                time
        }, null);

        child.callMethod(context, "dispatch", event);

        time = (RubyNumeric) child.callMethod(context, "time_next");
        setInstanceVariable("@time", time);

        while (time.getDoubleValue() < duration) {
            // debug "* Tick at: #{@time}, #{Time.now - @start_time} secs elapsed"

            event = DevsService.sEvent.newInstance(context, new IRubyObject[] {
                    RubySymbol.newSymbol(rb, "internal"),
                    time
            }, null);

            child.callMethod(context, "dispatch", event);

            time = (RubyNumeric) child.callMethod(context, "time_next");
            setInstanceVariable("@time", time);
        }

        return rb.getNil();
    }
}
