# CWA-2026-006 differential harness (Wasmer static-memory guard)

Tests Wasmer PR #6879 (internal#5): `MemoryStyle::Static` relied on a 6 GiB
reservation (4 GiB bound + 2 GiB guard) while wasm32 effective addresses
(`zero-extended u32 index + zero-extended u32 offset`) can reach 8 GiB - 2.

- `wasmer437/` — Wasmer 4.3.7 (vulnerable line; used by wasmvm 2.2.8/2.3.4).
  Run: `cargo run --release -- singlepass|cranelift [target-index 0..4]`
  (per-target isolation avoids the hard SIGSEGV when the target page is unmapped).
- `wasmer742/` — Wasmer 7.4.2 (patched; 8 GiB + 1 page reservation).
- Outputs: `../../analysis/cwa006-harness-437.txt` (and `-742.txt` when built).

Result on x86_64 Linux, static memory `(memory 1 512)`:
- Singlepass 4.3.7: TRAP on all five targets (4/5/6/7/8 GiB) — the 32-bit add +
  carry trap caps effective addresses at 4 GiB.
- Cranelift 4.3.7: **escape at +6 GiB** (read an existing host mapping,
  `0x7f...0030`) and **+7 GiB** (read the placed sentinel page).
- Wasmer 7.4.2 reserves 8 GiB + 1 page (`static_bound() = 4 GiB`,
  `static_offset_guard_size() = 4 GiB + page`): all 10 runs (both engines x 5 targets)
  TRAP, and every sentinel mmap fails with EEXIST because the whole range is reserved.

Note: the 4.3.7 crate needs a harness-only `__rust_probestack` stub with
modern Rust toolchains (see `wasmer437/src/main.rs`).
