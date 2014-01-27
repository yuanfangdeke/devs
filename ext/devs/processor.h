#ifndef DEVS_PROCESSOR
#define DEVS_PROCESSOR

#include <devs.h>

void init_devs_processor();

VALUE devs_processor_ensure_input_message(VALUE self, VALUE msg);

extern VALUE cDEVSProcessor;

#endif
