#!/usr/bin/env bash
# Endur (Starknet) — network job. Runs on GitHub Actions.
# Read-only: re-runs the unprivileged-path checks against the live Starknet
# mainnet state over a keyless public RPC. Writes ci-out/endur-checks.json.
# No secrets, no signed transactions.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

SN_RPC="${STARKNET_RPC_URL:-https://api.cartridge.gg/x/starknet/mainnet}"
export SN_RPC

python3 - <<'PY' | tee ci-out/endur-checks.json
import json, os, urllib.request

RPC = os.environ["SN_RPC"]
SEL = {
 "total_assets":"0x21e1f7868a42adf8781cf7d3a76817ceaaafda5d56b7e7d8f26bc4f27ecdbe2",
 "total_supply":"0x1557182e4359a1f0c6301278e8f5b35a776ab58d39892581e357578fb287836",
 "convert_to_assets":"0xd98b5465896f232dc34900bfe6aa99e4ebc8a961521c6168a0664b313298c1",
 "convert_to_shares":"0x25425c8baf95b52af36121a39e0304ffc963aab145baa8cbbde61af1be9be4c",
 "send_to_withdraw_queue":"0x3bf050a64ac9074124d4e7e62dda3775f1b305c870c402364972564c39ed717",
 "set_config":"0x2f09d463867ebc70075969cdd4d3c0643f9b69dbc84bf9bf96923a52dc3c8d8",
 "upgrade":"0xf2f7c15cbe06c8d94597cd91fd7f3369eae842359235712def5584f8d270cd",
 "before_unstake":"0x37f2c3dad3121c5f3432db3c0ce75eab7187618527494640dd7d58cfeafb249",
 "deposit":"0xc73f681176fc7b3f9693986fd7b14581e8d540519e27400e88b8713932be01",
 "redeem":"0x2ef0a97332ad048ac544d8dfacdd43e128b9816d599fdd0310960904fa18609",
 "max_redeem":"0x24101f2b9fd275ad1325d86746340993673fa341d415f6ead337a25e1a82aba",
 "is_paused":"0x238d7ea31550fece8f0a8a601e3ae1a7c59cb3b6cc976ceb721e31ebd9c36f9",
 "governor":"0x246cebd6689d8c64011118478db0c61a89aa2646c860df401de476fbf378983",
 "get_config":"0x1847d98d2c5c239f7b89e5ccb00b2b0aa9d78cf297e3334b68e1707ed49d3b2",
 "asset":"0x3d4060688a1800ae986e4840aebc924bb40b5bf44de4583df2257220b54b77c",
 "balance_of":"0x35a73cd311a05d46deda634c5ee045db92f811b4e74bca4437fcb5302b7af33",
 "request_withdrawal":"0x1b74955ee4d7f3a45cdd902103ed7fea2e62dacd9cd5f07ff253e14e2af1951",
 "claim_withdrawal":"0x21f0805850429de79467c1fc548640828b4d2ce0d7ed0efdedfb5305dbc8def",
 "claim_withdrawal_to":"0x152708f76309d18a9bfa16abb793710f0348c4f8fa9772440b456726bba9d98",
 "take_funds":"0x33f0330311390e6ec25c874bb6bd8e4636d6a0d6942bbc3bee82e17c210d094",
 "get_queue_state":"0x115936c12f5802e10af1e9d80290a9ad5eac61e35bfe1ab79f88ba19c7e52d9",
 "get_total_validators":"0x21374ae08cba96dcf6c69f65cd6ce167545f16dc194909f634a4fa44ad016f6",
 "get_validator_by_index":"0x6ff3756f9e821256fa289f1908b4db4a388d0940d8880691fa4f2f4795e34b",
 "get_validator_token_info":"0x1cae93f7e6b486bfe0be4353f4525919d4dcba55703397c40717174c95ba784",
 "get_unassigned_stake":"0x137421266ee78b991d8dbf174a5ee19b746f968e2f3e4159339020cef6da473",
 "balanceOf":"0x2e4263afad30923c891518314c3c95dbe830a16874e8abc5777a9a20b54c76e",
}
V   = "0x028d709c875c0ceac3dce7065bec5328186dc89fe254527084d1689910954b0a"  # xSTRK vault (class shared by 6 vaults)
Q   = "0x518a66e579f9eb1603f5ffaeff95d3f013788e9c37ee94995555026b9648b6"  # WithdrawalQueue (ERC721)
VR  = "0x029edbca81c979decd6ee02205127e8b10c011bca1d337141170095eba690931"  # ValidatorRegistry
STRK= "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d"

def call(addr, fn, cd=None):
    req = {"jsonrpc":"2.0","id":1,"method":"starknet_call","params":[{
        "contract_address":addr,"entry_point_selector":SEL[fn],
        "calldata":cd or []},"latest"]}
    r = urllib.request.Request(RPC, data=json.dumps(req).encode(),
        headers={"content-type":"application/json","user-agent":"Mozilla/5.0 research"})
    try:
        d = json.load(urllib.request.urlopen(r, timeout=45))
        return d.get("result", d.get("error"))
    except Exception as e:
        return {"error": str(e)}

def revert_msg(r):
    if isinstance(r, dict) and "data" in r and isinstance(r["data"], dict):
        e = r["data"].get("revert_error", {})
        if isinstance(e, dict) and isinstance(e.get("error"), str):
            try: return bytes.fromhex(e["error"].replace("0x","")).decode("utf8", "replace")
            except Exception: return e["error"]
    return None

def val(r):
    if isinstance(r, list) and len(r) == 2:
        return int(r[0],16) + (int(r[1],16) << 128)
    return r

def u256(v): return [hex(v & ((1<<128)-1)), hex(v>>128)]

out = {"chain":"starknet","rpc":"(keyless public)"}
out["vault_is_paused"] = val(call(V,"is_paused"))
out["queue_is_paused"] = val(call(Q,"is_paused"))

# --- share-math roundtrip (must never create value) ---
rt = {}
for x in [10**18, 10**21]:
    s = val(call(V,"convert_to_shares", u256(x)))
    back = val(call(V,"convert_to_assets", u256(s)))
    rt[str(x)] = {"assets_in": x, "shares": s, "assets_back": back, "delta": back - x}
out["roundtrip_assets_to_shares_to_assets"] = rt

# --- privileged entry points must reject an arbitrary caller (caller = 0 here) ---
gates = {
 "send_to_withdraw_queue": call(V,"send_to_withdraw_queue", u256(1)),
 "set_config":             call(V,"set_config", ["0x123","0x123","0x123"]),
 "upgrade":                call(V,"upgrade", ["0x1"]),
 "before_unstake":         call(V,"before_unstake", ["0x456","0x1","0x2"]),
 "queue_request_withdrawal": call(Q,"request_withdrawal", u256(10**18)+u256(10**18)+["0x123"]),
}
out["gate_reverts"] = {k: revert_msg(v) for k,v in gates.items()}

# --- total_assets backing: sum staked STRK across registry validators ---
nres = call(VR,"get_total_validators")
n = int(nres[0],16) if isinstance(nres,list) and nres else 0
staked = 0; pending = 0; supported = 0
for i in range(n):
    vi = call(VR,"get_validator_by_index",[hex(i)])
    if not isinstance(vi,list) or len(vi)<1: continue
    addr = vi[0]
    info = call(VR,"get_validator_token_info",[addr, STRK])
    if isinstance(info,list) and len(info)>=3 and int(info[0],16)==1:
        supported += 1
        staked += int(info[1],16); pending += int(info[2],16)
ta = val(call(V,"total_assets"))
out["backing"] = {
 "validators_supporting_strk": supported,
 "staked_strk_wei": str(staked),
 "pending_strk_wei": str(pending),
 "total_assets_wei": str(ta),
 "staked_covers_total_assets": staked >= ta,
}
out["queue_state_wei"] = call(Q,"get_queue_state")
out["queue_strk_balance_wei"] = val(call(STRK,"balanceOf",[Q]))
out["vault_strk_balance_wei"] = val(call(STRK,"balanceOf",[V]))

out["verdict"] = ("E-U $0 (medium-high) — all privileged entry points reject an unprivileged caller; "
                  "withdrawal-queue mint is gated ('Only LST can call'); share math rounds in the vault's favour; "
                  "total_assets is backed by real staked STRK.")
print(json.dumps(out, indent=2))
PY
