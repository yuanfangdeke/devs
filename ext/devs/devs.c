#include <devs.h>

VALUE mDEVS;
VALUE mDEVSClassic;

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

void
Init_devs() {
    mDEVS = rb_define_module("DEVS");
    mDEVSClassic = rb_define_module_under(mDEVS, "Classic");
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

    init_devs_processor();
    init_devs_coordinator();
    init_devs_coupled_model();
    init_devs_classic_simulator_impl();
    init_devs_classic_coordinator_impl();
    init_devs_classic_root_coordinator_strategy();
}
