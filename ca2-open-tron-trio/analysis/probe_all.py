#!/usr/bin/env python3
"""Arbitrary-caller constant-call probe of EVERY state-changing selector.

TVM simulation via wallet/triggerconstantcontract from a fresh, unspendable address.
No state is committed and nothing is broadcast. Writes analysis/probes.json.
"""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tronlib as T

OUT = os.path.dirname(os.path.abspath(__file__))
FRESH = T.fresh_address()
ZERO = T.hex_to_addr("0" * 40)
C = {"CherryPool": "TQxzSmRaCf1qrWdP6sfCihmrdXLNs8r4RR",
     "PokerGame": "TAcszQSbMybSkhfy4nQrAptmACRTDcYUgn",
     "FireFull": "TFxznGmEVdp5XxnQnyGp2FhFfBkMAprveW"}

A, U = T.enc_addr, T.enc_uint
PROBES = {
    "CherryPool": [
        ("withdrawTronAll()", "", 0),
        ("withdraw(uint256)", U(1), 0),
        ("withdrawAll()", "", 0),
        ("withdrawAllCherry()", "", 0),
        ("withdrawAllPledgeToken()", "", 0),
        ("withdrawToken(address,uint256)", A(FRESH) + U(1), 0),
        ("withdrawAllToken(address)", A(FRESH), 0),
        ("deposit()", "", 1000000),
        ("depositToken(uint256)", U(1000000), 0),
        ("start()", "", 0),
        ("updateUserAmountChange(address)", A(FRESH), 0),
    ],
    "PokerGame": [
        ("bet()", "", 1000000),
        ("withdraw()", "", 0),
        ("withdrawAdmin(address,uint256)", A(FRESH) + U(1), 0),
        ("withdrawAllBalance()", "", 0),
        ("withdrawIncome()", "", 0),
        ("withDrawToken(address,address,uint256)", A(FRESH) + A(FRESH) + U(1), 0),
        ("updateGame(uint256,uint256)", U(1) + U(1), 0),
        ("triggerBet(address[],uint256)", U(0x40) + U(0) + U(0), 0),
        ("endSuccessfulRound(uint256,address[])", U(1) + U(0x40) + U(0), 0),
        ("endFailedRound(uint256)", U(1), 0),
        ("newRoom(uint256,uint256,uint256)", U(1) + U(1) + U(1), 0),
        ("leaveRoom(address[],uint256)", U(0x40) + U(0) + U(0), 0),
        ("start()", "", 0),
        ("stop()", "", 0),
        ("setName(string)", U(0x20) + U(1) + "78" + "0" * 62, 0),
        ("setCfo(address)", A(FRESH), 0),
        ("setCoo(address)", A(FRESH), 0),
        ("updatePrice(uint256,uint256,uint256,uint256,uint256)", U(1) * 5, 0),
        ("updateFee(uint256,uint256,uint256,uint256,uint256)", U(1) * 5, 0),
        ("setMineContract(address)", A(FRESH), 0),
        ("transferOwnership(address)", A(FRESH), 0),
    ],
    "FireFull": [
        ("withdraw()", "", 0),
        ("superPlayerWithdraw()", "", 0),
        ("sedimentaryAssetWithdraw()", "", 0),
        ("restore(address,address,uint256)", A(FRESH) + A(FRESH) + U(1), 0),
        ("preShip(address)", A(FRESH), 0),
        ("activateSuperPlayer()", "", 0),
        ("join()", "", 1000000),
        ("addOwnership(address)", A(FRESH), 0),
        ("delOwnership(address)", A(FRESH), 0),
        ("setMinJoinAmount(uint256)", U(100), 0),
        ("startContract()", "", 0),
        ("setNextPeriods()", "", 0),
        ("setFirePowerContract(address)", A(FRESH), 0),
    ],
}


def dec_message(msg):
    if not msg:
        return None
    try:
        b = bytes.fromhex(msg)
        if b[:4] == bytes.fromhex("08c379a0"):
            ln = int.from_bytes(b[4:36], "big")
            return b[36:36 + ln].decode("utf-8", "replace")
        return "0x" + b.hex()[:200]
    except Exception:
        return str(msg)[:200]


def main():
    block = T.now_block()
    out = {"block": block, "owner_address": FRESH, "owner_hex": T.addr_to_hex(FRESH),
           "selector_source": "on-chain ABI via wallet/getcontract; selectors recomputed with cast sig",
           "contracts": {}}
    for name, addr in C.items():
        rows = []
        print(f"== {name} @ {block}")
        for sig, param, value in PROBES[name]:
            try:
                r = T.trigger(FRESH, addr, sig, param, call_value=value)
                res = r.get("result") or {}
                row = {
                    "sig": sig, "call_value_sun": value, "parameter": param,
                    "result_bool": res.get("result"),
                    "code": res.get("code"),
                    "message_hex": res.get("message"),
                    "message_text": dec_message(res.get("message")),
                    "constant_result": r.get("constant_result"),
                    "energy_used": r.get("energy_used"),
                    "energy_penalty": r.get("energy_penalty"),
                    "txid": (r.get("transaction") or {}).get("txID"),
                }
            except Exception as e:  # noqa: BLE001
                row = {"sig": sig, "error": str(e)[:250]}
            rows.append(row)
            print(f"  {sig:48s} ok={row.get('result_bool')} code={row.get('code')} "
                  f"energy={row.get('energy_used')} ret={str(row.get('constant_result'))[:70]} "
                  f"msg={row.get('message_text')}")
            time.sleep(0.65)
        out["contracts"][name] = rows
    json.dump(out, open(f"{OUT}/probes.json", "w"), indent=1)
    print("wrote probes.json")


if __name__ == "__main__":
    main()
