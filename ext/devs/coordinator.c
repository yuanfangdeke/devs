#include <coordinator.h>

VALUE cDEVSCoordinator;

static VALUE imminent_children(VALUE self);

/*
* Document-class: DEVS::Coordinator
*/
void
init_devs_coordinator() {
    VALUE klass = rb_define_class_under(mDEVS, "Coordinator", cDEVSSimulator);
    cDEVSCoordinator = klass;

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

    for (int i = 0; i < RARRAY_LEN(children); i++) {
        VALUE child = rb_ary_entry(children, i);
        double child_tn = NUM2DBL(rb_iv_get(child, "@time_next"));

        if (time_next == child_tn) {
            rb_ary_push(imminent, child);
        }
    }

    return imminent;
}
