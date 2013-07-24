#include <devs.h>

VALUE mDEVS;
VALUE mDEVSClassic;

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

    init_devs_simulator();
}
