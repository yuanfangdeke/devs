#include <classic_coordinator_impl.h>

VALUE cDEVSClassicCoordinatorImpl;

static VALUE handle_init_event(VALUE self, VALUE event);
static VALUE handle_input_event(VALUE self, VALUE event);
static VALUE handle_output_event(VALUE self, VALUE event);
static VALUE handle_internal_event(VALUE self, VALUE event);

/*
* Document-module: DEVS::Classic::CoordinatorImpl
*/
void
init_devs_classic_coordinator_impl() {
    VALUE mod = rb_define_module_under(mDEVSClassic, "CoordinatorImpl");
    cDEVSClassicCoordinatorImpl = mod;

    rb_define_method(mod, "handle_init_event", handle_init_event, 1);
    rb_define_method(mod, "handle_input_event", handle_input_event, 1);
    rb_define_method(mod, "handle_output_event", handle_output_event, 1);
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
    VALUE children = rb_iv_get(self, "@children");
    VALUE model = rb_iv_get(self, "@model");
    long i;

    for (i = 0; i < RARRAY_LEN(children); i++) {
        VALUE child = rb_ary_entry(children, i);
        rb_funcall(child, DISPATCH_ID, 1, event);
    }

    VALUE tl = rb_funcall(self, rb_intern("max_time_last"), 0);
    VALUE tn = rb_funcall(self, rb_intern("min_time_next"), 0);
    rb_iv_set(self, "@time_last", tl);
    rb_iv_set(self, "@time_next", tn);

    DEVS_DEBUG("set tl: %f; tn: %f", NUM2DBL(tl), NUM2DBL(tn));
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
*   range, e.g isn't between {Coordinator#time_last} and
*   {Coordinator#time_next}
*/
static VALUE
handle_input_event(VALUE self, VALUE event) {
    VALUE model = rb_iv_get(self, "@model");
    VALUE msg = rb_ary_entry(rb_iv_get(event, "@bag"), 0);
    VALUE port = rb_iv_get(msg, "@port");
    VALUE payload = rb_iv_get(msg, "@payload");
    double time_last = NUM2DBL(rb_iv_get(self, "@time_last"));
    double time_next = NUM2DBL(rb_iv_get(self, "@time_next"));
    double ev_time = NUM2DBL(rb_iv_get(event, "@time"));

    if (ev_time >= time_last && ev_time <= time_next) {
        VALUE ret = rb_funcall(model, rb_intern("each_input_coupling"), 1, port);
        long i;

        for (i = 0; i < RARRAY_LEN(ret); i++) {
            VALUE coupling = rb_ary_entry(ret, i);
            VALUE mdl_dst = rb_funcall(coupling, rb_intern("destination"), 0);
            VALUE child = rb_funcall(mdl_dst, rb_intern("processor"), 0);
            VALUE prt_dst = rb_iv_get(coupling, "@destination_port");

#ifdef DEBUG
            DEVS_DEBUG("%s found external input coupling %s",
                RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)),
                RSTRING_PTR(rb_funcall(coupling, rb_intern("to_s"), 0))
            );
#endif

            VALUE msg2 = rb_funcall(
                cDEVSMessage,
                rb_intern("new"),
                2,
                payload,
                prt_dst
            );
            VALUE ev = rb_funcall(
                cDEVSEvent,
                rb_intern("new"),
                3,
                ID2SYM(rb_intern("input")),
                rb_float_new(ev_time),
                rb_ary_new_from_args(1, msg2)
            );
            rb_funcall(child, DISPATCH_ID, 1, ev);
        }

        rb_iv_set(self, "@time_last", rb_float_new(ev_time));
        VALUE tn = rb_funcall(self, rb_intern("min_time_next"), 0);
        rb_iv_set(self, "@time_next", tn);

#ifdef DEBUG
        DEVS_DEBUG("%s time_last: %f | time_next: %f",
            RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)),
            ev_time,
            NUM2DBL(tn)
        );
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
*   handle_output_event(event)
*
* Handles output events (y messages)
*
* @param event [Event] the output event
*/
static VALUE
handle_output_event(VALUE self, VALUE event) {
    VALUE model = rb_iv_get(self, "@model");
    VALUE msg = rb_ary_entry(rb_iv_get(event, "@bag"), 0);
    VALUE port = rb_iv_get(msg, "@port");
    VALUE payload = rb_iv_get(msg, "@payload");
    VALUE parent = rb_iv_get(self, "@parent");
    VALUE time = rb_iv_get(event, "@time");
    long i;

    VALUE ret = rb_funcall(model, rb_intern("each_output_coupling"), 1, port);
    for (i = 0; i < RARRAY_LEN(ret); i++) {
        VALUE coupling = rb_ary_entry(ret, i);
        VALUE prt_dst = rb_iv_get(coupling, "@destination_port");

#ifdef DEBUG
        DEVS_DEBUG("%s found external output coupling %s",
            RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)),
            RSTRING_PTR(rb_funcall(coupling, rb_intern("to_s"), 0))
        );
#endif

        VALUE msg2 = rb_funcall(
            cDEVSMessage,
            rb_intern("new"),
            2,
            payload,
            prt_dst
        );
        VALUE ev = rb_funcall(
            cDEVSEvent,
            rb_intern("new"),
            3,
            ID2SYM(rb_intern("output")),
            time,
            rb_ary_new3(1, msg2)
        );

        rb_funcall(parent, DISPATCH_ID, 1, ev);
    }

    ret = rb_funcall(model, rb_intern("each_internal_coupling"), 1, port);
    for (i = 0; i < RARRAY_LEN(ret); i++) {
        VALUE coupling = rb_ary_entry(ret, i);
        VALUE mdl_dst = rb_funcall(coupling, rb_intern("destination"), 0);
        VALUE child = rb_funcall(mdl_dst, rb_intern("processor"), 0);
        VALUE prt_dst = rb_iv_get(coupling, "@destination_port");

#ifdef DEBUG
        DEVS_DEBUG("%s found internal coupling %s",
            RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)),
            RSTRING_PTR(rb_funcall(coupling, rb_intern("to_s"), 0))
        );
#endif

        VALUE msg2 = rb_funcall(
            cDEVSMessage,
            rb_intern("new"),
            2,
            payload,
            prt_dst
        );
        VALUE ev = rb_funcall(
            cDEVSEvent,
            rb_intern("new"),
            3,
            ID2SYM(rb_intern("input")),
            time,
            rb_ary_new_from_args(1, msg2)
        );

        rb_funcall(child, DISPATCH_ID, 1, ev);
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
*   {Coordinator#time_next}
*/
static VALUE
handle_internal_event(VALUE self, VALUE event) {
    double time_next = NUM2DBL(rb_iv_get(self, "@time_next"));
    double ev_time = NUM2DBL(rb_iv_get(event, "@time"));
    VALUE model = rb_iv_get(self, "@model");
    long i, index;

    if (ev_time != time_next) {
        rb_raise(
            cDEVSBadSynchronisationError,
            "time: %f should match time_next: %f",
            ev_time,
            time_next
        );

        return Qnil;
    }

    VALUE children = rb_funcall(self, rb_intern("imminent_children"), 0);
    VALUE children_models = rb_ary_new2(RARRAY_LEN(children));
    for (i = 0; i < RARRAY_LEN(children); i++) {
        VALUE child = rb_ary_entry(children, i);
        rb_ary_push(children_models, rb_iv_get(child, "@model"));
    }
    VALUE child_model = rb_funcall(model, rb_intern("select"), 1, children_models);

    for (index = 0; index < RARRAY_LEN(children); index++) {
        if (child_model == rb_ary_entry(children_models, index)) {
            break;
        }
    }
    VALUE child = rb_ary_entry(children, index);

    rb_funcall(child, DISPATCH_ID, 1, event);

    rb_iv_set(self, "@time_last", rb_float_new(ev_time));
    VALUE tn = rb_funcall(self, rb_intern("min_time_next"), 0);
    rb_iv_set(self, "@time_next", tn);

#ifdef DEBUG
    DEVS_DEBUG("%s time_last: %f | time_next: %f",
        RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)),
        ev_time,
        NUM2DBL(tn)
    );
#endif

    return Qnil;
}
