val e = _export "kernel_main" private: (unit -> int) -> unit;
val _ = e (fn () => 0);
val () = print "Hello World! :)";
