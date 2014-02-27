#include <processor.h>

VALUE cDEVSProcessor;

static VALUE dispatch(VALUE self, VALUE event);
static VALUE ensure_input_message(VALUE self, VALUE msg);

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
        ensure_input_message,
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
    static const char* prefix = "handle_";
    static const char* suffix = "_event";
    VALUE type = rb_iv_get(event, "@type");
    VALUE hsh = rb_iv_get(self, "@events_count");
    VALUE model = rb_iv_get(self, "@model");
    long count = NUM2INT(rb_hash_aref(hsh, type));

    rb_hash_aset(hsh, type, INT2NUM(count + 1));

#ifdef DEBUG
    DEVS_DEBUG("* %s received %s",
        RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)),
        RSTRING_PTR(rb_funcall(event, rb_intern("to_s"), 0))
    );
#endif

    const char* type_name = rb_id2name(SYM2ID(type));
    char str[strlen(prefix) + strlen(suffix) + strlen(type_name) + 1];
    strcpy(str, prefix);
    strcat(str, type_name);
    strcat(str, suffix);

    return rb_funcall(self, rb_intern(str), 1, event);
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
static VALUE
ensure_input_message(VALUE self, VALUE msg) {
    VALUE model = rb_iv_get(self, "@model");
    VALUE port = rb_iv_get(msg, "@port");
    VALUE host = rb_iv_get(port, "@host");
    VALUE ret;

    if (host != model) {
        rb_raise(
            cDEVSInvalidPortHostError,
            "the port %s associated with the given msg %s doesn't belong to model %s",
            RSTRING_PTR(rb_funcall(port, rb_intern("to_s"), 0)),
            RSTRING_PTR(rb_funcall(msg, rb_intern("to_s"), 0)),
            RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0))
        );
    }

    ret = rb_funcall(port, rb_intern("input?"), 0);
    if (ret == Qfalse) {
        rb_raise(
            cDEVSInvalidPortTypeError,
            "the port %s associated with the given msg %s should be an input port",
            RSTRING_PTR(rb_funcall(port, rb_intern("to_s"), 0)),
            RSTRING_PTR(rb_funcall(msg, rb_intern("to_s"), 0))
        );
    }

    return msg;
}
