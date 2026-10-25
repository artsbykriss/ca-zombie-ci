#!/usr/bin/env python3
"""pass7-recon CI check: count reconciliation, live-funds re-read for OPEN items,
and a secret / keyed-RPC-URL scan. Writes ci-out/validation.json + ci-out/live_checks.json.

Runs on GitHub Actions (public repo) -> MUST NOT print or write any secret.
All RPC calls use KEYLESS public endpoints only.
"""
import json, os, re, sys, urllib.request, urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)                      # pass7-recon/
OUT = os.path.join(ROOT, "ci-out")
os.makedirs(OUT, exist_ok=True)

errors, notes = [], []

# ---------- 1. count reconciliation ----------
rows = json.load(open(os.path.join(ROOT, "analysis", "rows.json")))
n = rows["candidate_count"]
if n != len(rows["rows"]):
    errors.append(f"candidate_count {n} != len(rows) {len(rows['rows'])}")
import collections
c = collections.Counter(r["disposition"] for r in rows["rows"])
if sum(c.values()) != n:
    errors.append("disposition counts do not sum to candidate_count")
open_ids = [r["id"] for r in rows["rows"] if r["disposition"] == "OPEN"]
if open_ids != [r["id"] for r in rows["open"]]:
    errors.append("OPEN list mismatch")

# ---------- 2. live sanity checks for OPEN items (keyless public RPC) ----------
RPCS = {
    "ethereum": "https://ethereum-rpc.publicnode.com",
    "optimism": "https://optimism-rpc.publicnode.com",
    "polygon": "https://polygon-bor-rpc.publicnode.com",
    "bsc": "https://bsc-rpc.publicnode.com",
    "zksync": "https://zksync.drpc.org",
    "scroll": "https://rpc.scroll.io",
}
def rpc(url, method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r).get("result")

CHECKS = [
    # (label, chain, address, note)
    ("unv-tail row13 OP",    "optimism", "0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4", "unverified-impl proxy tail"),
    ("unv-tail row14 POLY",  "polygon",  "0x5520385bFcf07Ec87C4c53A7d8d65595Dff69FA4", "unverified-impl proxy tail"),
    ("unv-tail row15 BSC",   "bsc",      "0x4CA08cD98De12a1Df316da8f93BD0b40146e1589", "unverified-impl proxy tail"),
    ("unv-tail row16 OP",    "optimism", "0x3cDbbC3eCa52a65998B021C67982Bc72B2deCef0", "unverified-impl proxy tail"),
    ("unv-tail row17 OP",    "optimism", "0xC6Ae1Db6C66d909F7bFEeEb24F9adb8620bf9dbf", "unverified-impl proxy tail"),
    ("unv-tail row18 OP",    "optimism", "0xA4B6D09c26113F90E7b0B42E76E6FA1959b354b5", "unverified-impl proxy tail"),
    ("unv-tail row19 OP",    "optimism", "0x6726CA16b1Ba702f58D835cf199672CA04E727eC", "unverified-impl proxy tail"),
    ("unv-tail row20 ZK",    "zksync",   "0x7d5b0215EF203D0660BC37d5D09d964fd6b55a1E", "unverified-impl proxy tail"),
    ("unv-tail row21 POLY",  "polygon",  "0xB07FfFf3c7DE073c9dA55dcD899fcd4AD8C3050D", "unverified-impl proxy tail"),
    ("unv-tail row22 OP",    "optimism", "0xc4d4500326981eacD020e20A81b1c479c161c7EF", "unverified-impl proxy tail"),
    ("bsc-router impl",      "bsc",      "0xc700cf8d7adf1782a53a4805d255cf17e126db7f", "new impl; selectors 0x33411b5e/0x23a69e75"),
    ("hyperlane-7702 relayer","ethereum","0x690f4e2f19717a06e1c146b2dce68c2d23e36f4c", "expect 0xef0100||delegate"),
]
live = []
for label, chain, addr, note in CHECKS:
    url = RPCS[chain]
    rec = {"label": label, "chain": chain, "address": addr, "note": note}
    try:
        code = rpc(url, "eth_getCode", [addr, "latest"]) or "0x"
        rec["codesize_bytes"] = max(0, (len(code) - 2) // 2)
        rec["has_code"] = rec["codesize_bytes"] > 0
        rec["native_wei"] = rpc(url, "eth_getBalance", [addr, "latest"])
        if rec["has_code"]:
            rec["has_selector_33411b5e"] = "33411b5e" in code
            rec["has_selector_23a69e75"] = "23a69e75" in code
            rec["is_7702_delegation"] = code.startswith("0xef0100")
        rec["ok"] = True
    except Exception as e:                       # noqa
        rec["ok"] = False
        rec["error"] = type(e).__name__
    live.append(rec)
json.dump(live, open(os.path.join(OUT, "live_checks.json"), "w"), indent=1)

# ---------- 3. secret / keyed-URL scan ----------
SECRET_PAT = re.compile(
    r"(api[_-]?key\s*=\s*[A-Za-z0-9]{16,})|(apikey=[A-Za-z0-9]{16,})"
    r"|(alchemy\.com/v2/[A-Za-z0-9_-]{16,})|(infura\.io/v3/[A-Za-z0-9]{16,})"
    r"|(quiknode\.pro/[A-Za-z0-9]{16,})|(drpc\.org/[A-Za-z0-9]{20,})"
    r"|(PRIVATE_KEY\s*[=:]\s*0x[a-fA-F0-9]{32,})"
    r"|(MNEMONIC\s*[=:]\s*\w+)|(SECRET\s*[=:]\s*\S{16,})"
    r"|(CHRIS_GITHUB_API_KEY\s*=\s*\S+)|(GITHUB_API_KEY\s*=\s*\S+)"
    r"|(ETHERSCANV2_API_KEY\s*=\s*\S+)|(ALCHEMY_API_KEY\s*=\s*\S+)"
    r"|(GOLD_RUSH_API_KEY\s*=\s*\S+)|(DUNE_API_KEY\s*=\s*\S+)",
)
hits = []
for dirpath, dirnames, filenames in os.walk(ROOT):
    dirnames[:] = [d for d in dirnames if d not in (".git", "ci-artifacts", "out", "cache")]
    for fn in filenames:
        p = os.path.join(dirpath, fn)
        if fn in ("ci-log.txt",) or fn.endswith((".png", ".jpg", ".pdf")):
            continue
        try:
            txt = open(p, encoding="utf-8", errors="ignore").read()
        except Exception:
            continue
        for m in SECRET_PAT.finditer(txt):
            # 0x64 hex is flagged only if not a known keccak/topic constant line
            frag = m.group(0)
            hits.append({"file": os.path.relpath(p, ROOT), "match": frag[:12] + "…"})

if hits:
    errors.append(f"secret/keyed-URL scan: {len(hits)} hit(s)")

# ---------- 4. write ----------
result = {
    "folder": "pass7-recon",
    "ok": not errors,
    "candidate_count": n,
    "counts": dict(c),
    "open_count": len(open_ids),
    "live_checks_ok": sum(1 for x in live if x.get("ok")),
    "live_checks_total": len(live),
    "secret_scan_hits": len(hits),
    "secret_hits": hits[:20],
    "errors": errors,
    "notes": notes,
}
json.dump(result, open(os.path.join(OUT, "validation.json"), "w"), indent=1)
print(json.dumps(result, indent=1))
sys.exit(0 if result["ok"] else 1)
