#!/usr/bin/env python3
"""O16-O21: pull each program's ELF strings + upgrade authority (read-only, keyless RPC)."""
import json, base64, re, sys, urllib.request, hashlib, os

RPC = "https://solana-rpc.publicnode.com"
PROGRAMS = {
    "O16_satrush_main":     "satRushGBRY2vgapeTAkoxz26vL2cYqyPi6CnBj7Tco",
    "O16_satrush_staking":  "SaTsTaKpGdTfUEPSSwyYgLKkfnZu8uL3D1DbLXshdb7",
    "O18_truedex":          "ttaiNybR4ncnBFsBCQKdVus8BNHepErToRp5cuULduL",
    "O19_pascal":           "3vCgc3aL1D6acmtiqtUgRSRDhep4PnVgs4jk86dGpg7j",
    "O20_n1bridge":         "n1brh2AaBbnMPEjpoCDFs1fzWb5Pa8FC1o8yXp2fAqM",
    "O21_byzanlink_vault":  "HyuZ17H9ScJ6GsMnJMYTCUZrw6Jz4AS4RGD9h3Pt4Se",
    "O21_byzanlink_payfi":  "B9wHQVTeCkZ8KM8nZTBfHQyfQhJvuihhHa9SdWo4x77U",
}

def rpc(method, params):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=40) as r:
        return json.load(r)

def b64d(s):
    return base64.b64decode(s)

def get(addr, enc="base64"):
    r = rpc("getAccountInfo", [addr, {"encoding": enc}])
    return r.get("result", {}).get("value")

def upgrade_authority(prog):
    """program account -> programdata address + authority (BPFLoaderUpgradeable state layout)."""
    v = get(prog)
    if not v:
        return None
    raw = b64d(v["data"][0])
    # enum u32 = 2 (Program), then programdata address (32 bytes)
    progdata = base58_encode(raw[4:36]) if len(raw) >= 36 else None
    auth = None
    if progdata:
        pv = get(progdata)
        if pv:
            praw = b64d(pv["data"][0])
            # UpgradeableLoaderState::ProgramData { slot: u64, upgrade_authority: Option<Pubkey> }
            tag = int.from_bytes(praw[0:4], "little")
            opt = praw[12]
            if opt == 1:
                auth = base58_encode(praw[13:45])
            else:
                auth = "NONE (immutable)"
    return {"programdata": progdata, "upgrade_authority": auth, "size": v.get("space") or len(raw)}

B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def base58_encode(b):
    n = int.from_bytes(b, "big")
    out = ""
    while n > 0:
        n, r = divmod(n, 58)
        out = B58[r] + out
    for c in b:
        if c == 0: out = "1" + out
        else: break
    return out

def elf_strings(prog):
    v = get(prog)
    raw = b64d(v["data"][0])
    progdata = base58_encode(raw[4:36])
    pv = get(progdata)
    praw = b64d(pv["data"][0])
    # ProgramData header: 4 (tag) + 8 (slot) + 1 (opt) + 32 (authority) + 8 (padding) = 53
    elf = praw[45:]  # ELF magic may start at 45 or 53 depending on padding
    if elf[:4] != b"\x7fELF":
        i = praw.find(b"\x7fELF")
        elf = praw[i:] if i >= 0 else b""
    return elf

def strings(buf, minlen=6):
    return re.findall(rb"[ -~]{%d,}" % minlen, buf)

ANCHOR = "global:"
def main():
    os.makedirs("raw", exist_ok=True)
    out = {}
    for name, prog in PROGRAMS.items():
        try:
            ua = upgrade_authority(prog)
            elf = elf_strings(prog)
            ss = [s.decode("utf-8", "replace") for s in strings(elf)]
            ixs = sorted({s[len(ANCHOR):] for s in ss if s.startswith(ANCHOR)})
            errs = sorted({s for s in ss if "Error" in s or "error" in s or "failed" in s.lower()})[:40]
            interesting = sorted({s for s in ss if re.search(r"withdraw|owner|authority|signer|admin|fee|claim|deposit|redeem|mint|burn|upgrade|paused|pause|guardian|only", s, re.I)})[:120]
            open(f"strings_{name}.txt","w").write("\n".join(ss))
            with open(f"raw/{name}.elf","wb") as f: f.write(elf)
            out[name] = {"program": prog, "elf_bytes": len(elf), **(ua or {}),
                         "anchor_instructions": ixs, "error_like": errs, "interesting": interesting}
            print(f"[{name}] {prog} elf={len(elf)}B auth={ua and ua.get('upgrade_authority')} ixs={len(ixs)}")
        except Exception as e:
            out[name] = {"program": prog, "error": str(e)}
            print(f"[{name}] ERROR {e}", file=sys.stderr)
    json.dump(out, open("program_surface.json","w"), indent=1)
    for k,v in out.items():
        print("\n==",k,v.get("program"),"==")
        print("  anchor ixs:", v.get("anchor_instructions"))
        print("  interesting:", v.get("interesting", [])[:40])

if __name__ == "__main__":
    main()
