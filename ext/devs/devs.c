#include <devs.h>

VALUE mDEVS;
VALUE mDEVSClassic;

void
Init_devs() {
    mDEVS = rb_define_module("DEVS");
    mDEVSClassic = rb_define_module_under(mDEVS, "Classic");

    init_devs_simulator();
}
