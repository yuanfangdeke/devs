#include <classic_simulator_impl.h>

VALUE cDEVSClassicSimulatorImpl;

static VALUE handle_init_event(VALUE self, VALUE event);
static VALUE handle_input_event(VALUE self, VALUE event);
static VALUE handle_internal_event(VALUE self, VALUE event);

/*
* Document-module: DEVS::Classic::SimulatorImpl
*/
void
init_devs_classic_simulator_impl() {
    VALUE mod = rb_define_module_under(mDEVSClassic, "SimulatorImpl");
    cDEVSClassicSimulatorImpl = mod;

    rb_define_method(mod, "handle_init_event", handle_init_event, 1);
    rb_define_method(mod, "handle_input_event", handle_input_event, 1);
    rb_define_method(mod, "handle_internal_event", handle_internal_event, 1);
}

/*
* call-seq:
*   handle_init_event(event)
*
* Handles events of init type (i messages)
*
* @param event [Event] the init event
*/
static VALUE
handle_init_event(VALUE self, VALUE event) {
    VALUE model = rb_iv_get(self, "@model");
    double time_next = NUM2DBL(rb_iv_get(self, "@time_next"));
    double ev_time = NUM2DBL(rb_iv_get(event, "@time"));

    rb_iv_set(model, "@time", rb_float_new(ev_time));
    rb_iv_set(self, "@time_last", rb_float_new(ev_time));

    double ta = NUM2DBL(rb_funcall(model, rb_intern("time_advance"), 0));
    rb_iv_set(self, "@time_next", rb_float_new(ev_time + ta));

#ifdef DEBUG
        DEVS_DEBUG("%s time_last: %f | time_next: %f",
            RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)),
            ev_time,
            ev_time + ta);
#endif

    return Qnil;
}

/*
* call-seq:
*   handle_input_event(event)
*
* Handles input events (x messages)
*
* @param event [Event] the input event
* @raise [BadSynchronisationError] if the event time isn't in a proper
*   range, e.g isn't between {Simulator#time_last} and {Simulator#time_next}
*/
static VALUE
handle_input_event(VALUE self, VALUE event) {
    VALUE model = rb_iv_get(self, "@model");
    VALUE msg = rb_ary_entry(rb_iv_get(event, "@bag"), 0);
    double time_last = NUM2DBL(rb_iv_get(self, "@time_last"));
    double time_next = NUM2DBL(rb_iv_get(self, "@time_next"));
    double ev_time = NUM2DBL(rb_iv_get(event, "@time"));

    if (ev_time >= time_last && ev_time <= time_next) {
        rb_iv_set(model, "@elapsed", rb_float_new(ev_time - time_last));

        msg = rb_funcall(self, rb_intern("ensure_input_message"), 1, msg);
        OBJ_FREEZE(msg);
        rb_funcall(model, rb_intern("external_transition"), 1, rb_ary_new3(1, msg));

        rb_iv_set(model, "@time", rb_float_new(ev_time));
        rb_iv_set(self, "@time_last", rb_float_new(ev_time));
        double ta = NUM2DBL(rb_funcall(model, rb_intern("time_advance"), 0));
        rb_iv_set(self, "@time_next", rb_float_new(ev_time + ta));

#ifdef DEBUG
        DEVS_DEBUG("%s time_last: %f | time_next: %f",
            RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)),
            ev_time,
            ev_time + ta);
#endif
    } else {
        rb_raise(
            cDEVSBadSynchronisationError,
            "time: %f should be between time_last: %f and time_next: %f",
            ev_time,
            time_last,
            time_next
        );
    }

    return Qnil;
}

/*
* call-seq:
*   handle_internal_event(event)
*
* Handles star events (* messages)
*
* @param event [Event] the star event
* @raise [BadSynchronisationError] if the event time is not equal to
*   {Simulator#time_next}
*/
static VALUE
handle_internal_event(VALUE self, VALUE event) {
    VALUE model = rb_iv_get(self, "@model");
    VALUE parent = rb_iv_get(self, "@parent");
    VALUE ret;
    double time_next = NUM2DBL(rb_iv_get(self, "@time_next"));
    double ev_time = NUM2DBL(rb_iv_get(event, "@time"));
    long i;

    if (ev_time != time_next) {
        rb_raise(
            cDEVSBadSynchronisationError,
            "time: %f should match time_next: %f",
            ev_time,
            time_next
        );

        return Qnil;
    }

    ret = rb_funcall(model, rb_intern("fetch_output!"), 0);

    for (i = 0; i < RARRAY_LEN(ret); i++) {
        VALUE msg = rb_ary_entry(ret, i);
        VALUE ev = rb_funcall(
            cDEVSEvent,
            rb_intern("new"),
            3,
            ID2SYM(rb_intern("output")),
            rb_float_new(ev_time),
            rb_ary_new_from_args(1, msg)
        );

#ifdef DEBUG
        DEVS_DEBUG("%s sent %s",
            RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)),
            RSTRING_PTR(rb_funcall(msg, rb_intern("to_s"), 0)));
#endif

        rb_funcall(parent, DISPATCH_ID, 1, ev);
    }

    rb_funcall(model, rb_intern("internal_transition"), 0);

    rb_iv_set(model, "@time", rb_float_new(ev_time));
    rb_iv_set(self, "@time_last", rb_float_new(ev_time));
    double ta = NUM2DBL(rb_funcall(model, rb_intern("time_advance"), 0));
    rb_iv_set(self, "@time_next", rb_float_new(ev_time + ta));

#ifdef DEBUG
    DEVS_DEBUG("%s time_last: %f | time_next: %f",
        RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)),
        ev_time,
        ev_time + ta);
#endif

    return Qnil;
}
