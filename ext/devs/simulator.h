#ifndef DEVS_SIMULATOR
#define DEVS_SIMULATOR

#include <devs.h>

void init_devs_simulator();

VALUE devs_simulator_ensure_input_message(VALUE self, VALUE msg);

extern VALUE cDEVSSimulator;

#endif
