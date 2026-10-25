#!/usr/bin/env python3
"""Probe candidate programs (O17 Loyal Earn + O16/O18-O21 verification).
Read-only keyless RPC. Pulls ELF strings + upgrade authority + Anchor instruction names."""
import json, base64, re, sys, os, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "o13-o15"))
from sol_rpc import get_account_info

CAND = {
    "O17_Hwi6": "Hwi6HP8LCXjVXDAdLf6sG689d7cYpvWo8zzGQB63mVVA",
    "O17_Live": "LiveiNLxbiyvZECvKAnhmuSzR4t9CWNY7Rj7XbThu9j",
    "O17_GktJ": "GktJg3afdwQEC7QhaFvgXrf1n2Jia22jmhiLYXNnxiqj",
    # verification of previously-found IDs
    "O16_satrush_main": "satRushGBRY2vgapeTAkoxz26vL2cYqyPi6CnBj7Tco",
    "O18_truedex": "ttaiNybR4ncnBFsBCQKdVus8BNHepErToRp5cuULduL",
    "O19_pascal": "3vCgc3aL1D6acmtiqtUgRSRDhep4PnVgs4jk86dGpg7j",
    "O20_n1bridge": "n1brh2AaBbnMPEjpoCDFs1fzWb5Pa8FC1o8yXp2fAqM",
    "O21_byzanlink_vault": "HyuZ17H9ScJ6GsMnJMYTCUZrw6Jz4AS4RGD9h3Pt4Se",
    "O21_byzanlink_payfi": "B9wHQVTeCkZ8KM8nZTBfHQyfQhJvuihhHa9SdWo4x77U",
}

B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58(b):
    n = int.from_bytes(b, "big"); out = ""
    while n > 0:
        n, r = divmod(n, 58); out = B58[r] + out
    for c in b:
        if c == 0: out = "1" + out
        else: break
    return out

def get(addr, enc="base64"):
    v = get_account_info(addr, encoding=enc).get("result", {}).get("value")
    return v

def strings(buf, n=6):
    return [s.decode("utf-8", "replace") for s in re.findall(rb"[ -~]{%d,}" % n, buf)]

def main():
    out = {}
    for name, prog in CAND.items():
        try:
            v = get(prog)
            if not v:
                out[name] = {"program": prog, "exists": False}; print(f"[{name}] {prog} MISSING"); continue
            raw = base64.b64decode(v["data"][0])
            rec = {"program": prog, "executable": v.get("executable"), "owner": v.get("owner"),
                   "lamports": v.get("lamports"), "data_len": len(raw)}
            if v.get("executable") and len(raw) >= 36:
                pd = b58(raw[4:36]); rec["programdata"] = pd
                pv = get(pd)
                if pv:
                    praw = base64.b64decode(pv["data"][0])
                    opt = praw[12]
                    rec["upgrade_authority"] = b58(praw[13:45]) if opt == 1 else "NONE (immutable)"
                    elf = praw[45:] if praw[45:49] == b"\x7fELF" else praw[praw.find(b"\x7fELF"):]
                    ss = strings(elf)
                    rec["elf_bytes"] = len(elf)
                    rec["anchor_instructions"] = sorted({s[7:] for s in ss if s.startswith("global:")})
                    rec["ix_names"] = sorted({s.split("Instruction: ")[1].split("Instruction")[0]
                                              for s in ss if "Instruction: " in s})[:60]
                    rec["interesting"] = sorted({s for s in ss if re.search(
                        r"withdraw|authority|signer|admin|fee|claim|redeem|mint|burn|upgrade|paused|guardian|operator|whitelist",
                        s, re.I)})[:20]
                    rec["errors"] = sorted({s for s in ss if re.search(r"Error Number: |Error Code: ", s)})[:10]
            out[name] = rec
            print(f"[{name}] {prog} exec={rec.get('executable')} auth={rec.get('upgrade_authority')} "
                  f"ixs={len(rec.get('ix_names',[]))}")
            print("   ix_names:", rec.get("ix_names"))
        except Exception as e:
            out[name] = {"program": prog, "error": str(e)}
            print(f"[{name}] ERR {e}")
    json.dump(out, open(os.path.join(os.path.dirname(__file__), "probe_candidates.json"), "w"), indent=1)

if __name__ == "__main__":
    main()
