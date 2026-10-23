#!/usr/bin/env python3
"""
Cardboard Trade (Solana) — decisive NEGATIVE auth PoC.
Read-only fork-simulations (simulateTransaction, sigVerify=false) against live mainnet state.
Proves the two auth gates that close the ~$1.04M USDC vault to an unprivileged attacker:
  (A) exchange settle (tag 0x1f) is gated on the immediate caller being the oracle program;
  (B) the oracle push (tag 0x07) validates every price-source account (owner allowlist + keys).

Writes ci-out/cardboard-auth.json. Never signs or sends a transaction.
"""
import json, base64, urllib.request, sys, os, time

RPC = os.environ.get("SOL_RPC", "https://api.mainnet-beta.solana.com")
EX = "J7vt5nGQd7YggFTV6GPwmWycfxzLjnHoGX6GRUKo9M7A"
OR = "5g3PW7gtfnM3QYsGPaPGLiCxtous4arSugCct9KPHHWo"
KEEPER = "Ef1YAVrvuUfjULKGEN2eqUSHwYTSUx2aE3VjoBefxVVb"
ORCLSKIP = "0x50494b534c43524f"
SYSTEM = "11111111111111111111111111111111"
# program ids that own oracle price-source accounts (from disassembly allowlist)
DEX_OWNERS = {
    "BiSoNHVpsVZW2F7rx2eQ59yQwKxzU5NvBcmKshCSUypi",
    "TessVdML9pBGgG9yGks7o4HewRaXVAMuoVj4x83GLQH",
    "goonuddtQRrWqqn5nFyczVKaie28f3kDkHWkHtURSLE",
    "ojh19ojaKduoJZuaJADhcVGp4xt1TcdAvZmpVsCorch",
    "AQU1FRd7papthgdrwPTTq5JacJh8YtwEXaBfKU3bTz45",
    "dijkbkCAKfFTCxQg3u1pg82gVU1jJGHBBRcteD11mBu",
    "fastC7gqs2WUXgcyNna2BZAe9mte4zcTGprv3mv18N3",
}


def rpc(method, params):
    for _ in range(6):
        try:
            req = urllib.request.Request(RPC, data=json.dumps(
                {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            return json.load(urllib.request.urlopen(req, timeout=120))
        except Exception:
            time.sleep(3)
    return {}


def _write(out):
    os.makedirs("ci-out", exist_ok=True)
    with open("ci-out/cardboard-auth.json", "w") as f:
        json.dump(out, f, indent=1)
    print("wrote ci-out/cardboard-auth.json")


def main():
    try:
        from solders.pubkey import Pubkey
        from solders.instruction import Instruction, AccountMeta
        from solders.message import Message
        from solders.transaction import Transaction
        from solders.hash import Hash
        from solders.signature import Signature
    except Exception as e:
        print("solders unavailable:", e)
        return _write({"verdict": "blocked", "reason": "solders not installed"})
    P = lambda s: Pubkey.from_string(s)

    def simulate(ixs):
        payer = P(KEEPER)
        msg = Message.new_with_blockhash(ixs, payer, Hash.default())
        tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
        raw = base64.b64encode(bytes(tx)).decode()
        r = rpc("simulateTransaction", [raw, {"encoding": "base64", "sigVerify": False,
                                              "replaceRecentBlockhash": True, "commitment": "processed"}])
        v = r.get("result", {}).get("value", {})
        logs = v.get("logs") or []
        return {"err": v.get("err"), "cu": v.get("unitsConsumed"),
                "orclskip": any(ORCLSKIP in l for l in logs), "logs": logs[:5]}

    out = {"target": "Cardboard Trade", "exchange": EX, "oracle": OR,
           "usdc_vault": "DSnqZ6ctTToaCMoCwULqdfkXGTTXfQ9oiv3qH98NR4hv",
           "usdc_vault_amount": 1037944.751058, "method": "simulateTransaction sigVerify=false",
           "tests": {}, "verdict": None}

    # (A) DIRECT exchange settle (tag 0x1f) with the exact oracle-CPI account list + payload.
    ex_ix = Instruction(P(EX), bytes.fromhex(
        "1f00007bc6860a130000007bc6860a130000003e50701b00000000a14e160000000000"),
        [AccountMeta(P("3Kmfgp4ue8eRg48as6rzgPtkFvnbZhEnRmn8ESdbiAPC"), False, False),
         AccountMeta(P("HrW16vpyqURMvR4CeRf1QYMucEGKusHuzPVz1V3h7R7B"), False, False),
         AccountMeta(P("iiGr5mtbreSHGuUw5DF1NtVjSqAjLdUvcUUVqQ9jYFc"), False, True),
         AccountMeta(P("ACJeDQXpxGEWdV7Ym7Wt2XgiRU1kBpcoN8m6QHFjokPY"), False, True),
         AccountMeta(P(EX), False, False)])
    out["tests"]["direct_exchange_settle_0x1f"] = simulate([ex_ix])

    # (B) ORACLE push (0x071f) using a FRESH reference tx's account list.
    sigs = rpc("getSignaturesForAddress", [OR, {"limit": 8}]).get("result", [])
    ref = None
    for s in sigs:
        r = rpc("getTransaction", [s["signature"], {"encoding": "json",
                 "maxSupportedTransactionVersion": 1, "commitment": "confirmed"}])
        res = r.get("result")
        if not res:
            continue
        m = res["transaction"]["message"]
        keys = m["accountKeys"]
        for ix in m["instructions"]:
            if keys[ix["programIdIndex"]] == OR and ix.get("data") == "YS":
                ref = {"sig": s["signature"], "keys": keys,
                       "idx": ix["accounts"], "header": m["header"]}
                break
        if ref:
            break
    if not ref:
        out["tests"]["oracle_push"] = {"note": "no fresh oracle push tx found"}
        out["verdict"] = "INCONCLUSIVE"
        return _write(out)

    keys = ref["keys"]
    hdr = ref["header"]
    nw = len(keys) - hdr["numReadonlySignedAccounts"] - hdr["numReadonlyUnsignedAccounts"]
    writable = set(range(0, nw))
    IDX = ref["idx"]

    def push(accounts):
        metas = [AccountMeta(P(a), False, i in writable) for a, i in accounts]
        return simulate([Instruction(P(OR), bytes.fromhex("071f"), metas)])

    out["tests"]["reference_tx"] = ref["sig"]
    out["tests"]["oracle_push_real_accounts"] = push([(keys[i], i) for i in IDX])

    # swap one real DEX-owned source account -> SystemProgram (wrong owner)
    owners = rpc("getMultipleAccounts", [keys, {"encoding": "base64"}]).get("result", {}).get("value", [])
    swap_at = None
    for pos, i in enumerate(IDX):
        o = owners[i]["owner"] if owners and owners[i] else None
        if o in DEX_OWNERS:
            swap_at = pos
            break
    if swap_at is not None:
        sw = [(keys[i], i) for i in IDX]
        sw[swap_at] = (SYSTEM, IDX[swap_at])
        out["tests"]["oracle_push_swapped_source_owner"] = push(sw)

    a = out["tests"]["direct_exchange_settle_0x1f"]
    c = out["tests"]["oracle_push_real_accounts"]
    b = out["tests"].get("oracle_push_swapped_source_owner", {})
    ok = (a.get("orclskip") and (a.get("cu") or 9e9) < 3000
          and not c.get("orclskip") and b.get("orclskip"))
    out["verdict"] = ("no E-U path — exchange 0x1f caller-gated to the oracle (ORCLSKIP, no settle); "
                      "oracle price-source accounts owner-allowlisted (wrong owner -> ORCLSKIP)"
                      ) if ok else "INCONCLUSIVE"
    out["pass"] = bool(ok)
    print(json.dumps(out["tests"], indent=1))
    print("VERDICT:", out["verdict"], "| pass:", ok)
    return _write(out)


if __name__ == "__main__":
    sys.exit(main())
