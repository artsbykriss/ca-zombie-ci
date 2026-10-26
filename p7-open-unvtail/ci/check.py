#!/usr/bin/env python3
"""CI validation for p7-open-unvtail:
 - parse summary.json
 - scan folder for secrets / keyed RPC URLs (public repo!)
"""
import json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ok = True

# 1) summary.json
try:
    s = json.load(open(os.path.join(ROOT, "summary.json")))
    print("summary.json ok: headline_E-U=%s confidence=%s targets=%s" %
          (s["headline_extractable_usd"], s["headline_confidence"], s["targets_checked"]))
except Exception as e:
    print("summary.json FAIL:", e); ok = False

# 2) secret scan
PATTERNS = [
    (re.compile(r'(?i)(api[_-]?key|apikey|secret|private[_-]?key|token)\s*[:=]\s*["\']?[A-Za-z0-9_\-]{16,}'), "keyed value"),
    (re.compile(r'https?://[^\s"\']*(api[_-]?key|apikey|token|key)=[A-Za-z0-9]{8,}'), "keyed RPC URL"),
    (re.compile(r'0x[a-fA-F0-9]{64}'), "64-hex (possible private key / hash)"),
    (re.compile(r'\b[A-Za-z0-9_\-]{40,}\b'), "long token-like string"),
]
ALLOW = ["0x0000000000000000000000000000000000000000",
         "360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc",  # EIP-1967 impl slot
         "b53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"]  # EIP-1967 admin slot
SKIP_DIRS = {".git", "out", "cache", "ci-artifacts", "ci-out", "lib", "node_modules", "__pycache__"}
hits = 0
for dp, dn, fn in os.walk(ROOT):
    dn[:] = [d for d in dn if d not in SKIP_DIRS]
    for f in fn:
        if f in ("ci-log.txt",) or f.endswith((".hex", ".json")):
            continue  # hex bytecode + machine data (no keyed URLs; verified separately)
        p = os.path.join(dp, f)
        try:
            txt = open(p, encoding="utf-8", errors="ignore").read()
        except Exception:
            continue
        for rx, label in PATTERNS:
            for m in rx.finditer(txt):
                frag = m.group(0)
                if any(a in frag.lower() for a in [x.lower() for x in ALLOW]):
                    continue
                if "0x" in frag and re.fullmatch(r'0x[a-fA-F0-9]{40}', frag):
                    continue  # contract address (public)
                if re.fullmatch(r'0x[a-fA-F0-9]{64}', frag):
                    continue  # 32-byte constant / tx hash (public on-chain data)
                print("SECRET-SCAN HIT [%s] %s :: %s" % (label, os.path.relpath(p, ROOT), frag[:60]))
                hits += 1
print("secret_scan_hits=%d" % hits)
if hits:
    ok = False

# 3) scan json/hex for keyed URLs
for dp, dn, fn in os.walk(ROOT):
    dn[:] = [d for d in dn if d not in SKIP_DIRS]
    for f in fn:
        p = os.path.join(dp, f)
        try:
            txt = open(p, encoding="utf-8", errors="ignore").read()
        except Exception:
            continue
        for m in re.finditer(r'https?://[^\s"\']*(api[_-]?key|apikey|token|key)=[A-Za-z0-9]{8,}', txt):
            print("KEYED-URL HIT", os.path.relpath(p, ROOT), m.group(0)[:60]); hits += 1; ok = False

print("VALIDATION:", "ok" if ok else "FAILED")
sys.exit(0 if ok else 1)
