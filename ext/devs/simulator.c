#include <simulator.h>

VALUE cDEVSSimulator;

static VALUE dispatch(VALUE self, VALUE event);

void
init_devs_simulator() {
    VALUE klass = rb_define_class_under(mDEVS, "Simulator", rb_cObject);
    cDEVSSimulator = klass;

    rb_define_method(klass, "dispatch", dispatch, 1);
    rb_define_protected_method(
        klass,
        "ensure_input_message",
        devs_simulator_ensure_input_message,
        1
    );
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
    int count = NUM2INT(rb_hash_aref(hsh, type));

    // VALUE str = rb_str_new2(RSTRING_PTR(rb_any_to_s(model)));
    // rb_str_cat2(str, " received ");
    // rb_str_cat2(str, RSTRING_PTR(rb_any_to_s(event)));

    rb_hash_aset(hsh, type, INT2NUM(count + 1));
//    rb_funcall(self, rb_intern("debug"), 1, str);
    DEVS_DEBUG("%s received %s", RSTRING_PTR(rb_any_to_s(model)), RSTRING_PTR(rb_any_to_s(event)));

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
            rb_id2name(SYM2ID(type))
        );
    }

    return result;
}

// Ensure the given {Message} is an input {Port} and belongs to {#model}.
// @param message [Message] the incoming message
// @raise [InvalidPortHostError] if {#model} is not the correct host
//   for this message
// @raise [InvalidPortTypeError] if the {Message#port} is not an input port
VALUE
devs_simulator_ensure_input_message(VALUE self, VALUE msg) {
    VALUE model = rb_iv_get(self, "@model");
    VALUE port = rb_iv_get(msg, "@port");
    VALUE host = rb_iv_get(port, "@host");
    VALUE ret;

    if (host != model) {
        rb_raise(
            cDEVSInvalidPortHostError,
            "the port associated with the given msg %s doesn't belong to this model",
            RSTRING_PTR(rb_any_to_s(msg))
        );
    }

    ret = rb_funcall(port, rb_intern("input?"), 0);
    if (ret == Qfalse) {
        rb_raise(
            cDEVSInvalidPortTypeError,
            "the port associated with the given msg %s should be an input port",
            RSTRING_PTR(rb_any_to_s(msg))
        );
    }

    return msg;
}
