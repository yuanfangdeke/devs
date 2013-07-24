#include <simulator.h>

VALUE cDEVSSimulator;

static VALUE dispatch(VALUE self, VALUE event);

void
init_devs_simulator() {
    VALUE klass = rb_define_class_under(mDEVS, "Simulator", rb_cObject);
    cDEVSSimulator = klass;

    rb_define_method(klass, "dispatch", dispatch, 1);
}

// Handles an incoming event
//
// @param event [Event] the incoming event
// @raise [RuntimeError] if the processor cannot handle the given event
//   ({Event#type})
static VALUE
dispatch(VALUE self, VALUE event) {
    VALUE result = Qnil;
    VALUE type = rb_ivar_get(event, rb_intern("@type"));
    VALUE hsh = rb_ivar_get(self, rb_intern("@events_count"));
    VALUE model = rb_ivar_get(self, rb_intern("@model"));
    int count = FIX2INT(rb_hash_aref(hsh, type));
    VALUE str = rb_str_new2(StringValuePtr(model));
    rb_str_cat2(str, " received ");
    rb_str_cat2(str, StringValuePtr(event));

    rb_hash_aset(hsh, type, INT2FIX(count + 1));
    rb_funcall(self, rb_intern("debug"), str);

    char m[80];
    strcat(m, "handle_");
    strcat(m, RSTRING_PTR(type));
    strcat(m, "_event");

    ID handler = rb_intern(m);

    if (rb_respond_to(self, handler)) {
        result = rb_funcall(self, handler, 1, event);
    } else {
        rb_raise(
            rb_eRuntimeError,
            "simulator doesn't handle %s events",
            RSTRING_PTR(m)
        );
    }

    return result;
}
