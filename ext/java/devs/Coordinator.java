package devs;

import org.jruby.*;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyNumeric;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.RubyFloat;
import devs.Simulator;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import java.lang.Thread;

@JRubyClass(name = "DEVS::Coordinator")
public class Coordinator extends Simulator {
    public Coordinator(Ruby rb, RubyClass klass) {
        super(rb, klass);
    }

    /*
    * call-seq:
    *   imminent_children
    *
    * Returns a subset of {#children} including imminent children, e.g with
    * a time next value matching {#time_next}.
    *
    * @return [Array<Model>] the imminent children
    */
    @JRubyMethod(name="imminent_children")
    public IRubyObject imminentChildren(ThreadContext context) {
        RubyArray children = (RubyArray) getInstanceVariable("@children");
        RubyArray imminent = RubyArray.newArray(getRuntime());
        double timeNext = ((RubyNumeric) getInstanceVariable("@time_next")).getDoubleValue();

        for (int i = 0; i < children.getLength(); i++) {
            RubyObject child = (RubyObject) children.entry(i);
            double childTn = ((RubyNumeric) child.getInstanceVariable("@time_next")).getDoubleValue();

            if (timeNext == childTn) {
                imminent.append(child);
            }
        }

        return imminent;
    }

    /*
    * call-seq:
    *   min_time_next
    *
    * Returns the minimum time next in all children
    *
    * @return [Numeric] the min time next
    */
    @JRubyMethod(name = "min_time_next")
    public IRubyObject minTimeNext(ThreadContext context) {
        RubyArray children = (RubyArray) getInstanceVariable("@children");
        double min = Double.POSITIVE_INFINITY;

        for (int i = 0; i < children.getLength(); i++) {
            RubyObject child = (RubyObject) children.entry(i);
            double childTn = ((RubyNumeric) child.getInstanceVariable("@time_next")).getDoubleValue();

            if (childTn < min) {
                min = childTn;
            }
        }

        return RubyFloat.newFloat(getRuntime(), min);
    }

    /*
    * call-seq:
    *   max_time_last
    *
    * Returns the maximum time last in all children
    *
    * @return [Numeric] the max time last
    */
    @JRubyMethod(name = "max_time_last")
    public IRubyObject maxTimeLast(ThreadContext context) {
        RubyArray children = (RubyArray) getInstanceVariable("@children");
        double max = Double.NEGATIVE_INFINITY;

        for (int i = 0; i < children.getLength(); i++) {
            RubyObject child = (RubyObject) children.entry(i);
            double childTl = ((RubyNumeric) child.getInstanceVariable("@time_last")).getDoubleValue();

            if (childTl > max) {
                max = childTl;
            }
        }

        return RubyFloat.newFloat(getRuntime(), max);
    }
}
