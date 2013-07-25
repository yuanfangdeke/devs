#include <devs.h>

VALUE mDEVS;
VALUE mDEVSClassic;

VALUE mDEVSNoSuchChildError;
VALUE mDEVSBadSynchronisationError;
VALUE mDEVSInvalidPortTypeError;
VALUE mDEVSInvalidPortHostError;
VALUE mDEVSMessageAlreadySentError;
VALUE mDEVSFeedbackLoopError;

VALUE mDEVSEvent;

void
devs_debug(const char *file, int lines, char *fmt, ...) {
    if (strlen(fmt) < 255) {
        char buffer[255];
        va_list arg_ptr;

        va_start(arg_ptr, fmt);
        vsprintf(buffer, fmt, arg_ptr);
        va_end(arg_ptr);

        fprintf(stdout, "devs-ext: %s:%d - %s\n", file, lines, buffer);
    }
}

void
Init_devs() {
    mDEVS = rb_define_module("DEVS");
    mDEVSClassic = rb_define_module_under(mDEVS, "Classic");
    mDEVSNoSuchChildError = rb_define_class_under(
        mDEVS,
        "NoSuchChildError",
        rb_eStandardError
    );
    mDEVSBadSynchronisationError = rb_define_class_under(
        mDEVS,
        "BadSynchronisationError",
        rb_eStandardError
    );
    mDEVSInvalidPortTypeError = rb_define_class_under(
        mDEVS,
        "InvalidPortTypeError",
        rb_eStandardError
    );
    mDEVSInvalidPortHostError = rb_define_class_under(
        mDEVS,
        "InvalidPortHostError",
        rb_eStandardError
    );
    mDEVSMessageAlreadySentError = rb_define_class_under(
        mDEVS,
        "MessageAlreadySentError",
        rb_eStandardError
    );
    mDEVSFeedbackLoopError = rb_define_class_under(
        mDEVS,
        "FeedbackLoopError",
        rb_eStandardError
    );
    mDEVSEvent = rb_define_class_under(mDEVS, "Event", rb_cObject);

    init_devs_simulator();
    init_devs_classic_simulator_strategy();
}
