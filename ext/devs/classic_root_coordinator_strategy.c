#include <classic_root_coordinator_strategy.h>

VALUE cDEVSClassicRootCoordinatorStrategy;

static VALUE run(VALUE self);

void
init_devs_classic_root_coordinator_strategy() {
    VALUE mod = rb_define_module_under(mDEVSClassic, "RootCoordinatorStrategy");
    cDEVSClassicRootCoordinatorStrategy = mod;

    rb_define_method(mod, "run", run, 0);
}

static VALUE
run(VALUE self) {
    VALUE time = rb_iv_get(self, "@time");
    VALUE child = rb_iv_get(self, "@child");
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
    rb_iv_set(self, "@time", time);

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
        rb_iv_set(self, "@time", time);
    }

    return Qnil;
}
