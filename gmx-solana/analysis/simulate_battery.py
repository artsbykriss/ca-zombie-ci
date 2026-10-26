#!/usr/bin/env python3
"""simulateTransaction battery against the live GMX-Solana store program (read-only).

Uses solders to build legacy transactions. Neutral external signer:
5tzFkiKscXHK5ZXCGbXZxdw7gTjjD1mBwuoFbhUvuAi9. sigVerify=false, replaceRecentBlockhash=true.
"""
import base64, hashlib, json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sol import simulate, b58dec, b58enc

from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.signature import Signature
from solders.hash import Hash

PROGRAM = Pubkey.from_string("Gmso1uvJnLbawvw7yezdfCDcPydwW2s2iqG3w6MDucLo")
STORE = Pubkey.from_string("CTDLvGGXnoxvqLyTpGzdGLg9pD6JexKxKXSV8tqqo8bN")
TOKEN_MAP = Pubkey.from_string("7cEiyyEB2VGMtnKLb7Ro7SsJKYZVBZjpS8ihBD8jR938")
SYSTEM = Pubkey.from_string("11111111111111111111111111111111")
ATTACKER = Pubkey.from_string("5tzFkiKscXHK5ZXCGbXZxdw7gTjjD1mBwuoFbhUvuAi9")
ORACLE_REAL = Pubkey.from_string("kbxzK9aj4LXrNrGEra8eDdaCYh2TSbY9JeJovZ3K3X4")
HERE = os.path.dirname(os.path.abspath(__file__))

def disc(name):
    return hashlib.sha256(("global:" + name).encode()).digest()[:8]

def build_tx(instructions, payer=ATTACKER):
    msg = Message.new_with_blockhash(instructions, payer, Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    return base64.b64encode(bytes(tx)).decode()

def simulate_tx(ixs, tries=5):
    tx = build_tx(ixs)
    for _ in range(tries):
        res = simulate(tx, sig_verify=False, replace_blockhash=True)
        if isinstance(res, dict) and "value" in res:
            return res["value"]
        time.sleep(3)
    return {"error": "rpc-failed"}

def run(name, ixs, note=""):
    v = simulate_tx(ixs)
    err = v.get("err")
    code = None
    if isinstance(err, dict) and "InstructionError" in err:
        ie = err["InstructionError"][1]
        code = ie.get("Custom") if isinstance(ie, dict) else ie
    out = {"name": name, "note": note, "err": err, "code": code,
           "units": v.get("unitsConsumed"), "logs_tail": (v.get("logs") or [])[-6:]}
    print(f"== {name}: err={err} code={code}")
    for l in out["logs_tail"]:
        print("   ", l[:130])
    time.sleep(1.5)
    return out

def sys_create_account(frm, new, lamports, space, owner):
    data = (0).to_bytes(4, "little") + lamports.to_bytes(8, "little") + space.to_bytes(8, "little") + bytes(owner)
    return Instruction(SYSTEM, data, [AccountMeta(frm, True, True), AccountMeta(new, True, True)])

def main():
    results = []
    role = b"ORACLE_CONTROLLER"
    keeper = Pubkey.from_string("4z1snZPe4fjqNGgyuykowuKrhwaVG8nFyzU3MXurPHfS")
    oracle_ctrl = Pubkey.from_string("55tVJJu5En1u4Vizh8yKbe9P6TtAx8BB6nqhFMQt4aB")

    def prog_ix(name, metas, data=b""):
        return Instruction(PROGRAM, disc(name) + data, metas)

    # sanity: recognized instruction with wrong accounts -> account error, not 101
    results.append(run("sanity:create_order_v2([store])",
                       [prog_ix("create_order_v2", [AccountMeta(STORE, False, False)])],
                       "expect NOT 101"))
    # 1. has_admin(attacker)
    results.append(run("has_admin(attacker)",
                       [prog_ix("has_admin", [AccountMeta(STORE, False, False)], bytes(ATTACKER))],
                       "expect NotAnAdmin (6000+) or false"))
    # 2. has_role(attacker, ORACLE_CONTROLLER)
    results.append(run("has_role(attacker,ORACLE_CONTROLLER)",
                       [prog_ix("has_role", [AccountMeta(STORE, False, False)],
                                bytes(ATTACKER) + len(role).to_bytes(4, "little") + role)],
                       "expect PermissionDenied"))
    # 2b. has_role(ORACLE_CONTROLLER PDA)
    results.append(run("has_role(55tVJJ,ORACLE_CONTROLLER)",
                       [prog_ix("has_role", [AccountMeta(STORE, False, False)],
                                bytes(oracle_ctrl) + len(role).to_bytes(4, "little") + role)],
                       "expect true"))
    # 2c. has_role(4z1snZ keeper)
    results.append(run("has_role(4z1snZ,ORACLE_CONTROLLER)",
                       [prog_ix("has_role", [AccountMeta(STORE, False, False)],
                                bytes(keeper) + len(role).to_bytes(4, "little") + role)],
                       "keeper probe"))
    # 3. set_prices_from_price_feed with attacker authority on the REAL oracle
    chainlink = Pubkey.from_string("HEvSKofvBgfaexv23kMabbYqxasxU3mQ4ibBMEmJWHny")
    results.append(run("set_prices(attacker,real_oracle)",
                       [prog_ix("set_prices_from_price_feed",
                                [AccountMeta(ATTACKER, True, False), AccountMeta(STORE, False, False),
                                 AccountMeta(ORACLE_REAL, False, True), AccountMeta(TOKEN_MAP, False, False),
                                 AccountMeta(chainlink, False, False)],
                                (0).to_bytes(4, "little"))],
                       "expect ConstraintHasOne (attacker != oracle.authority)"))
    # 4. create own oracle then set prices as its authority -> role check
    new_oracle = Pubkey.from_bytes(hashlib.sha256(b"gmx-oracle-probe-1").digest())
    space = 8 + 22888
    results.append(run("self_oracle+set_prices(attacker)", [
        sys_create_account(ATTACKER, new_oracle, 250_000_000, space, PROGRAM),
        prog_ix("initialize_oracle", [AccountMeta(ATTACKER, True, True), AccountMeta(ATTACKER, False, False),
                                      AccountMeta(STORE, False, False), AccountMeta(new_oracle, True, True),
                                      AccountMeta(SYSTEM, False, False)]),
        prog_ix("set_prices_from_price_feed",
                [AccountMeta(ATTACKER, True, False), AccountMeta(STORE, False, False),
                 AccountMeta(new_oracle, False, True), AccountMeta(TOKEN_MAP, False, False),
                 AccountMeta(chainlink, False, False)],
                (0).to_bytes(4, "little")),
    ], "expect PermissionDenied at role check on self-created oracle"))
    # 5. ADMIN-gated instruction with attacker authority
    results.append(run("update_last_restarted_slot(attacker)",
                       [prog_ix("update_last_restarted_slot",
                                [AccountMeta(ATTACKER, True, False), AccountMeta(STORE, False, True)])],
                       "expect PermissionDenied/NotAnAdmin at ADMIN gate"))
    # 6. claim_fees_from_market with attacker authority
    market = Pubkey.from_string("BZFQaPvXNL7ksHhCgEn8eRZpefiDCy61wyGVJeP1mD2")
    results.append(run("claim_fees(attacker)",
                       [prog_ix("claim_fees_from_market",
                                [AccountMeta(ATTACKER, True, False), AccountMeta(STORE, False, False),
                                 AccountMeta(market, False, True), AccountMeta(TOKEN_MAP, False, False),
                                 AccountMeta(ATTACKER, False, True), AccountMeta(ATTACKER, False, True),
                                 AccountMeta(SYSTEM, False, False)])],
                       "expect failure before/at claim-fees-address gate"))
    # 7. liquidate with attacker authority
    results.append(run("liquidate(attacker)",
                       [prog_ix("liquidate",
                                [AccountMeta(ATTACKER, True, False), AccountMeta(STORE, False, False),
                                 AccountMeta(market, False, True), AccountMeta(TOKEN_MAP, False, False),
                                 AccountMeta(ORACLE_REAL, False, True)])],
                       "expect failure (role gate / account validation)"))
    with open(os.path.join(HERE, "sim_battery.json"), "w") as f:
        json.dump(results, f, indent=2)

if __name__ == "__main__":
    main()
