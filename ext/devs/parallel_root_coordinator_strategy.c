#include <parallel_root_coordinator_strategy.h>

VALUE cDEVSParallelRootCoordinatorStrategy;

static VALUE run(VALUE self, VALUE rc);

/*
* Document-module: DEVS::Parallel::RootCoordinatorStrategy
*/
void
init_devs_parallel_root_coordinator_strategy() {
    VALUE mod = rb_define_module_under(mDEVSParallel, "RootCoordinatorStrategy");
    cDEVSParallelRootCoordinatorStrategy = mod;

    rb_define_module_function(mod, "run", run, 1);
}


/*
      def run(rc)
        rc.time = rc.child.time_next

        loop do
          rc.send :debug, "* Tick at: #{@time}, #{Time.now - rc.start_time} secs elapsed"
          rc.child.dispatch(Event.new(:collect, rc.time))
          rc.child.dispatch(Event.new(:internal, rc.time))
          rc.time = rc.child.time_next
          break if rc.time >= rc.duration
        end
      end
*/

static VALUE
run(VALUE self, VALUE rc) {
    VALUE child = rb_iv_get(rc, "@child");
    double duration = NUM2DBL(rb_iv_get(rc, "@duration"));
    int start_time = NUM2INT(
        rb_funcall(rb_iv_get(rc, "@start_time"), rb_intern("to_i"), 0)
    );

    VALUE t = rb_funcall(child, rb_intern("time_next"), 0);
    rb_funcall(rc, rb_intern("time="), 1, t);

    while(NUM2DBL(t) < duration) {
        DEVS_DEBUG("*** Tick at: %f, %d secs elapsed", NUM2DBL(t),
            time(NULL) - start_time);

        VALUE ev = rb_funcall(
            cDEVSEvent,
            rb_intern("new"),
            2,
            ID2SYM(rb_intern("collect")),
            t
        );
        rb_funcall(child, rb_intern("dispatch"), 1, ev);

        ev = rb_funcall(
            cDEVSEvent,
            rb_intern("new"),
            2,
            ID2SYM(rb_intern("internal")),
            t
        );
        rb_funcall(child, rb_intern("dispatch"), 1, ev);

        t = rb_funcall(child, rb_intern("time_next"), 0);
        rb_funcall(rc, rb_intern("time="), 1, t);
    }

    return Qnil;
}
