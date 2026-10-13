#!/usr/bin/env python3
"""Child1: live VASE state audit at a single Aurora block. Read-only keyless RPC."""
import json, urllib.request, time, sys
from Crypto.Hash import keccak

RPC = "https://mainnet.aurora.dev"
VASE = "0xee793001Ce9Fa988712B15a59CCf5dC7d54b22FF"
GARDEN_MASTER = "0x857050Ef3a0241a2c1f65ca1F0c100a04E4AEd93"
GARDENS = {
    "gardenNear": "0x64C922E3824ab40cbbEdd6C8092d148C283d3D3D",
    "gardenUsdc": "0xfbAF3eBF228eB712b1267285787e51aDd70086bB",
    "gardenUsdt": "0x0F44fCD177098Cb2B063B50f6C62e4F1E1f9d596",
    "gardenWeth": "0x084355FDd5fcfd55d60C5B8626756a6906576f13",
    "gardenAtust": "0xe8F7F08D50e12145Cb722cfF861e6A9b43EADBA1",
}
TOKENS = {
    "USDC.e": "0xb12bfca5a55806aaf64e99521918a4bf0fc40802",
    "USDT.e": "0x4988a896b1227218e4a686fde5eabdcabd91571f",
    "DAI.e":  "0xe3520349F477A5F6EB06107066048508498A291b",
    "WNEAR":  "0xc42c30ac6cc15fac9bd938618bcaa1a1fae8501d",
    "WETH":   "0xc9bdeed33cd01541e1eed10f90519d2c06fe3feb",
    "WBTC":   "0xf4eb217ba2454613b15dbdea6e5f22276410e89e",
    "UST":    "0x5ce9f0b6afb36135b5ddbf11705ceb65e634a9dc",
    "T-da25": "0xda2585430fef327ad8ee44af8f1f989a2a91a3d2",
    "T-dfa4": "0xdfa46478f9e5ea86d57387849598dbfb2e964b02",
    "T-dcd6": "0xdcd6d4e2b3e1d1e1e6fa8c21c8a323dcbecff970",
    "RUSD":   "0x19cc40283b057d6608c22f1d20f17e16c245642e",
    "T-56f8": "0x56f87a0cb4713eb513baf57d5e81750433f5fcb9",
}
SEL = {
    "owner": "0x8da5cb5b", "pendingOwner": "0xe30c3978", "DOMAIN_SEPARATOR": "0x3644e515",
    "nonces": "0x7ecebe00", "totals": "0x4ffe34db", "balanceOf": "0x70a08231",
    "strategy": "0x228bfd9f", "pendingStrategy": "0x5108a558", "strategyData": "0xdf23b45b",
    "masterContractOf": "0xbafe4f14", "whitelistedMasterContracts": "0x12a90c8a",
    "masterContractApproved": "0x91e0eab5", "symbol": "0x95d89b41", "decimals": "0x313ce567",
    "deposit": "0x02b9446c", "withdraw": "0x97da6d30", "transfer": "0xf18d03cc",
}
ZERO_ADDR = "0x" + "0" * 40

def rpc_batch(items, retries=4, chunk=8):
    """items: list of (method, params)"""
    out = []
    for i in range(0, len(items), chunk):
        part = items[i:i+chunk]
        payload = [{"jsonrpc": "2.0", "id": j, "method": m, "params": p} for j, (m, p) in enumerate(part)]
        got = None
        for att in range(retries):
            try:
                req = urllib.request.Request(RPC, data=json.dumps(payload).encode(),
                                             headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
                r = json.load(urllib.request.urlopen(req, timeout=60))
                got = {x["id"]: x for x in r}
                break
            except Exception:
                time.sleep(2)
        if got is None:
            out.extend([{"error": "rpc-failed"}] * len(part))
        else:
            out.extend(got.get(j, {"error": "missing"}) for j in range(len(part)))
        time.sleep(0.15)
    return out

def u(x):
    return int(x, 16) if x and x != "0x" else None

def a(x):
    return "0x" + x[-40:] if x and len(x) >= 42 else None

def dec_str(hexresp):
    if not hexresp or len(hexresp) < 66:
        return None
    if len(hexresp) >= 130 and hexresp[2:66] == "0" * 64:
        ln = int(hexresp[66:130], 16)
        raw = hexresp[130:130 + ln * 2]
        if len(raw) % 2:
            raw = raw[:-1]
        return bytes.fromhex(raw).decode("utf8", "replace")
    raw = hexresp[2:66]
    if len(raw) % 2:
        raw = raw[:-1]
    try:
        b = bytes.fromhex(raw)
    except ValueError:
        return None
    return b.rstrip(b"\x00").decode("utf8", "replace")

def keccak_str(s):
    h = keccak.new(digest_bits=256)
    h.update(s.encode())
    return "0x" + h.hexdigest()

def main():
    blk = u(rpc_batch([("eth_blockNumber", [])])[0].get("result"))
    blk_hex = hex(blk)
    print("Aurora block:", blk)

    keyed = []   # (label, to, data)
    # vault basics
    keyed.append(("vault.owner", VASE, SEL["owner"]))
    keyed.append(("vault.pendingOwner", VASE, SEL["pendingOwner"]))
    keyed.append(("vault.DOMAIN_SEPARATOR", VASE, SEL["DOMAIN_SEPARATOR"]))
    keyed.append(("vault.nonces_owner", VASE, SEL["nonces"] + "0e2a05ca5d1e218034f2b7deb6e9419159839f8b".rjust(64, "0")))

    # tokens
    for lab, tok in TOKENS.items():
        t = tok.lower()[2:].rjust(64, "0")
        vasearg = VASE.lower()[2:].rjust(64, "0")
        keyed.append((f"{lab}.symbol", tok, SEL["symbol"]))
        keyed.append((f"{lab}.decimals", tok, SEL["decimals"]))
        keyed.append((f"{lab}.vaseBal", tok, SEL["balanceOf"] + vasearg))
        keyed.append((f"{lab}.totals", VASE, SEL["totals"] + t))
        keyed.append((f"{lab}.strategy", VASE, SEL["strategy"] + t))
        keyed.append((f"{lab}.pendingStrategy", VASE, SEL["pendingStrategy"] + t))
        keyed.append((f"{lab}.strategyData", VASE, SEL["strategyData"] + t))

    # whitelist / masterContract maps
    for lab, addr in list(GARDENS.items()) + [("gardenMaster", GARDEN_MASTER)] + \
            [("owner", "0x0e2a05ca5d1e218034f2b7deb6e9419159839f8b".lower()),
             ("rusdPool", "0x79B0a67a4045A7a8DC04b17456F4fe15339cBA34".lower()),
             ("random", "0x000000000000000000000000000000000000dEaD".lower())]:
        arg = addr.lower()[2:].rjust(64, "0")
        keyed.append((f"mcOf.{lab}", VASE, SEL["masterContractOf"] + arg))
        keyed.append((f"wlMC.{lab}", VASE, SEL["whitelistedMasterContracts"] + arg))
    # approvals for garden master x candidate users
    try:
        gl = json.load(open("garden_logs.json"))
        users = set()
        for lab in GARDENS:
            for l in gl.get(lab, []):
                for tt in l["topics"][1:]:
                    users.add("0x" + tt[-40:])
        users = sorted(users)
    except Exception as e:
        print("garden_logs read failed:", e)
        users = []
    print("candidate users from garden logs:", len(users))
    for usr in users[:200]:
        keyed.append((f"approved.{usr}", VASE,
                      SEL["masterContractApproved"] + GARDEN_MASTER.lower()[2:].rjust(64, "0") + usr[2:].rjust(64, "0")))

    # execute calls in batches
    items = [("eth_call", [{"to": to, "data": data}, blk_hex]) for (_, to, data) in keyed]
    res = rpc_batch(items, chunk=10)
    state = {"block": blk, "calls": {}}
    for (label, to, data), r in zip(keyed, res):
        state["calls"][label] = r.get("result") if "result" in r else {"error": r.get("error")}
    # native balance
    bal = rpc_batch([("eth_getBalance", [VASE, blk_hex])])[0]
    state["vase_eth_balance_wei"] = u(bal.get("result"))
    # code hash at this block
    code = rpc_batch([("eth_getCode", [VASE, blk_hex])])[0].get("result", "")
    state["vase_code_len"] = (len(code) - 2) // 2

    # decode summary
    def val(label):
        r = state["calls"].get(label)
        return r if isinstance(r, str) else None

    summary = {}
    summary["block"] = blk
    summary["owner"] = a(val("vault.owner"))
    summary["pendingOwner"] = a(val("vault.pendingOwner"))
    summary["DOMAIN_SEPARATOR"] = val("vault.DOMAIN_SEPARATOR")
    summary["nonces_owner"] = u(val("vault.nonces_owner"))
    summary["vase_eth_balance_wei"] = state["vase_eth_balance_wei"]
    summary["vase_code_len"] = state["vase_code_len"]

    for lab, tok in TOKENS.items():
        sym = dec_str(val(f"{lab}.symbol"))
        dec = u(val(f"{lab}.decimals"))
        bal = u(val(f"{lab}.vaseBal"))
        tot = val(f"{lab}.totals")
        tot_e = tot_b = None
        if isinstance(tot, str) and len(tot) >= 2 + 128:
            tot_e = int(tot[2:66], 16)
            tot_b = int(tot[66:130], 16)
        sd = val(f"{lab}.strategyData")
        sdate = tpct = sbal = None
        if isinstance(sd, str) and len(sd) >= 2 + 192:
            sdate = int(sd[2:66], 16)
            tpct = int(sd[66:130], 16)
            sbal = int(sd[130:194], 16)
        summary.setdefault("tokens", {})[lab] = {
            "address": tok, "symbol": sym, "decimals": dec,
            "vaseBalance": bal, "totals_elastic": tot_e, "totals_base": tot_b,
            "excess": (bal - tot_e) if (bal is not None and tot_e is not None) else None,
            "strategy": a(val(f"{lab}.strategy")),
            "pendingStrategy": a(val(f"{lab}.pendingStrategy")),
            "strategyData": [sdate, tpct, sbal],
        }
    summary["masterContractOf"] = {}
    summary["whitelistedMasterContracts"] = {}
    for lab in list(GARDENS) + ["gardenMaster", "owner", "rusdPool", "random"]:
        summary["masterContractOf"][lab] = a(val(f"mcOf.{lab}"))
        summary["whitelistedMasterContracts"][lab] = u(val(f"wlMC.{lab}"))
    summary["approvals_gardenMaster"] = {}
    for usr in users[:200]:
        v = u(val(f"approved.{usr}"))
        if v:
            summary["approvals_gardenMaster"][usr] = v
    json.dump(state, open("child1_state_raw.json", "w"), indent=1)
    json.dump(summary, open("child1_state.json", "w"), indent=1)

    print(json.dumps({k: v for k, v in summary.items() if k not in ("tokens", "approvals_gardenMaster")}, indent=1))
    print("\nTOKENS:")
    for lab, t in summary["tokens"].items():
        print(f"  {lab:8s} {t['address']} {t['symbol']!r} dec={t['decimals']} vaseBal={t['vaseBalance']} "
              f"elastic={t['totals_elastic']} excess={t['excess']} strat={t['strategy']} sData={t['strategyData']}")
    print("\napprovals (nonzero) for gardenMaster:", summary["approvals_gardenMaster"])

if __name__ == "__main__":
    main()
