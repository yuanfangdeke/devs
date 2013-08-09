package devs;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;

import devs.Model;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;

@JRubyClass(name = "DEVS::CoupledModel")
public class CoupledModel extends Model {
    public CoupledModel(Ruby rb, RubyClass klass) {
        super(rb, klass);
    }

    @JRubyMethod(name = "each_coupling", visibility = Visibility.PRIVATE)
    public IRubyObject eachCoupling(ThreadContext context, IRubyObject ary, IRubyObject port, Block block) {
        Ruby rb = getRuntime();
        RubyArray all = (RubyArray) ary;
        RubyArray couplings;

        if (port.isNil()) {
            couplings = all;
        } else {
            couplings = RubyArray.newArray(rb);

            for (int i = 0; i < all.getLength(); i++) {
                RubyObject coupling = (RubyObject) all.entry(i);
                IRubyObject portSrc = coupling.getInstanceVariable("@port_source");

                if (portSrc == port) {
                    couplings.append(coupling);
                }

                if (block.isGiven()) {
                    block.yield(context, coupling);
                }
            }
        }

        return couplings;
    }
}