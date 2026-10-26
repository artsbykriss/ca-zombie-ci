#!/usr/bin/env python3
"""Final live-state capture: Solana custody + BSC bridge/vault balances. Read-only, keyless RPC."""
import json, urllib.request, time
from rpc import call

SOL_ATAS = {
    "9ayXbTyhkJ49WtG6DA2PCN6EAKtM8DCneMzhJPTMRWcj": "bridge USDC (custody)",
    "6hVp2UaWWQwGo2c6yHj39WJWDNenR48GsLGKPzSa7EU2": "bridge USDT (custody)",
    "Cjhbg8g13QpfVLPvavQjz8RsDMNifyHkLZ8L4b2TCTEw": "bridge USDT (2nd, custody)",
    "2ZEku38cWzGqMzhKG6tnpC42godiy8hjGFMZwf7uvPTc": "Fireblocks SIG USDC",
    "FYmWdMq9KT87jpZomMQR7Y2r4a2KbEiXkoDJcHMAP1vq": "Fireblocks SIG USDT",
    "3uCQ76uwDRur1udh4EPjzN84K2vrrcnyH2AnuUjFWNAF": "Fireblocks TFUSERS USDC",
    "8ckjipCeccH3RrcPyXU8xCBGHRK9qgSPuU47ZfBKWGKC": "Fireblocks TFUSERS USDT",
}
BSC = "https://bsc-rpc.publicnode.com"
USDC_BSC = "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d"
USDT_BSC = "0x55d398326f99059fF775485246999027B3197955"
BSC_HOLDERS = {
    "0x145CD0d5C3dD0eF1405dCf1b4D2BCE7c611625dB": "BSC bridge (user deposits)",
    "0x8757f9E16d775759671e95e50D749CECCDA375AE": "Fireblocks MPC (SIG)",
    "0x077Ab3f5D4372cA14c6AA417215Af3d91B55bAFc": "Fireblocks MPC (TFUSERS)",
}

def evm_balance(token, holder):
    data = "0x70a08231" + holder[2:].rjust(64, "0")
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                       "params": [{"to": token, "data": data}, "latest"]}).encode()
    req = urllib.request.Request(BSC, data=body, headers={"Content-Type": "application/json",
                                                          "User-Agent": "Mozilla/5.0"})
    r = json.load(urllib.request.urlopen(req, timeout=60))
    return int(r["result"], 16) / 1e18

def main():
    out = {"solana": {}, "bsc": {}}
    slot = call("getSlot", [{"commitment": "finalized"}])
    out["slot"] = slot
    print("slot", slot)
    for a, label in SOL_ATAS.items():
        v = call("getTokenAccountBalance", [a])["value"]
        out["solana"][label] = {"ata": a, "amount": v["amount"], "ui": v["uiAmountString"]}
        print(f"  SOL {label:28s} {v['uiAmountString']:>18s}  {a}")
        time.sleep(0.3)
    for h, label in BSC_HOLDERS.items():
        try:
            u = evm_balance(USDC_BSC, h); t = evm_balance(USDT_BSC, h)
            out["bsc"][label] = {"holder": h, "usdc": u, "usdt": t}
            print(f"  BSC {label:28s} USDC={u:,.2f} USDT={t:,.2f}  {h}")
        except Exception as e:
            print("  BSC ERR", label, e)
        time.sleep(0.3)
    json.dump(out, open("final_state.json", "w"), indent=1)

if __name__ == "__main__":
    main()
