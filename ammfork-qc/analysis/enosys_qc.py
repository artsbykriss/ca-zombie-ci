import json, sys, datetime
sys.path.insert(0, '/home/heisenberg/CA/ammfork-qc/analysis')
from rpc import *

out = {"generated_at": datetime.datetime.utcnow().isoformat()+"Z", "chain": "flare", "reads": {}, "security": {}, "songbird": {}, "errors": []}

FACTORY = "0x17AA157AC8C54034381b840Cb8f6bf7Fc355f0de"
NPM = "0xD9770b1C7A6ccd33C75b5bcB1c0078f46bE46657"
POOL = "0x3C2a7B76795E58829FAAa034486D417dd0155162"
WFLR = "0x1D80c49BbBCd1C0911346656B529DF9E5c2F783d"
SAFE = "0xdedda08961216adb9ca09b88986d110127b24270"
DEAD = "0x" + addr("0x000000000000000000000000000000000000dEaD")
IMPL_SLOT = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
ADMIN_SLOT = "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"
GUARD_SLOT = "0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8"

def code_size(c, a, block="latest"):
    c_ = rpc(c, "eth_getCode", [a, block])
    return (len(c_)-2)//2

def slot(c, a, s, block="latest", endpoint=None):
    v = rpc(c, "eth_getStorageAt", [a, s, block], endpoint=endpoint)
    return "0x" + v[-40:]

try:
    latest = int(rpc("flare", "eth_blockNumber", []), 16)
    out["latest_block"] = latest
    out["chain_id"] = int(rpc("flare", "eth_chainId", []), 16)
    B = hex(latest)

    rd = out["reads"]
    rd["factory_owner"] = "0x"+call("flare", FACTORY, "0x8da5cb5b", (), B)[-40:]
    rd["factory_governor"] = "0x"+call("flare", FACTORY, "0x0c340a24", (), B)[-40:]
    rd["factory_protocolFeeReceiver"] = "0x"+call("flare", FACTORY, "0x39a51be5", (), B)[-40:]
    rd["factory_poolsCount"] = word(call("flare", FACTORY, "0x8c788de0", (), B))
    rd["factory_protocolFee"] = word(call("flare", FACTORY, "0xb0e21e8a", (), B))
    rd["factory_impl_slot"] = slot("flare", FACTORY, IMPL_SLOT, B)
    rd["factory_admin_slot"] = slot("flare", FACTORY, ADMIN_SLOT, B)
    rd["npm_impl_slot"] = slot("flare", NPM, IMPL_SLOT, B)
    rd["npm_admin_slot"] = slot("flare", NPM, ADMIN_SLOT, B)
    rd["pool_impl_slot"] = slot("flare", POOL, IMPL_SLOT, B)
    rd["pool_admin_slot"] = slot("flare", POOL, ADMIN_SLOT, B)
    rd["pool_impl_code_size"] = code_size("flare", rd["pool_impl_slot"])
    rd["factory_impl_code_size"] = code_size("flare", rd["factory_impl_slot"])
    rd["npm_impl_code_size"] = code_size("flare", rd["npm_impl_slot"])
    rd["pool_admin_owner"] = "0x"+call("flare", rd["pool_admin_slot"], "0x8da5cb5b", (), B)[-40:]
    rd["factory_admin_owner"] = "0x"+call("flare", rd["factory_admin_slot"], "0x8da5cb5b", (), B)[-40:]

    # Safe
    rd["safe_threshold"] = word(call("flare", SAFE, "0xe75235b8", (), B))
    owners = call("flare", SAFE, "0xa0e67e2b", (), B, endpoint="https://flare-api.flare.network/ext/C/rpc")
    od = owners[2:]
    n = int(od[64:128], 16)
    rd["safe_owners"] = ["0x"+od[128+64*i:128+64*(i+1)][-40:] for i in range(n)]
    rd["safe_version"] = dec_str(call("flare", SAFE, "0xffa1ad74", (), B))
    rd["safe_nonce"] = word(call("flare", SAFE, "0xaffed0e0", (), B))
    rd["safe_guard_slot"] = "0x"+rpc("flare", "eth_getStorageAt", [SAFE, GUARD_SLOT, B])[-40:]
    mods = call("flare", SAFE, "0xcc2f8452", (addr(SAFE), hexword(10)), B, endpoint="https://flare-api.flare.network/ext/C/rpc")
    md = mods[2:]
    rd["safe_modules_count"] = int(md[64:128], 16)
    rd["safe_modules_first"] = "0x"+md[128:192][-40:] if rd["safe_modules_count"] else None

    # Pool state
    rd["pool_token0"] = "0x"+call("flare", POOL, "0x0dfe1681", (), B)[-40:]
    rd["pool_token1"] = "0x"+call("flare", POOL, "0xd21220a7", (), B)[-40:]
    rd["pool_fee"] = word(call("flare", POOL, "0xddca3f43", (), B))
    s0 = call("flare", POOL, "0x3850c7bd", (), B)
    rd["pool_slot0"] = {k: word(s0, i) for i,k in enumerate(["sqrtPriceX96","tick","observationIndex","observationCardinality","observationCardinalityNext","feeProtocol","unlocked"])}
    if rd["pool_slot0"]["tick"] >= 2**255: rd["pool_slot0"]["tick"] -= 2**256
    rd["pool_liquidity"] = word(call("flare", POOL, "0x1a686502", (), B))
    rd["pool_wflr_balance"] = word(call("flare", WFLR, "0x70a08231", (addr(POOL),), B))/1e18
    usdt0 = rd["pool_token1"] if rd["pool_token0"].lower()==WFLR.lower() else rd["pool_token0"]
    rd["pool_other_token"] = usdt0
    rd["pool_other_balance_raw"] = word(call("flare", usdt0, "0x70a08231", (addr(POOL),), B))
    try:
        rd["pool_other_decimals"] = word(call("flare", usdt0, "0x313ce567", (), B))
    except Exception: pass
    try:
        rd["npm_token1_owner"] = "0x"+call("flare", NPM, "0x6352211e", (hexword(1),), B)[-40:]
    except Exception as e:
        rd["npm_token1_owner_error"] = repr(e)

    # Historical state and security tests at pinned block
    PIN = 72386500
    HB = hex(PIN)
    out["security_block"] = PIN
    rd["pool_impl_slot_pinned"] = slot("flare", POOL, IMPL_SLOT, HB, endpoint="https://flare.rpc.thirdweb.com")
    rd["pool_token0_pinned"] = "0x"+call("flare", POOL, "0x0dfe1681", (), HB, "https://flare.rpc.thirdweb.com")[-40:]
    rd["pool_token1_pinned"] = "0x"+call("flare", POOL, "0xd21220a7", (), HB, "https://flare.rpc.thirdweb.com")[-40:]
    s0p = call("flare", POOL, "0x3850c7bd", (), HB, "https://flare.rpc.thirdweb.com")
    rd["pool_slot0_pinned"] = {k: word(s0p, i) for i,k in enumerate(["sqrtPriceX96","tick","observationIndex","observationCardinality","observationCardinalityNext","feeProtocol","unlocked"])}
    if rd["pool_slot0_pinned"]["tick"] >= 2**255: rd["pool_slot0_pinned"]["tick"] -= 2**256
    rd["pool_liquidity_pinned"] = word(call("flare", POOL, "0x1a686502", (), HB, "https://flare.rpc.thirdweb.com"))
    rd["pool_wflr_balance_pinned"] = word(call("flare", WFLR, "0x70a08231", (addr(POOL),), HB, "https://flare.rpc.thirdweb.com"))/1e18
    rd["pool_usdt0_balance_pinned_raw"] = word(call("flare", usdt0, "0x70a08231", (addr(POOL),), HB, "https://flare.rpc.thirdweb.com"))
    try:
        rd["npm_token1_owner_pinned"] = "0x"+call("flare", NPM, "0x6352211e", (hexword(1),), HB, "https://flare.rpc.thirdweb.com")[-40:]
    except Exception as e:
        rd["npm_token1_owner_pinned_error"] = repr(e)

    def sec(name, to, selector, args=(), block=HB):
        res, err = rpc_raw("flare", "eth_call", [{"to": to, "data": selector+"".join(args)}, block], endpoint="https://flare.rpc.thirdweb.com")
        out["security"][name] = {"to": to, "result": res, "error": err}

    # reuse exact calldata from security_tests.json where possible
    sec("pool.mint_nopay", POOL, "0x3c8a7d8d", [addr("0x000000000000000000000000000000000000dEaD"), hexword(-600), hexword(600), hexword(10**18), hexword(160)])
    sec("pool.swap_nopay", POOL, "0x128acb08", [addr("0x000000000000000000000000000000000000dEaD"), hexword(1), hexword(-10**6), hexword(4295128740), hexword(160)])
    sec("pool.flash_norepay", POOL, "0x490e6cbc", [addr("0x000000000000000000000000000000000000dEaD"), hexword(10**6), hexword(0), hexword(128)])
    sec("pool.collectProtocol", POOL, "0x85b66729", [addr("0x000000000000000000000000000000000000dEaD"), "f"*64, "f"*64])
    sec("pool.setFeeProtocol", POOL, "0x8206a4d1", [hexword(10), hexword(10)])
    sec("pool.resetupDelegations", POOL, "0xdbb9a17f", [])
    sec("npm.collect_nonowner", NPM, "0xfc6f7865", [hexword(1), addr("0x000000000000000000000000000000000000dEaD"), "f"*64, "f"*64])
    sec("npm.burn_nonowner", NPM, "0x42966c68", [hexword(1)])
    sec("factory.setPoolImplementation", FACTORY, "0xd6f74898", [addr("0x000000000000000000000000000000000000dEaD")])
    sec("factory.transferOwnership", FACTORY, "0xf2fde38b", [addr("0x000000000000000000000000000000000000dEaD")])
    sec("factory.setGovernor", FACTORY, "0xc42cf535", [addr("0x000000000000000000000000000000000000dEaD")])
    sec("factory.collectProtocolFeesAll", FACTORY, "0xfcd5bbe8", [])
    sec("tracker.updateLiquiditySnapshots", "0x5646f8f757ed7238f28ae930ab7e1d806413df36", "0x75b2e9d8", [hexword(1), hexword(10**30), hexword(0)])

    # songbird counts / impl
    sb = int(rpc("songbird", "eth_blockNumber", []), 16)
    out["songbird"]["latest_block"] = sb
    SB = hex(sb)
    SFACT = "0x416F1CcBc55033Ae0133DA96F9096Fe8c2c17E7d"
    out["songbird"]["poolsCount"] = word(call("songbird", SFACT, "0x8c788de0", (), SB))
    out["songbird"]["factory_impl_slot"] = slot("songbird", SFACT, IMPL_SLOT, SB)
    out["songbird"]["factory_impl_code_size"] = code_size("songbird", out["songbird"]["factory_impl_slot"])
    out["songbird"]["factory_owner"] = "0x"+call("songbird", SFACT, "0x8da5cb5b", (), SB)[-40:]
    out["songbird"]["final_block_2026_10_18"] = 135684743
    out["songbird"]["poolsCount_at_report_block"] = word(call("songbird", SFACT, "0x8c788de0", (), hex(135684743)))
except Exception as e:
    out["errors"].append(repr(e))

with open("/home/heisenberg/CA/ammfork-qc/analysis/enosys_qc.json","w") as f:
    json.dump(out, f, indent=2)
print(json.dumps(out, indent=2)[:12000])
