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
    VALUE type = rb_iv_get(event, "@type");
    VALUE hsh = rb_iv_get(self, "@events_count");
    VALUE model = rb_iv_get(self, "@model");
    int count = FIX2INT(rb_hash_aref(hsh, type));

    // VALUE str = rb_str_new2(RSTRING_PTR(rb_any_to_s(model)));
    // rb_str_cat2(str, " received ");
    // rb_str_cat2(str, RSTRING_PTR(rb_any_to_s(event)));

    rb_hash_aset(hsh, type, INT2FIX(count + 1));
//    rb_funcall(self, rb_intern("debug"), str);

    VALUE m = rb_str_new2("handle_");
    rb_str_cat2(m, rb_id2name(SYM2ID(type)));
    rb_str_cat2(m, "_event");

    ID handler = rb_intern(RSTRING_PTR(m));
    if (rb_respond_to(self, handler)) {
        result = rb_funcall(self, handler, 1, event);
    } else {
        rb_raise(
            rb_eRuntimeError,
            "simulator doesn't handle %s events",
            RSTRING_PTR(rb_any_to_s(type))
        );
    }

    return result;
}
