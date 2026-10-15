#!/usr/bin/env python3
"""READ-ONLY: decode the recent spoo1 instructions that touched a drifted
validator stake account, to identify what last wrote its validator-list record."""
import sys, json, pathlib
HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE)); sys.path.insert(0, str(HERE.parent))
from rpc import rpc  # noqa

POOL = "aero2ePURjuEgLKTzcUmF6RypBncBGd7pMUYCoSsVJ6"
SPOO1 = "SPoo1Ku8WFXoNDMHPsrGSTSG1Y47rzgn41SLUNakuHy"

# borsh discriminant -> name (order from program/src/instruction.rs @54cdceda)
NAMES = ["Initialize", "AddValidatorToPool", "RemoveValidatorFromPool", "DecreaseValidatorStake",
         "IncreaseValidatorStake", "SetPreferredValidator", "UpdateValidatorListBalance",
         "UpdateStakePoolBalance", "CleanupRemovedValidatorEntries", "DepositStake",
         "WithdrawStake", "SetFee", "SetManager", "SetStaker", "SetFundingAuthority",
         "DepositSol", "WithdrawSol", "CreateTokenMetadata", "UpdateTokenMetadata",
         "Redelegate", "DepositStakeWithSlippage", "WithdrawStakeWithSlippage",
         "DepositSolWithSlippage", "WithdrawSolWithSlippage"]


def dec_ix(d):
    tag = int.from_bytes(d[:8], "little") if len(d) >= 8 else None
    # borsh enum discriminant for <24 variants is 1 byte
    t1 = d[0] if d else None
    name = NAMES[t1] if t1 is not None and t1 < len(NAMES) else f"?{t1}"
    args = ""
    if name in ("UpdateValidatorListBalance",):
        args = f" start_index={int.from_bytes(d[1:5],'little')} no_merge={d[5]}"
    elif name in ("DepositSol", "WithdrawSol", "WithdrawStake"):
        args = f" amount={int.from_bytes(d[1:9],'little')}"
    elif name == "WithdrawSolWithSlippage":
        args = f" in={int.from_bytes(d[1:9],'little')} min_out={int.from_bytes(d[9:17],'little')}"
    elif name == "WithdrawStakeWithSlippage":
        args = f" in={int.from_bytes(d[1:9],'little')} min_out={int.from_bytes(d[9:17],'little')}"
    elif name == "DepositStakeWithSlippage":
        args = f" min_out={int.from_bytes(d[1:9],'little')}"
    elif name == "DepositSolWithSlippage":
        args = f" in={int.from_bytes(d[1:9],'little')} min_out={int.from_bytes(d[9:17],'little')}"
    elif name in ("DecreaseValidatorStake", "IncreaseValidatorStake"):
        args = f" lamports={int.from_bytes(d[1:9],'little')} seed={int.from_bytes(d[9:17],'little')}"
    return name + args


def main():
    target = sys.argv[1] if len(sys.argv) > 1 else "52qokGjZdeRYWUwYSPEfT2GsJXqvDWy4oStp2tTkUjst"
    sigs = rpc("getSignaturesForAddress", [target, {"limit": 8, "commitment": "confirmed"}])
    for s in sigs:
        tx = rpc("getTransaction", [s["signature"], {"encoding": "json", "commitment": "confirmed",
                                                    "maxSupportedTransactionVersion": 0}])
        if not tx:
            print(s["signature"][:16], "tx unavailable"); continue
        msg = tx["transaction"]["message"]
        keys = list(msg["accountKeys"])
        # v0 transactions: append loaded addresses from address table lookups
        loaded = tx["meta"].get("loadedAddresses") or {}
        keys += list(loaded.get("writable", [])) + list(loaded.get("readonly", []))
        print(f"\n=== slot={s['slot']} bt={tx.get('blockTime')} err={tx['meta'].get('err')} sig={s['signature'][:24]}…")
        for pi, ix in enumerate(msg["instructions"]):
            pid = ix.get("programId") or keys[ix["programIdIndex"]]
            if pid == SPOO1:
                data = __import__("base64").b64decode(ix["data"]) if ix["data"] else b""
                print(f"   ix{pi} SPOO1 -> {dec_ix(data)}  (#accts={len(ix['accounts'])})")
                print(f"        accts: {[keys[i] for i in ix['accounts']]}")
            else:
                print(f"   ix{pi} {pid[:20]}… data_len={len(ix.get('data',''))}")
        # lamport deltas for the target
        ti = keys.index(target)
        pre = tx["meta"]["preBalances"][ti]; post = tx["meta"]["postBalances"][ti]
        print(f"   target pre={pre} post={post} delta={post-pre}")


main()
