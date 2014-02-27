#include <processor.h>
#include <coordinator.h>

VALUE cDEVSCoordinator;

static VALUE min_time_next(VALUE self);
static VALUE max_time_last(VALUE self);
static VALUE imminent_children(VALUE self);

/*
* Document-class: DEVS::Coordinator
*/
void
init_devs_coordinator() {
    VALUE klass = rb_define_class_under(mDEVS, "Coordinator", cDEVSProcessor);
    cDEVSCoordinator = klass;

    rb_define_method(klass, "min_time_next", min_time_next, 0);
    rb_define_method(klass, "max_time_last", max_time_last, 0);
    rb_define_method(klass, "imminent_children", imminent_children, 0);
}

/*
* call-seq:
*   imminent_children
*
* Returns a subset of {#children} including imminent children, e.g with
* a time next value matching {#time_next}.
*
* @return [Array<Model>] the imminent children
*/
static VALUE
imminent_children(VALUE self) {
    VALUE children = rb_iv_get(self, "@children");
    VALUE imminent = rb_ary_new();
    double time_next = NUM2DBL(rb_iv_get(self, "@time_next"));
    long i;

    for (i = 0; i < RARRAY_LEN(children); i++) {
        VALUE child = rb_ary_entry(children, i);
        double child_tn = NUM2DBL(rb_iv_get(child, "@time_next"));

        if (time_next == child_tn) {
            rb_ary_push(imminent, child);
        }
    }

    return imminent;
}

/*
* call-seq:
*   min_time_next
*
* Returns the minimum time next in all children
*
* @return [Numeric] the min time next
*/
static VALUE
min_time_next(VALUE self) {
    VALUE children = rb_iv_get(self, "@children");
    double min = INFINITY;
    long i;

    for (i = 0; i < RARRAY_LEN(children); i++) {
        VALUE child = rb_ary_entry(children, i);
        double child_tn = NUM2DBL(rb_iv_get(child, "@time_next"));

        if (child_tn < min) {
            min = child_tn;
        }
    }

    return rb_float_new(min);
}

/*
* call-seq:
*   max_time_last
*
* Returns the maximum time last in all children
*
* @return [Numeric] the max time last
*/
static VALUE
max_time_last(VALUE self) {
    VALUE children = rb_iv_get(self, "@children");
    double max = -INFINITY;
    long i;

    for (i = 0; i < RARRAY_LEN(children); i++) {
        VALUE child = rb_ary_entry(children, i);
        double child_tl = NUM2DBL(rb_iv_get(child, "@time_last"));

        if (child_tl > max) {
            max = child_tl;
        }
    }

    return rb_float_new(max);
}
