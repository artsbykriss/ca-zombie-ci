#!/usr/bin/env python3
"""
Heavy job (CI): fetch the deployed Plutus scripts from Koios, disassemble to UPLC
with the `uplc` Python package, and extract the builtin inventory + trace strings
that decide the message-encoding question.

No keys, no writes, read-only public API.
"""
import json
import os
import re
import subprocess
import sys
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "ci-out")
AN = os.path.join(ROOT, "analysis")
os.makedirs(OUT, exist_ok=True)
os.makedirs(AN, exist_ok=True)

KOIOS = "https://api.koios.rest/api/v1"
TIMEOUT = int(os.environ.get("UPLC_TIMEOUT", "1500"))

GROUPINFO_NFT = "1ddf09a9ffeca57a7ba08e1d92e1cff6ae3f6940ce8b5e7c9f9aa541"
TCHECK_POLICY = "526d246045bf4a66ae86fd7a9985a91ef3752113f9daa9060bb54be6"
TREASURY_VH = "1cfb41dc0b8d13fe53600e17059dcbcda2d8647347ec25288b4f5234"

SCRIPTS = {
    "replacement_check_v3": "8c027908260ebc29410ce4fffe788da510e4d7fd67f4b39d3c77db5e",
    "exploited_check_v2": "485aa10343f63bcc2a43f1625dc841093488e4685ba607cc187ba495",
    "treasury_value_v2": "1cfb41dc0b8d13fe53600e17059dcbcda2d8647347ec25288b4f5234",
    "tcheck_policy_v2": "526d246045bf4a66ae86fd7a9985a91ef3752113f9daa9060bb54be6",
}


def post(path, payload):
    req = urllib.request.Request(
        KOIOS + path,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "Accept": "application/json"},
        method="POST",
    )
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=90) as r:
                return json.loads(r.read())
        except Exception as e:
            if attempt == 3:
                raise
            time.sleep(3 * (attempt + 1))


def strip_cbor_bytestring(b: bytes) -> bytes:
    first = b[0]
    assert first >> 5 == 2, "not a CBOR bytestring"
    ai = first & 31
    if ai < 24:
        hl, ln = 1, ai
    elif ai == 24:
        hl, ln = 2, b[1]
    elif ai == 25:
        hl, ln = 3, int.from_bytes(b[1:3], "big")
    elif ai == 26:
        hl, ln = 5, int.from_bytes(b[1:5], "big")
    else:
        raise ValueError("unsupported CBOR header")
    return b[hl : hl + ln]


def builtins_and_traces(uplc_text):
    b = re.findall(r"\(builtin ([A-Za-z0-9_]+)\)", uplc_text)
    counts = {}
    for x in b:
        k = x.lower()
        counts[k] = counts.get(k, 0) + 1
    traces = sorted(set(re.findall(r'\(con string "((?:[^"\\]|\\.)*)"\)', uplc_text)))
    return counts, traces


def main():
    report = {"fetched_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "scripts": {}}
    hashes = list(SCRIPTS.values())
    info = post("/script_info", {"_script_hashes": hashes})
    idmap = {x["script_hash"]: x for x in info}

    for name, h in SCRIPTS.items():
        rec = {"hash": h}
        try:
            d = idmap[h]
            rec["type"] = d["type"]
            rec["size"] = d["size"]
            rec["creation_tx"] = d["creation_tx_hash"]
            raw = strip_cbor_bytestring(bytes.fromhex(d["bytes"]))
            cbor_hex = os.path.join(AN, f"{h}.hex")
            with open(cbor_hex, "w") as f:
                f.write(d["bytes"])
            ver = {"plutusV1": "1", "plutusV2": "2", "plutusV3": "3"}[d["type"]]
            t0 = time.time()
            p = subprocess.run(
                [sys.executable, "-m", "uplc", "dump", cbor_hex, "--from-cbor",
                 "--plutus-version", ver, "--dialect", "plutus"],
                capture_output=True, text=True, timeout=TIMEOUT,
            )
            rec["dump_rc"] = p.returncode
            rec["dump_seconds"] = round(time.time() - t0, 1)
            if p.returncode == 0 and p.stdout.strip():
                counts, traces = builtins_and_traces(p.stdout)
                rec["builtins"] = counts
                rec["trace_strings"] = traces[:80]
                rec["uplc_chars"] = len(p.stdout)
                rec["append_bytestring"] = counts.get("appendbytestring", 0)
                rec["sha3_256"] = counts.get("sha3_256", 0)
                rec["serialise_data"] = counts.get("serialisedata", 0)
                rec["verify_ecdsa"] = counts.get("verifyecdsasecp256k1signature", 0)
                rec["param_block_groupinfo_nft"] = GROUPINFO_NFT in p.stdout
                rec["param_block_tcheck"] = TCHECK_POLICY in p.stdout
                rec["param_block_treasury"] = TREASURY_VH in p.stdout
            else:
                rec["error"] = (p.stderr or "")[-800:]
                # fallback: use a dump committed in analysis/ (same on-chain CBOR)
                fallback = os.path.join(AN, f"{h}.uplc")
                if os.path.exists(fallback):
                    txt = open(fallback, "r", errors="replace").read()
                    counts, traces = builtins_and_traces(txt)
                    rec["builtins"] = counts
                    rec["trace_strings"] = traces[:80]
                    rec["uplc_chars"] = len(txt)
                    rec["append_bytestring"] = counts.get("appendbytestring", 0)
                    rec["sha3_256"] = counts.get("sha3_256", 0)
                    rec["serialise_data"] = counts.get("serialisedata", 0)
                    rec["verify_ecdsa"] = counts.get("verifyecdsasecp256k1signature", 0)
                    rec["param_block_groupinfo_nft"] = GROUPINFO_NFT in txt
                    rec["param_block_tcheck"] = TCHECK_POLICY in txt
                    rec["param_block_treasury"] = TREASURY_VH in txt
                    rec["source"] = "committed analysis/<hash>.uplc (uplc dump failed in CI)"
                    rec["error"] += " [fallback used]"
        except subprocess.TimeoutExpired:
            rec["error"] = f"uplc dump timeout after {TIMEOUT}s"
        except Exception as e:  # noqa: BLE001
            rec["error"] = f"{type(e).__name__}: {e}"
        report["scripts"][name] = rec
        print(name, h, rec.get("type"), rec.get("size"), rec.get("error", "ok"))

    # ---- verdicts derived purely from the bytecode inventory
    v = {}
    new = report["scripts"].get("replacement_check_v3", {})
    old = report["scripts"].get("exploited_check_v2", {})
    if "builtins" in new:
        v["replacement_has_no_raw_concat"] = new.get("append_bytestring", 0) == 0
        v["replacement_serialises_message"] = new.get("serialise_data", 0) >= 1
        v["replacement_single_sha3"] = new.get("sha3_256", 0) == 1
        v["replacement_checks_ecdsa"] = new.get("verify_ecdsa", 0) >= 1
        v["replacement_param_block_ok"] = bool(
            new.get("param_block_groupinfo_nft") and new.get("param_block_tcheck")
            and new.get("param_block_treasury"))
    if "builtins" in old:
        v["exploited_uses_raw_concat"] = old.get("append_bytestring", 0) == 1
        v["exploited_single_sha3"] = old.get("sha3_256", 0) == 1
    report["verdicts"] = v

    with open(os.path.join(OUT, "script_scan.json"), "w") as f:
        json.dump(report, f, indent=2)
    print(json.dumps(v, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
