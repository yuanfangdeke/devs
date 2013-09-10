#ifndef DEVS_NATIVE
#define DEVS_NATIVE

#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include <ruby.h>

#include <simulator.h>
#include <coordinator.h>
#include <coupled_model.h>
#include <classic_simulator_strategy.h>
#include <classic_coordinator_strategy.h>
#include <classic_root_coordinator_strategy.h>

extern VALUE mDEVS;
extern VALUE mDEVSClassic;

extern VALUE cDEVSNoSuchChildError;
extern VALUE cDEVSBadSynchronisationError;
extern VALUE cDEVSInvalidPortTypeError;
extern VALUE cDEVSInvalidPortHostError;
extern VALUE cDEVSMessageAlreadySentError;
extern VALUE cDEVSFeedbackLoopError;

extern VALUE cDEVSEvent;
extern VALUE cDEVSMessage;

void devs_debug(const char *file, int lines, char *fmt, ...);

// #define DEBUG

#ifdef DEBUG
#define DEVS_DEBUG(fmt...) devs_debug(__FILE__, __LINE__, fmt);
#else
#define DEVS_DEBUG(fmt...)
#endif

#ifndef RSTRING_PTR
#define RSTRING_PTR(s) (RSTRING(s)->ptr)
#endif

#ifndef RSTRING_LEN
#define RSTRING_LEN(s) (RSTRING(s)->len)
#endif

#ifndef RARRAY_PTR
#define RARRAY_PTR(a) RARRAY(a)->ptr
#endif

#ifndef RARRAY_LEN
#define RARRAY_LEN(a) RARRAY(a)->len
#endif

#ifndef INFINITY
#define INFINITY 1.0 / 0.0
#endif

#endif
