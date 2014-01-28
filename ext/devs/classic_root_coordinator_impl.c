#include <classic_root_coordinator_impl.h>

VALUE cDEVSClassicRootCoordinatorImpl;

static VALUE run(VALUE self);

/*
* Document-module: DEVS::Classic::RootCoordinatorImpl
*/
void
init_devs_classic_root_coordinator_impl() {
    VALUE mod = rb_define_module_under(mDEVSClassic, "RootCoordinatorImpl");
    cDEVSClassicRootCoordinatorImpl = mod;

    rb_define_method(mod, "run", run, 0);
}

static VALUE
run(VALUE self) {
    VALUE time = rb_iv_get(self, "@time");
    VALUE child = rb_iv_get(self, "@child");
    VALUE mutex = rb_iv_get(self, "@lock");
    double duration = NUM2DBL(rb_iv_get(self, "@duration"));

    VALUE ev = rb_funcall(
        cDEVSEvent,
        rb_intern("new"),
        2,
        ID2SYM(rb_intern("init")),
        time
    );
    rb_funcall(child, rb_intern("dispatch"), 1, ev);

    time = rb_funcall(child, rb_intern("time_next"), 0);
    rb_funcall(mutex, rb_intern("lock"), 0);
    rb_iv_set(self, "@time", time);
    rb_funcall(mutex, rb_intern("unlock"), 0);

    while(NUM2DBL(time) < duration) {
        // debug "* Tick at: #{@time}, #{Time.now - @start_time} secs elapsed"
        DEVS_DEBUG("tick at: %f", NUM2DBL(time));

        ev = rb_funcall(
            cDEVSEvent,
            rb_intern("new"),
            2,
            ID2SYM(rb_intern("internal")),
            time
        );
        rb_funcall(child, rb_intern("dispatch"), 1, ev);

        time = rb_funcall(child, rb_intern("time_next"), 0);
        rb_funcall(mutex, rb_intern("lock"), 0);
        rb_iv_set(self, "@time", time);
        rb_funcall(mutex, rb_intern("unlock"), 0);
    }

    return Qnil;
}
