#include <parallel_coordinator_impl.h>

VALUE cDEVSParallelCoordinatorImpl;

static VALUE handle_collect_event(VALUE self, VALUE event);
static VALUE handle_input_event(VALUE self, VALUE event);
static VALUE handle_output_event(VALUE self, VALUE event);
static VALUE handle_internal_event(VALUE self, VALUE event);

/*
* Document-module: DEVS::Parallel::CoordinatorImpl
*/
void
init_devs_parallel_coordinator_impl() {
    VALUE mod = rb_define_module_under(mDEVSParallel, "CoordinatorImpl");
    cDEVSParallelCoordinatorImpl = mod;

    rb_define_method(mod, "handle_input_event", handle_input_event, 1);
    rb_define_method(mod, "handle_output_event", handle_output_event, 1);
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
    VALUE sync = rb_iv_get(self, "@synchronize");
    double time_next = NUM2DBL(rb_iv_get(self, "@time_next"));
    double ev_time = NUM2DBL(rb_iv_get(event, "@time"));
    long i;

    if (fneq(ev_time, time_next, EPSILON)) {
        rb_iv_set(self, "@time_last", rb_float_new(ev_time));

        VALUE children = rb_funcall(self, rb_intern("imminent_children"), 0);
        for (i = 0; i < RARRAY_LEN(children); i++) {
            VALUE child = rb_ary_entry(children, i);
#ifdef DEBUG
            DEVS_DEBUG("\t%s dispatching %s",
                RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)),
                RSTRING_PTR(rb_funcall(event, rb_intern("to_s"), 0))
            );
#endif
            rb_funcall(child, DISPATCH_ID, 1, event);

            if (!rb_ary_includes(sync, child)) {
                rb_ary_push(sync, child);
            }
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
* @raise [BadSynchronisationError] if the event time isn't in a proper
*   range, e.g isn't between {Simulator#time_last} and {Simulator#time_next}
*/
static VALUE
handle_output_event(VALUE self, VALUE event) {
    VALUE model = rb_iv_get(self, "@model");
    VALUE parent = rb_iv_get(self, "@parent");
    VALUE bag = rb_iv_get(event, "@bag");
    VALUE sync = rb_iv_get(self, "@synchronize");
    VALUE ev_time = rb_iv_get(event, "@time");
    long bag_size = RARRAY_LEN(bag);
    VALUE parent_bag = rb_ary_new();
    VALUE child_bags = rb_hash_new();
    long i, j;

    for (i = 0; i < bag_size; i++) {
        VALUE message = rb_ary_entry(bag, i);
        VALUE port = rb_iv_get(message, "@port");
        VALUE payload = rb_iv_get(message, "@payload");

        // check internal coupling to get children who receive sub-bag of y
        VALUE ic = rb_funcall(model, rb_intern("each_internal_coupling"), 1, port);
        for (j = 0; j < RARRAY_LEN(ic); j++) {
            VALUE coupling = rb_ary_entry(ic, j);
            VALUE mdl_dst = rb_funcall(coupling, rb_intern("destination"), 0);
            VALUE receiver = rb_funcall(mdl_dst, rb_intern("processor"), 0);
            VALUE prt_dst = rb_iv_get(coupling, "@destination_port");

            VALUE ary = rb_hash_aref(child_bags, receiver);
            if (ary == Qnil) {
                ary = rb_ary_new();
                rb_hash_aset(child_bags, receiver, ary);
            }

            rb_ary_push(
                ary,
                rb_funcall(
                    cDEVSMessage,
                    rb_intern("new"),
                    2,
                    payload,
                    prt_dst
                )
            );

            if (!rb_ary_includes(sync, receiver)) {
                rb_ary_push(sync, receiver);
            }
        }

        // check external coupling to form sub-bag of parent output
        VALUE eoc = rb_funcall(model, rb_intern("each_output_coupling"), 1, port);
        for (j = 0; j < RARRAY_LEN(eoc); j++) {
            VALUE coupling = rb_ary_entry(eoc, j);
            VALUE prt_dst = rb_iv_get(coupling, "@destination_port");

            rb_ary_push(parent_bag,
                rb_funcall(
                    cDEVSMessage,
                    rb_intern("new"),
                    2,
                    payload,
                    prt_dst
                )
            );
        }
    }

    VALUE receivers = rb_funcall(child_bags, rb_intern("keys"), 0);
    for (i = 0; i < RARRAY_LEN(receivers); i++) {
        VALUE receiver = rb_ary_entry(receivers, i);
        VALUE sub_bag = rb_hash_aref(child_bags, receiver);

        VALUE ev = rb_funcall(
            cDEVSEvent,
            rb_intern("new"),
            3,
            ID2SYM(rb_intern("input")),
            ev_time,
            sub_bag
        );

#ifdef DEBUG
        VALUE receiver_model = rb_iv_get(receiver, "@model");
        DEVS_DEBUG("\t%s dispatch input %s to %s",
            RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)),
            RSTRING_PTR(rb_funcall(ev, rb_intern("to_s"), 0)),
            RSTRING_PTR(rb_funcall(receiver_model, rb_intern("to_s"), 0))
        );
#endif

        rb_funcall(receiver, DISPATCH_ID, 1, ev);
    }

    if (RARRAY_LEN(parent_bag) > 0) {
        VALUE ev = rb_funcall(
            cDEVSEvent,
            rb_intern("new"),
            3,
            ID2SYM(rb_intern("output")),
            ev_time,
            parent_bag
        );

#ifdef DEBUG
        DEVS_DEBUG("\t%s dispatch output %s to parent",
            RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)),
            RSTRING_PTR(rb_funcall(ev, rb_intern("to_s"), 0))
        );
#endif

        rb_funcall(parent, DISPATCH_ID, 1, ev);
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
    VALUE bag = rb_iv_get(self, "@bag");
    VALUE sync = rb_iv_get(self, "@synchronize");
    VALUE child_bags = rb_hash_new();
    double time_next = NUM2DBL(rb_iv_get(self, "@time_next"));
    double time_last = NUM2DBL(rb_iv_get(self, "@time_last"));
    double ev_time = NUM2DBL(rb_iv_get(event, "@time"));
    bool synced = ev_time >= time_last && ev_time <= time_next;
    long i, j;

    if (synced) {
        for (i = 0; i < RARRAY_LEN(bag); i++) {
            VALUE msg = rb_ary_entry(bag, i);
            VALUE port = rb_iv_get(msg, "@port");
            VALUE payload = rb_iv_get(msg, "@payload");

            // check external input couplings to get children who receive sub-bag of y
            VALUE eic = rb_funcall(model, rb_intern("each_input_coupling"), 1, port);
            for (j = 0; j < RARRAY_LEN(eic); j++) {
                VALUE coupling = rb_ary_entry(eic, j);
                VALUE mdl_dst = rb_funcall(coupling, rb_intern("destination"), 0);
                VALUE receiver = rb_funcall(mdl_dst, rb_intern("processor"), 0);
                VALUE prt_dst = rb_iv_get(coupling, "@destination_port");

                VALUE ary = rb_hash_aref(child_bags, receiver);
                if (ary == Qnil) {
                    ary = rb_ary_new();
                    rb_hash_aset(child_bags, receiver, ary);
                }

                rb_ary_push(
                    ary,
                    rb_funcall(
                        cDEVSMessage,
                        rb_intern("new"),
                        2,
                        payload,
                        prt_dst
                    )
                );

                if (!rb_ary_includes(sync, receiver)) {
                    rb_ary_push(sync, receiver);
                }
            }
        }

        VALUE receivers = rb_funcall(child_bags, rb_intern("keys"), 0);
        for (i = 0; i < RARRAY_LEN(receivers); i++) {
            VALUE receiver = rb_ary_entry(receivers, i);
            VALUE sub_bag = rb_hash_aref(child_bags, receiver);
            VALUE ev = rb_funcall(
                cDEVSEvent,
                rb_intern("new"),
                3,
                ID2SYM(rb_intern("input")),
                rb_float_new(ev_time),
                sub_bag
            );

#ifdef DEBUG
            VALUE receiver_model = rb_iv_get(receiver, "@model");
            DEVS_DEBUG("\t%s dispatch input %s to %s",
                RSTRING_PTR(rb_funcall(model, rb_intern("to_s"), 0)),
                RSTRING_PTR(rb_funcall(ev, rb_intern("to_s"), 0)),
                RSTRING_PTR(rb_funcall(receiver_model, rb_intern("to_s"), 0))
            );
#endif

            rb_funcall(receiver, DISPATCH_ID, 1, ev);
        }
        rb_ary_clear(bag);

        for (i = 0; i < RARRAY_LEN(sync); i++) {
            VALUE child = rb_ary_entry(sync, i);
            VALUE ev = rb_funcall(
                cDEVSEvent,
                rb_intern("new"),
                2,
                ID2SYM(rb_intern("internal")),
                rb_float_new(ev_time)
            );
            rb_funcall(child, DISPATCH_ID, 1, ev);
        }
        rb_ary_clear(sync);

        rb_iv_set(self, "@time_last", rb_float_new(ev_time));
        VALUE tn = rb_funcall(self, rb_intern("min_time_next"), 0);
        rb_iv_set(self, "@time_next", tn);
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
