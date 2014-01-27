#include <processor.h>

VALUE cDEVSProcessor;

static VALUE dispatch(VALUE self, VALUE event);

/*
* Document-class: DEVS::Simulator
*/
void
init_devs_processor() {
    VALUE klass = rb_define_class_under(mDEVS, "Processor", rb_cObject);
    cDEVSProcessor = klass;

    rb_define_method(klass, "dispatch", dispatch, 1);
    rb_define_protected_method(
        klass,
        "ensure_input_message",
        devs_processor_ensure_input_message,
        1
    );
}

/*
* call-seq:
*   dispatch(event)
*
* Handles an incoming event
*
* @param event [Event] the incoming event
* @raise [RuntimeError] if the processor cannot handle the given event
*   ({Event#type})
*/
static VALUE
dispatch(VALUE self, VALUE event) {
    VALUE result = Qnil;
    VALUE type = rb_iv_get(event, "@type");
    VALUE hsh = rb_iv_get(self, "@events_count");
    VALUE model = rb_iv_get(self, "@model");
    VALUE strategy = rb_iv_get(self, "@strategy");
    int count = NUM2INT(rb_hash_aref(hsh, type));

    rb_hash_aset(hsh, type, INT2NUM(count + 1));
    DEVS_DEBUG("%s received %s", RSTRING_PTR(rb_any_to_s(model)), RSTRING_PTR(rb_any_to_s(event)));

    if (strategy != Qnil) {
        result = rb_funcall(strategy, rb_intern("dispatch"), 2, self, event);
    } else {
        rb_raise(rb_eRuntimeError, "processor strategy not set");
    }

    return result;
}

/*
* call-seq:
*   ensure_input_message(msg)
*
* Ensure the given {Message} is an input {Port} and belongs to {#model}.
* @param message [Message] the incoming message
* @raise [InvalidPortHostError] if {#model} is not the correct host
*   for this message
* @raise [InvalidPortTypeError] if the {Message#port} is not an input port
*/
VALUE
devs_processor_ensure_input_message(VALUE self, VALUE msg) {
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
