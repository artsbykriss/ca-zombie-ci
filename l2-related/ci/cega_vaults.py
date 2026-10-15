#!/usr/bin/env python3
"""Cega V2 vault state census (both chains) — read-only, public RPCs, no secrets.
Fetches for every vault created via the CegaEntry diamond:
  - ERC20 totalSupply()
  - CegaEntry.getVault(vault) -> (totalAssets, tokenId, yieldFeeBps, mgmtFeeBps, productId, auctionWinner, tradeStartDate, vaultStatus, dataSource, isInDispute, isDefaulted)
Writes ci-out/cega-vaults.json + prints aggregates.
"""
import json, os, subprocess, time, sys

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ci-out")
os.makedirs(OUT, exist_ok=True)

CHAINS = [
    (1, ["https://ethereum-rpc.publicnode.com", "https://eth.drpc.org", "https://1rpc.io/eth"],
     "0x7a67D5Eb2D6684d3e899575aAAA5AB31b79890c2", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "analysis", "cega-v2", "vaults-1.json")),
    (42161, ["https://arb1.arbitrum.io/rpc", "https://arbitrum-one-rpc.publicnode.com"],
     "0xFD62eEbAA64D2F33BbDb42e713Fba7E94EF2dA50", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "analysis", "cega-v2", "vaults-42161.json")),
]

GETVAULT_SIG = "getVault(address)((uint128,uint64,uint16,uint16,uint32,address,uint40,uint8,uint8,bool,bool))"


def cast(args, timeout=40):
    try:
        r = subprocess.run(["cast"] + args, capture_output=True, text=True, timeout=timeout)
        return r.stdout.strip()
    except Exception:
        return ""


def call(rpcs, to, sig, args=None, tries=4):
    for i in range(tries):
        rpc = rpcs[i % len(rpcs)]
        a = ["call", to, sig] + (args or []) + ["--rpc-url", rpc]
        out = cast(a)
        if out:
            return out
        time.sleep(1.5)
    return ""


def main():
    allout = {}
    for chain, rpcs, entry, vf in CHAINS:
        vaults = list(json.load(open(vf)).keys())
        print(f"chain {chain}: {len(vaults)} vaults", flush=True)
        out = {}
        for idx, v in enumerate(vaults):
            ts_raw = call(rpcs, v, "totalSupply()(uint256)")
            gv_raw = call(rpcs, entry, GETVAULT_SIG, [v])
            rec = {"vault": v}
            try:
                rec["totalSupply"] = int(ts_raw)
            except Exception:
                rec["totalSupply"] = None
            rec["getVault_raw"] = gv_raw
            if gv_raw.startswith("("):
                inner = gv_raw.strip("()")
                parts = [p.strip() for p in inner.split(",")]
                try:
                    rec["totalAssets"] = int(parts[0])
                    rec["productId"] = int(parts[4])
                    rec["vaultStatus"] = int(parts[7])
                    rec["isDefaulted"] = parts[10] == "true"
                except Exception:
                    pass
            out[v] = rec
            if idx % 20 == 0:
                print(f"  {idx}/{len(vaults)}", flush=True)
        allout[str(chain)] = out
        nz = [r for r in out.values() if r.get("totalSupply")]
        print(f"chain {chain}: {len(nz)} vaults with nonzero share supply", flush=True)
    json.dump(allout, open(os.path.join(OUT, "cega-vaults.json"), "w"), indent=1)
    for chain, out in allout.items():
        ta = sum(r.get("totalAssets", 0) or 0 for r in out.values())
        print(f"chain {chain}: sum totalAssets (raw 6dp-ish) = {ta}")
    print("wrote", os.path.join(OUT, "cega-vaults.json"))


if __name__ == "__main__":
    main()
