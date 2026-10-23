#!/usr/bin/env bash
# Verify CWA-2026-006 applicability on the EXACT engine versions our chains run.
# Public sources only (proxy.golang.org, raw.githubusercontent.com).
set -uo pipefail
cd "$(dirname "$0")/.."
O=ci-out
mkdir -p "$O"
OUT="$O/cwa006_engine.txt"
: > "$OUT"

say(){ echo "$@" | tee -a "$OUT"; }

say "== CWA-2026-006 engine verification $(date -u +%FT%TZ) =="

# --- wasmvm v1.5.5 (Archway / Jackway-class deployed line) ---
for V in v1.5.5 v1.5.8 v2.2.8 v2.2.9; do
  URL="https://proxy.golang.org/github.com/!cosm!wasm/wasmvm/@v/${V}.zip"
  F="/tmp/wasmvm_${V}.zip"
  if curl -sSL -o "$F" "$URL"; then
    SHA=$(sha256sum "$F" | cut -d' ' -f1)
    say ""
    say "wasmvm ${V}: zip sha256 ${SHA}"
    # Cargo.lock pins
    if unzip -p "$F" "*libwasmvm/Cargo.lock" > /tmp/cl_${V}.txt 2>/dev/null; then
      say "  cosmwasm-vm pin: $(grep -A1 'name = \"cosmwasm-vm\"' /tmp/cl_${V}.txt | grep version | head -1 | tr -d ' ')"
      say "  wasmer pin:      $(grep -A1 'name = \"wasmer\"' /tmp/cl_${V}.txt | grep version | head -1 | tr -d ' ')"
      say "  singlepass pin:  $(grep -A1 'name = \"wasmer-compiler-singlepass\"' /tmp/cl_${V}.txt | grep version | head -1 | tr -d ' ')"
    else
      say "  (no Cargo.lock extracted)"
    fi
  else
    say "wasmvm ${V}: download FAILED"
  fi
done

# --- the vulnerable Singlepass function in the exact deployed Wasmer (4.2.2) ---
say ""
say "== Wasmer Singlepass codegen (the CWA-2026-006 defect) =="
for WV in v4.2.2 v7.4.2; do
  U="https://raw.githubusercontent.com/wasmerio/wasmer/${WV}/lib/compiler-singlepass/src/codegen.rs"
  if curl -sSL -o /tmp/cg_${WV}.rs "$U"; then
    say "wasmer ${WV}: $(wc -l < /tmp/cg_${WV}.rs) lines"
    # show the release_locations_value tail (buggy adjust_stack vs correct restore_stack)
    say "  release_locations_value tail:"
    awk '/fn release_locations_value/{f=1} f{print} f&&/^    }/{c++} c==1{exit}' /tmp/cg_${WV}.rs | tail -8 | sed 's/^/    /' | tee -a "$OUT"
    say "  buggy 'adjust_stack' in release_locations_value: $(awk '/fn release_locations_value/{f=1} f&&/adjust_stack/{print "YES"} f&&/^    }/{exit}' /tmp/cg_${WV}.rs | head -1)"
    say "  correct 'restore_stack' in release_locations_value: $(awk '/fn release_locations_value/{f=1} f&&/restore_stack/{print "YES"} f&&/^    }/{exit}' /tmp/cg_${WV}.rs | head -1)"
  else
    say "wasmer ${WV}: fetch FAILED"
  fi
done

# --- cosmwasm-vm engine (Singlepass is the production compiler) ---
say ""
say "== cosmwasm-vm engine selection =="
for CV in v1.5.8 v2.2.10; do
  U="https://raw.githubusercontent.com/CosmWasm/cosmwasm/${CV}/packages/vm/src/wasm_backend/engine.rs"
  if curl -sSL -o /tmp/eng_${CV}.rs "$U"; then
    say "cosmwasm-vm ${CV}: $(grep -c 'Singlepass' /tmp/eng_${CV}.rs) Singlepass refs, $(grep -c 'Cranelift' /tmp/eng_${CV}.rs) Cranelift refs"
  fi
done

# --- wasmvm v2.2.9 (patched) go.mod wasmer line via cosmwasm crate ---
say ""
say "== patched side (wasmvm v2.2.9 -> cosmwasm-vm 2.2.10 -> Wasmer 7.4.2) =="
curl -sSL "https://raw.githubusercontent.com/CosmWasm/cosmwasm/v2.2.10/packages/vm/Cargo.toml" \
  | grep -E '^wasmer' | sed 's/^/  /' | tee -a "$OUT"
curl -sSL "https://raw.githubusercontent.com/CosmWasm/cosmwasm/v1.5.8/packages/vm/Cargo.toml" \
  | grep -E '^wasmer' | sed 's/^/  v1.5.8: /' | tee -a "$OUT"

say ""
say "== DONE =="
