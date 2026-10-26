#!/usr/bin/env python3
"""Dump live Wildcat V2 market state for both chains. Read-only, keyless-URL only.

Emits JSON on stdout. RPC endpoints are taken from env (never hard-coded keyed URLs):
  ETH_RPC     default https://ethereum-rpc.publicnode.com
  PLASMA_RPC  default https://rpc.plasma.to
"""
import json, os, subprocess, sys

ETH = os.environ.get("ETH_RPC", "https://ethereum-rpc.publicnode.com")
PLASMA = os.environ.get("PLASMA_RPC", "https://rpc.plasma.to")
UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120 Safari/537.36"

SIGS = {
    "asset": "0x38d52e0f",
    "borrower": "0x7df1f1b9",
    "totalAssets": "0x01e1d114",
    "totalSupply": "0x18160ddd",
    "totalDebts": "0x14a1c32d",
    "isClosed": "0xc2b6b58c",
    "reserveRatioBips": "0xd98e0fe8",
    "annualInterestBips": "0x11057cd0",
    "borrowableAssets": "0x76636017",
    "accruedProtocolFees": "0x0cd1a5b6",
    "feeRecipient": "0x46904840",
    "hooks": "0xcd7033c4",
}
CHAINS = {
    "ethereum": (ETH, "0xfEB516d9D946dD487A9346F6fee11f40C6945eE4"),
    "plasma": (PLASMA, "0xdb2e0DE97d6d96aa56754635704a4273E0F348ae"),
}


def batch(url, payload):
    # pass the JSON body on stdin: a large batch exceeds ARG_MAX as an argv argument.
    # chunk into small requests: public RPCs cap batch size and otherwise drop entries.
    out = []
    for i in range(0, len(payload), 40):
        chunk = payload[i:i + 40]
        p = subprocess.run(
            ["curl", "-s", "-m", "60", "-X", "POST", url,
             "-H", "content-type: application/json", "-H", "User-Agent: " + UA,
             "-d", "@-"],
            input=json.dumps(chunk), capture_output=True, text=True)
        try:
            r = json.loads(p.stdout)
            out.extend(r if isinstance(r, list) else [r])
        except Exception:
            print("RPC parse error: " + p.stdout[:200], file=sys.stderr)
    return out


def markets(url, arch):
    r = batch(url, [{"jsonrpc": "2.0", "id": 0, "method": "eth_call",
                     "params": [{"to": arch, "data": "0x46762101"}, "latest"]}])
    if not r or not isinstance(r, list) or not r[0].get("result"):
        return []
    b = r[0]["result"][2:]
    off = int(b[:64], 16); ln = int(b[off * 2:off * 2 + 64], 16)
    return ["0x" + b[off * 2 + 64 + i * 64: off * 2 + 64 + i * 64 + 64][-40:] for i in range(ln)]


def main():
    out = {}
    for chain, (url, arch) in CHAINS.items():
        ms = markets(url, arch)
        payload, ids = [], []
        i = 0
        for m in ms:
            for name, sel in SIGS.items():
                payload.append({"jsonrpc": "2.0", "id": i, "method": "eth_call",
                                "params": [{"to": m, "data": sel}, "latest"]})
                ids.append((m, name)); i += 1
        R = {x["id"]: x.get("result") for x in batch(url, payload) if isinstance(x, dict)}
        # retry ids that came back missing/errored (public RPCs drop entries under load)
        for _ in range(3):
            missing = [c for c in payload if R.get(c["id"]) in (None, "0x")]
            if not missing:
                break
            R.update({x["id"]: x.get("result") for x in batch(url, missing) if isinstance(x, dict)})
        rows = {m: {} for m in ms}
        idx = 0
        for m in ms:
            for name in SIGS:
                v = R.get(idx); idx += 1
                if v is None or v == "0x":
                    rows[m][name] = None
                elif name in ("asset", "borrower", "feeRecipient"):
                    rows[m][name] = "0x" + v[-40:]
                elif name == "hooks":
                    rows[m]["hooks_addr"] = "0x%040x" % (int(v, 16) >> 96)
                    rows[m]["hooks_raw"] = v
                else:
                    rows[m][name] = int(v, 16)
        # borrower code size (EOA vs contract vs EIP-7702 delegation)
        payload = [{"jsonrpc": "2.0", "id": j, "method": "eth_getCode",
                    "params": [row["borrower"], "latest"]}
                   for j, row in enumerate(rows.values()) if row.get("borrower")]
        R2 = {x["id"]: x.get("result") for x in batch(url, payload) if isinstance(x, dict)}
        for _ in range(3):
            miss2 = [c for c in payload if R2.get(c["id"]) in (None, "0x")]
            if not miss2:
                break
            R2.update({x["id"]: x.get("result") for x in batch(url, miss2) if isinstance(x, dict)})
        for j, row in enumerate(rows.values()):
            c = R2.get(j) or "0x"
            row["borrower_codesize"] = (len(c) - 2) // 2
            row["borrower_code_prefix"] = c[:44]
        out[chain] = {"archController": arch, "marketCount": len(ms), "markets": rows}
    json.dump(out, sys.stdout, indent=1)


if __name__ == "__main__":
    main()
