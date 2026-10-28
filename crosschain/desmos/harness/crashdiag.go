package main

// crashdiag.go — cgo bridge that makes sure the C crash-report handler
// (crashdump.c) is installed AFTER the Go runtime installs its own signal
// handlers, so our register/stack/code dump wins for the cgo/wasmvm crashes.

/*
#include <signal.h>
#include <sys/prctl.h>
void crashdiag_install_now(void);
static void debug_pause_now(void) {
    prctl(PR_SET_PTRACER, PR_SET_PTRACER_ANY, 0, 0, 0);
    raise(SIGSTOP);
}
*/
import "C"

func debugPause() {
	C.debug_pause_now()
}

// crashdiagInstall re-installs the crash handler. Call as late as possible
// (after runtime init) so it overrides the Go runtime's SIGSEGV/SIGILL setup.
func crashdiagInstall() {
	C.crashdiag_install_now()
}
