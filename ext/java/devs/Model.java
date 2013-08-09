package devs;

import org.jruby.RubyObject;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;

@JRubyClass(name = "DEVS::Model")
public class Model extends RubyObject {
    public Model(Ruby rb, RubyClass klass) {
        super(rb, klass);
    }
}