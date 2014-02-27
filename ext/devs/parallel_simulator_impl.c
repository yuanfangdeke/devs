#include <parallel_simulator_impl.h>

VALUE cDEVSParallelSimulatorImpl;

static VALUE handle_collect_event(VALUE self, VALUE event);
static VALUE handle_input_event(VALUE self, VALUE event);
static VALUE handle_internal_event(VALUE self, VALUE event);
static VALUE frozen_bag(VALUE self, VALUE bag);

/*
* Document-module: DEVS::Parallel::SimulatorImpl
*/
void
init_devs_parallel_simulator_impl() {
    VALUE mod = rb_define_module_under(mDEVSParallel, "SimulatorImpl");
    cDEVSParallelSimulatorImpl = mod;

    rb_define_method(mod, "handle_input_event", handle_input_event, 1);
    rb_define_method(mod, "handle_internal_event", handle_internal_event, 1);
    rb_define_method(mod, "handle_collect_event", handle_collect_event, 1);
}

/*
* call-seq:
*   handle_collect_event(event)
*
* Handles events of collect type (@ messages)
*
* @param event [Event] the collect event
*/
static VALUE
handle_collect_event(VALUE self, VALUE event) {
    VALUE model = rb_iv_get(self, "@model");
    VALUE parent = rb_iv_get(self, "@parent");
    double time_next = NUM2DBL(rb_iv_get(self, "@time_next"));
    double ev_time = NUM2DBL(rb_iv_get(event, "@time"));
    VALUE bag;

    if (fneq(ev_time, time_next, EPSILON)) {
        bag = rb_funcall(model, rb_intern("fetch_output!"), 0);
        if (RARRAY_LEN(bag) > 0) {
            VALUE ev = rb_funcall(
                cDEVSEvent,
                rb_intern("new"),
                3,
                ID2SYM(rb_intern("output")),
                rb_float_new(ev_time),
                bag
            );
#ifdef DEBUG
            DEVS_DEBUG("\t\t%s sends %s",
                RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)),
                RSTRING_PTR(rb_funcall(ev, rb_intern("to_s"), 0)));
#endif
            rb_funcall(parent, DISPATCH_ID, 1, ev);
        }
    } else {
        rb_raise(
            cDEVSBadSynchronisationError,
            "time: %f should match time_next: %f",
            ev_time,
            time_next
        );
    }

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
    VALUE bag = rb_iv_get(self, "@bag");
    VALUE sub_bag = rb_iv_get(event, "@bag");
    long i;

    for (i = 0; i < RARRAY_LEN(sub_bag); i++) {
        VALUE msg = rb_ary_entry(sub_bag, i);
        rb_ary_push(bag, msg);
#ifdef DEBUG
        DEVS_DEBUG("\t\t%s adding %s to bag",
            RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)),
            RSTRING_PTR(rb_funcall(msg, rb_intern("to_s"), 0))
        );
#endif
    }

    return Qnil;
}

/*
* call-seq:
*   handle_internal_event(event)
*
* Handles internal events (* messages)
*
* @param event [Event] the star event
* @raise [BadSynchronisationError] if the event time is not equal to
*   {Simulator#time_next}
*/
static VALUE
handle_internal_event(VALUE self, VALUE event) {
    VALUE model = rb_iv_get(self, "@model");
    VALUE parent = rb_iv_get(self, "@parent");
    VALUE bag = rb_iv_get(self, "@bag");
    double time_next = NUM2DBL(rb_iv_get(self, "@time_next"));
    double time_last = NUM2DBL(rb_iv_get(self, "@time_last"));
    double ev_time = NUM2DBL(rb_iv_get(event, "@time"));
    bool synced = ev_time >= time_last && ev_time <= time_next;

    if (fneq(ev_time, time_next, EPSILON)) {
        if (RARRAY_LEN(bag) > 0) {
#ifdef DEBUG
            DEVS_DEBUG("\t\t%s confluent transition",
                RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)));
#endif
            rb_funcall(model, rb_intern("confluent_transition"), 1, frozen_bag(self, bag));
            rb_ary_clear(bag);
        } else {
            #ifdef DEBUG
            DEVS_DEBUG("\t\t%s internal transition",
                RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)));
#endif
            rb_funcall(model, rb_intern("internal_transition"), 0);
        }
    } else if (synced && RARRAY_LEN(bag) > 0) {
#ifdef DEBUG
        DEVS_DEBUG("\t\t%s external transition",
            RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)));
#endif
        rb_iv_set(model, "@elapsed", rb_float_new(ev_time - time_last));
        rb_funcall(model, rb_intern("external_transition"), 1, frozen_bag(self, bag));
        rb_ary_clear(bag);
    } else if (!synced) {
        rb_raise(
            cDEVSBadSynchronisationError,
            "time: %f should be between time_last: %f and time_next: %f",
            ev_time,
            time_last,
            time_next
        );
    }

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

static VALUE
frozen_bag(VALUE self, VALUE bag) {
    long i;
    VALUE ret = rb_ary_new_capa(RARRAY_LEN(bag));

    for (i = 0; i < RARRAY_LEN(bag); i++) {
        VALUE msg = rb_funcall(self,
            rb_intern("ensure_input_message"),
            1,
            rb_ary_entry(bag, i)
        );
        OBJ_FREEZE(msg);
        rb_ary_push(ret, msg);
    }

    return ret;
}
