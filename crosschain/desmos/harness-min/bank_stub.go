package main

// bank_stub.go — minimal terminal for the fallback harness (no Cosmos SDK).
// Used only if the SDK 0.47.10 harness fails to build in CI; validates the
// native control-transfer chain (pivot -> g0 clear -> cgocallback -> terminal)
// on the Go 1.21.13 runtime without the SDK dependency graph.

import (
	"fmt"
	"os"
	"unsafe"
)

var calls int

//go:noinline
func mintBridge(_ unsafe.Pointer) {
	calls++
	fmt.Fprintf(os.Stderr, "M4BANK call=%d terminal=mintBridge-stub\n", calls)
}

func runBankCheck() error {
	mintBridge(nil)
	return nil
}
