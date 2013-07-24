#ifndef DEVS_NATIVE
#define DEVS_NATIVE

#include <stdlib.h>
#include <string.h>

#include <ruby.h>

#include <simulator.h>

extern VALUE mDEVS;
extern VALUE mDEVSClassic;

void devs_debug(const char *file, int lines, char *fmt, ...);

#define DEBUG

#ifdef DEBUG
#define DEVS_DEBUG(fmt...) devs_debug(__FILE__, __LINE__, fmt);
#else
#define DEVS_DEBUG(p)
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

#endif
