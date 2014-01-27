#include <classic_simulator_strategy.h>

VALUE cDEVSClassicSimulatorStrategy;

static VALUE dispatch(VALUE self, VALUE processor, VALUE event);
static VALUE handle_init_event(VALUE processor, VALUE event);
static VALUE handle_input_event(VALUE processor, VALUE event);
static VALUE handle_internal_event(VALUE processor, VALUE event);

/*
* Document-module: DEVS::Classic::SimulatorStrategy
*/
void
init_devs_classic_simulator_strategy() {
    VALUE mod = rb_define_module_under(mDEVSClassic, "SimulatorStrategy");
    cDEVSClassicSimulatorStrategy = mod;

    rb_define_module_function(mod, "dispatch", dispatch, 2);
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
dispatch(VALUE self, VALUE processor, VALUE event) {
    ID type = SYM2ID(rb_iv_get(event, "@type"));
    VALUE res;

    if (type == rb_intern("init")) {
        res = handle_init_event(processor, event);
    } else if (type == rb_intern("input")) {
        res = handle_input_event(processor, event);
    } else if (type == rb_intern("internal")) {
        res = handle_internal_event(processor, event);
    } else {
        rb_raise(
            rb_eRuntimeError,
            "ClassicSimulatorStrategy doesn't handle %s events",
            rb_id2name(SYM2ID(type))
        );
    }

    return res;
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
handle_init_event(VALUE processor, VALUE event) {
    VALUE model = rb_iv_get(processor, "@model");
    double time_next = NUM2DBL(rb_iv_get(processor, "@time_next"));
    double ev_time = NUM2DBL(rb_iv_get(event, "@time"));

    rb_iv_set(model, "@time", rb_float_new(ev_time));
    rb_iv_set(processor, "@time_last", rb_float_new(ev_time));

    double ta = NUM2DBL(rb_funcall(model, rb_intern("time_advance"), 0));
    rb_iv_set(processor, "@time_next", rb_float_new(ev_time + ta));

    // debug "    time_last: #{@time_last} | time_next: #{@time_next}"
    DEVS_DEBUG("    time_last: %f | time_next: %f", ev_time, ev_time + ta);

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
handle_input_event(VALUE processor, VALUE event) {
    VALUE model = rb_iv_get(processor, "@model");
    VALUE msg = rb_iv_get(event, "@message");
    double time_last = NUM2DBL(rb_iv_get(processor, "@time_last"));
    double time_next = NUM2DBL(rb_iv_get(processor, "@time_next"));
    double ev_time = NUM2DBL(rb_iv_get(event, "@time"));

    if (ev_time >= time_last && ev_time <= time_next) {
        rb_iv_set(model, "@elapsed", rb_float_new(ev_time - time_last));
        // debug "    received #{event.message}"
        DEVS_DEBUG("received %s", RSTRING_PTR(rb_any_to_s(msg)));
        msg = rb_funcall(processor, rb_intern("ensure_input_message"), 1, msg);
        // msg = devs_simulator_ensure_input_message(processor, msg);
        OBJ_FREEZE(msg);
        rb_funcall(model, rb_intern("external_transition"), 1, rb_ary_new3(1, msg));

        rb_iv_set(model, "@time", rb_float_new(ev_time));
        rb_iv_set(processor, "@time_last", rb_float_new(ev_time));
        double ta = NUM2DBL(rb_funcall(model, rb_intern("time_advance"), 0));
        rb_iv_set(processor, "@time_next", rb_float_new(ev_time + ta));
        DEVS_DEBUG("    time_last: %f | time_next: %f", ev_time, ev_time + ta);
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
handle_internal_event(VALUE processor, VALUE event) {
    VALUE model = rb_iv_get(processor, "@model");
    VALUE parent = rb_iv_get(processor, "@parent");
    VALUE ret;
    double time_next = NUM2DBL(rb_iv_get(processor, "@time_next"));
    double ev_time = NUM2DBL(rb_iv_get(event, "@time"));
    int i;

    if (ev_time != time_next) {
        rb_raise(
            cDEVSBadSynchronisationError,
            "time: %f should match time_next: %f",
            ev_time,
            time_next
        );
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
            msg
        );
        // debug "    sent #{message}"
        DEVS_DEBUG("sent %s", RSTRING_PTR(rb_any_to_s(msg)));
        rb_funcall(parent, rb_intern("dispatch"), 1, ev);
    }

    rb_funcall(model, rb_intern("internal_transition"), 0);

    rb_iv_set(model, "@time", rb_float_new(ev_time));
    rb_iv_set(processor, "@time_last", rb_float_new(ev_time));
    double ta = NUM2DBL(rb_funcall(model, rb_intern("time_advance"), 0));
    rb_iv_set(processor, "@time_next", rb_float_new(ev_time + ta));
    // debug "#{model} time_last: #{@time_last} | time_next: #{@time_next}"
    DEVS_DEBUG("    time_last: %f | time_next: %f", ev_time, ev_time + ta);

    return Qnil;
}
