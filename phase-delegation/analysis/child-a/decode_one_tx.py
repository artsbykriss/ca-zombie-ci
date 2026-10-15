#!/usr/bin/env python3
"""READ-ONLY: fully decode one transaction (base58 data + inner instructions)."""
import sys, base64, pathlib
HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE)); sys.path.insert(0, str(HERE.parent))
from rpc import rpc, b58dec, b58enc  # noqa

# borsh discriminant -> name, VERIFIED against the declaration order in
# program/src/instruction.rs @54cdceda (27 variants; Redelegate = 22).
NAMES = ["Initialize", "AddValidatorToPool", "RemoveValidatorFromPool", "DecreaseValidatorStake",
         "IncreaseValidatorStake", "SetPreferredValidator", "UpdateValidatorListBalance",
         "UpdateStakePoolBalance", "CleanupRemovedValidatorEntries", "DepositStake",
         "WithdrawStake", "SetManager", "SetFee", "SetStaker", "DepositSol",
         "SetFundingAuthority", "WithdrawSol", "CreateTokenMetadata", "UpdateTokenMetadata",
         "IncreaseAdditionalValidatorStake", "DecreaseAdditionalValidatorStake",
         "DecreaseValidatorStakeWithReserve", "Redelegate", "DepositStakeWithSlippage",
         "WithdrawStakeWithSlippage", "DepositSolWithSlippage", "WithdrawSolWithSlippage"]
SPOO1 = "SPoo1Ku8WFXoNDMHPsrGSTSG1Y47rzgn41SLUNakuHy"
STAKE = "Stake11111111111111111111111111111111111111"


def dec(d: bytes):
    t = d[0] if d else None
    name = NAMES[t] if t is not None and t < len(NAMES) else f"?{t}"
    extra = ""
    if name == "UpdateValidatorListBalance":
        extra = f" start_index={int.from_bytes(d[1:5],'little')} no_merge={d[5]}"
    elif name in ("DepositSol", "WithdrawSol", "WithdrawStake", "AddValidatorToPool"):
        extra = f" arg={int.from_bytes(d[1:9],'little')}"
    return f"{name}{extra}"


def main():
    sig = sys.argv[1]
    tx = rpc("getTransaction", [sig, {"encoding": "json", "commitment": "confirmed",
                                     "maxSupportedTransactionVersion": 0}])
    msg = tx["transaction"]["message"]
    keys = list(msg["accountKeys"])
    loaded = tx["meta"].get("loadedAddresses") or {}
    keys += list(loaded.get("writable", [])) + list(loaded.get("readonly", []))
    print(f"slot={tx['slot']} blockTime={tx.get('blockTime')} err={tx['meta'].get('err')}")
    print("signers:", [k for k in msg["accountKeys"][:msg["header"]["numRequiredSignatures"]]])
    print(f"\n-- {len(msg['instructions'])} top-level ix")
    for i, ix in enumerate(msg["instructions"]):
        pid = ix.get("programId") or keys[ix["programIdIndex"]]
        d = b58dec(ix["data"]) if ix.get("data") else b""
        print(f"  ix{i}: {pid}")
        if pid == SPOO1:
            print(f"        -> {dec(d)}")
            print(f"        accts: {[keys[a] for a in ix['accounts']]}")
        else:
            print(f"        data({len(d)}) = {d[:64].hex()}")
    inner = tx["meta"].get("innerInstructions") or []
    print(f"\n-- inner instruction groups: {len(inner)}")
    for grp in inner:
        for ix in grp["instructions"]:
            pid = ix.get("programId") or keys[ix["programIdIndex"]]
            d = b58dec(ix["data"]) if ix.get("data") else b""
            tag = ""
            if pid == SPOO1:
                tag = " -> " + dec(d)
            elif pid == STAKE:
                tag = f" (stake instr {d[0] if d else '?'})"
            print(f"   [{grp['index']}] {pid}{tag}")
            if pid in (SPOO1, STAKE):
                print(f"        accts={[keys[a] for a in ix['accounts']]}")


main()
