package devs;

import java.io.IOException;
import java.lang.Object;

import devs.classic.SimulatorStrategy;
import devs.classic.RootCoordinatorStrategy;
import devs.classic.CoordinatorStrategy;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.BasicLibraryService;

public class DevsService implements BasicLibraryService {
    public static RubyClass sNoSuchChildError;
    public static RubyClass sBadSyncError;
    public static RubyClass sInvalidPortTypeError;
    public static RubyClass sInvalidPortHostError;
    public static RubyClass sMsgAlreadySentError;
    public static RubyClass sFeedbackLoopError;

    public static RubyClass sEvent;
    public static RubyClass sMessage;

    public boolean basicLoad(Ruby rb) throws IOException {
        RubyModule devs = rb.defineModule("DEVS");
        RubyModule classicModule = devs.defineModuleUnder("Classic");

        defineErrors(rb, devs);

        sEvent = devs.defineOrGetClassUnder("Event", rb.getObject());
        sMessage = devs.defineOrGetClassUnder("Message", rb.getObject());

        RubyClass simulator = devs.defineOrGetClassUnder("Simulator", rb.getObject());
        simulator.defineAnnotatedMethods(Simulator.class);

        RubyClass coordinator = devs.defineOrGetClassUnder("Coordinator", simulator);
        coordinator.defineAnnotatedMethods(Coordinator.class);

        RubyClass model = devs.defineOrGetClassUnder("Model", rb.getObject());
        RubyClass coupledModel = devs.defineOrGetClassUnder("CoupledModel", model);
        coupledModel.defineAnnotatedMethods(CoupledModel.class);

        RubyModule simulatorStrategy = classicModule.defineModuleUnder("SimulatorStrategy");
        simulatorStrategy.defineAnnotatedMethods(SimulatorStrategy.class);

        RubyModule coordinatorStrategy = classicModule.defineModuleUnder("CoordinatorStrategy");
        coordinatorStrategy.defineAnnotatedMethods(CoordinatorStrategy.class);

        RubyModule rootCoordinatorStrategy = classicModule.defineModuleUnder("RootCoordinatorStrategy");
        rootCoordinatorStrategy.defineAnnotatedMethods(RootCoordinatorStrategy.class);

        return true;
    }

    private void defineErrors(Ruby rb, RubyModule devs) {
        RubyClass stErr = rb.getStandardError();
        ObjectAllocator stErrAllocator = stErr.getAllocator();

        sNoSuchChildError = devs.defineClassUnder("NoSuchChildError", stErr, stErrAllocator);
        sBadSyncError = devs.defineClassUnder("BadSynchronisationError", stErr, stErrAllocator);
        sInvalidPortTypeError = devs.defineClassUnder("InvalidPortTypeError", stErr, stErrAllocator);
        sInvalidPortHostError = devs.defineClassUnder("InvalidPortHostError", stErr, stErrAllocator);
        sMsgAlreadySentError = devs.defineClassUnder("MessageAlreadySentError", stErr, stErrAllocator);
        sFeedbackLoopError = devs.defineClassUnder("FeedbackLoopError", stErr, stErrAllocator);
    }
}
