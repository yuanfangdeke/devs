#include <classic_simulator_strategy.h>

VALUE cDEVSClassicSimulatorStrategy;

static VALUE handle_init_event(VALUE self, VALUE event);
static VALUE handle_input_event(VALUE self, VALUE event);
static VALUE handle_internal_event(VALUE self, VALUE event);
static VALUE block_fetch_output(VALUE yo, VALUE ctx, int argc, VALUE argv[]);

void
init_devs_classic_simulator_strategy() {
    VALUE mod = rb_define_module_under(mDEVSClassic, "SimulatorStrategy");
    cDEVSClassicSimulatorStrategy = mod;

    rb_define_method(mod, "handle_init_event", handle_init_event, 1);
    rb_define_method(mod, "handle_input_event", handle_input_event, 1);
    rb_define_method(mod, "handle_internal_event", handle_internal_event, 1);
}

// Handles events of init type (i messages)
//
// @param event [Event] the init event
static VALUE
handle_init_event(VALUE self, VALUE event) {
    VALUE model = rb_iv_get(self, "@model");
    double time_next = NUM2DBL(rb_iv_get(self, "@time_next"));
    double ev_time = NUM2DBL(rb_iv_get(event, "@time"));

    rb_iv_set(model, "@time", rb_float_new(ev_time));
    rb_iv_set(self, "@time_last", rb_float_new(ev_time));
    double ta = NUM2DBL(rb_funcall(model, rb_intern("time_advance"), 0));
    rb_iv_set(self, "@time_next", rb_float_new(ev_time + ta));
    // debug "    time_last: #{@time_last} | time_next: #{@time_next}"
    DEVS_DEBUG("    time_last: %f | time_next: %f", ev_time, ev_time + ta);

    return Qnil;
}

// Handles input events (x messages)
//
// @param event [Event] the input event
// @raise [BadSynchronisationError] if the event time isn't in a proper
//   range, e.g isn't between {Simulator#time_last} and {Simulator#time_next}
static VALUE
handle_input_event(VALUE self, VALUE event) {
    VALUE model = rb_iv_get(self, "@model");
    VALUE msg = rb_iv_get(event, "@message");
    double time_last = NUM2DBL(rb_iv_get(self, "@time_last"));
    double time_next = NUM2DBL(rb_iv_get(self, "@time_next"));
    double ev_time = NUM2DBL(rb_iv_get(event, "@time"));

    if (ev_time >= time_last && ev_time <= time_next) {
        rb_iv_set(model, "@elapsed", rb_float_new(ev_time - time_last));
        // debug "    received #{event.message}"
        DEVS_DEBUG("received %s", RSTRING_PTR(rb_any_to_s(msg)));
        msg = devs_simulator_ensure_input_message(self, msg);
        OBJ_FREEZE(msg);
        rb_funcall(model, rb_intern("external_transition"), 1, msg);
        rb_iv_set(model, "@time", rb_float_new(ev_time));
        rb_iv_set(self, "@time_last", rb_float_new(ev_time));
        double ta = NUM2DBL(rb_funcall(model, rb_intern("time_advance"), 0));
        rb_iv_set(self, "@time_next", rb_float_new(ev_time + ta));
        DEVS_DEBUG("    time_last: %f | time_next: %f", ev_time, ev_time + ta);
    } else {
        rb_raise(
            mDEVSBadSynchronisationError,
            "time: %f should be between time_last: %f and time_next: %f",
            ev_time,
            time_last,
            time_next
        );
    }

    return Qnil;
}

// Handles star events (* messages)
//
// @param event [Event] the star event
// @raise [BadSynchronisationError] if the event time is not equal to
//   {Simulator#time_next}
static VALUE
handle_internal_event(VALUE self, VALUE event) {
    VALUE model = rb_iv_get(self, "@model");
    VALUE parent = rb_iv_get(self, "@parent");
    VALUE ret;
    double time_next = NUM2DBL(rb_iv_get(self, "@time_next"));
    double ev_time = NUM2DBL(rb_iv_get(event, "@time"));

    if (ev_time != time_next) {
        rb_raise(
            mDEVSBadSynchronisationError,
            "time: %f should match time_next: %f",
            ev_time,
            time_next
        );
    }

    ret = rb_funcall(model, rb_intern("fetch_output!"), 0);

    for (int i = 0; i < RARRAY_LEN(ret); i++) {
        VALUE msg = rb_ary_entry(ret, i);
        VALUE ev = rb_funcall(
            mDEVSEvent,
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

    DEVS_DEBUG("after fetch_output");

    rb_funcall(model, rb_intern("internal_transition"), 0);

    rb_iv_set(model, "@time", rb_float_new(ev_time));
    rb_iv_set(self, "@time_last", rb_float_new(ev_time));
    double ta = NUM2DBL(rb_funcall(model, rb_intern("time_advance"), 0));
    rb_iv_set(self, "@time_next", rb_float_new(ev_time + ta));
    // debug "#{model} time_last: #{@time_last} | time_next: #{@time_next}"
    DEVS_DEBUG("    time_last: %f | time_next: %f", ev_time, ev_time + ta);

    return Qnil;
}
