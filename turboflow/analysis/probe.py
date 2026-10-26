#!/usr/bin/env python3
"""Read-only probe of a Solana program account: owner, executable, ELF size, upgrade authority.
Usage: python3 probe.py <PROGRAM_ID>
Never prints secrets. Public RPC only.
"""
import sys, json, base64, struct
from rpc import call
from b58 import b58enc, b58dec

BPF_UPGRADEABLE = "BPFLoaderUpgradeab1e11111111111111111111111"
BPF_LOADER = "BPFLoader2111111111111111111111111111111111"

def acct(pubkey, enc="base64"):
    r = call("getAccountInfo", [pubkey, {"encoding": enc}])
    return r["value"]

def main():
    pid = sys.argv[1]
    a = acct(pid)
    if a is None:
        print(json.dumps({"program": pid, "exists": False})); return
    out = {"program": pid, "exists": True, "owner": a["owner"],
           "executable": a["executable"], "lamports": a["lamports"],
           "data_len": len(base64.b64decode(a["data"][0])) if a.get("data") else 0,
           "rentEpoch": a.get("rentEpoch")}
    if a["owner"] == BPF_UPGRADEABLE:
        raw = base64.b64decode(a["data"][0])
        # UpgradeableLoaderState::Program = tag u32 =2, then programdata address
        tag = struct.unpack("<I", raw[:4])[0]
        out["loader_state_tag"] = tag
        if tag == 2:
            pd = b58enc(raw[4:36])
            out["programdata"] = pd
            pda = acct(pd)
            if pda:
                praw = base64.b64decode(pda["data"][0])
                # ProgramData = tag u32=3, slot u64, option<authority> u8
                slot = struct.unpack("<Q", praw[4:12])[0]
                has_auth = praw[12]
                auth = b58enc(praw[13:45]) if has_auth else None
                out["upgrade_authority"] = auth
                out["last_deploy_slot"] = slot
                out["programdata_len"] = len(praw)
                # decode authority to check on/off curve
                if auth:
                    out["auth_off_curve"] = not on_curve(auth)
    print(json.dumps(out, indent=2))

def on_curve(pubkey_b58):
    """Approximate: check if a valid ed25519 point can be decompressed from the 32 bytes.
    Solana PDA 'off-curve' means bytes are NOT a valid ed25519 point."""
    b = b58dec(pubkey_b58)
    if len(b) != 32:
        return False
    # Pure-python ed25519 point decompression test
    p = 2**255 - 19
    d = -121665 * pow(121666, p-2, p) % p
    y = int.from_bytes(b, 'little') & ((1 << 255) - 1)
    if y >= p:
        return False
    xx = (y*y - 1) * pow(d*y*y + 1, p-2, p) % p
    x = pow(xx, (p+3)//8, p)
    if (x*x - xx) % p != 0:
        x = x * pow(2, (p-1)//4, p) % p
    if (x*x - xx) % p != 0:
        return False
    return True

if __name__ == "__main__":
    main()
