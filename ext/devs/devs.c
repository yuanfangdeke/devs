#include <devs.h>

const float EPSILON = 0.00000001f;

ID DISPATCH_ID;

VALUE mDEVS;
VALUE mDEVSClassic;
VALUE mDEVSParallel;

VALUE cDEVSNoSuchChildError;
VALUE cDEVSBadSynchronisationError;
VALUE cDEVSInvalidPortTypeError;
VALUE cDEVSInvalidPortHostError;
VALUE cDEVSMessageAlreadySentError;
VALUE cDEVSFeedbackLoopError;

VALUE cDEVSEvent;
VALUE cDEVSMessage;

void
devs_debug(const char *file, int lines, char *fmt, ...) {
    int ret;
    char buffer[2048];
    va_list arg_ptr;

    va_start(arg_ptr, fmt);
    ret = vsprintf(buffer, fmt, arg_ptr);
    va_end(arg_ptr);

    fprintf(stdout, "%40s:%d\t %s\n", file, lines, buffer);
}

bool
fneq(const double a, const double b, const float epsilon) {
    const double absA = fabs(a);
    const double absB = fabs(b);
    const double diff = fabs(a - b);

    if (a == b) { // shortcut, handles infinities
        return true;
    } else if (a == 0 || b == 0 || diff < DBL_MIN) {
        // a or b is zero or both are extremely close to it
        // relative error is less meaningful here
        return diff < (epsilon * DBL_MIN);
    } else { // use relative error
        return diff / (absA + absB) < epsilon;
    }
}

void
Init_devs() {
    mDEVS = rb_define_module("DEVS");
    mDEVSClassic = rb_define_module_under(mDEVS, "Classic");
    mDEVSParallel = rb_define_module_under(mDEVS, "Parallel");

    cDEVSNoSuchChildError = rb_define_class_under(
        mDEVS,
        "NoSuchChildError",
        rb_eStandardError
    );
    cDEVSBadSynchronisationError = rb_define_class_under(
        mDEVS,
        "BadSynchronisationError",
        rb_eStandardError
    );
    cDEVSInvalidPortTypeError = rb_define_class_under(
        mDEVS,
        "InvalidPortTypeError",
        rb_eStandardError
    );
    cDEVSInvalidPortHostError = rb_define_class_under(
        mDEVS,
        "InvalidPortHostError",
        rb_eStandardError
    );
    cDEVSMessageAlreadySentError = rb_define_class_under(
        mDEVS,
        "MessageAlreadySentError",
        rb_eStandardError
    );
    cDEVSFeedbackLoopError = rb_define_class_under(
        mDEVS,
        "FeedbackLoopError",
        rb_eStandardError
    );
    cDEVSEvent = rb_define_class_under(mDEVS, "Event", rb_cObject);
    cDEVSMessage = rb_define_class_under(mDEVS, "Message", rb_cObject);

    DISPATCH_ID = rb_intern("dispatch");

    init_devs_processor();
    init_devs_coordinator();
    init_devs_coupled_model();
    init_devs_classic_simulator_impl();
    init_devs_classic_coordinator_impl();
    init_devs_classic_root_coordinator_strategy();
    init_devs_parallel_simulator_impl();
    init_devs_parallel_coordinator_impl();
    init_devs_parallel_root_coordinator_strategy();
}
