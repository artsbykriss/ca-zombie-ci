#!/usr/bin/env python3
"""
Endur (Starknet) LST — READ-ONLY live probe.

No keys, no transactions, no state changes.  Uses keyless public Starknet RPCs.
Pins one Starknet block and reads:
  * the 6 ERC-4626 vaults (xSTRK, strkBTC, xWBTC, xtBTC, xLBTC, xsBTC)
  * the xSTRK withdrawal-queue NFT (ERC-721) and ValidatorRegistry
  * the ERC-4626 deposit->redeem round-trip (exact integer math + on-chain preview)
  * an access-control map built by calling every external entry point with the
    zero address as caller (the most unprivileged caller).  A revert whose reason
    is a caller/role check proves the gate; a revert for any *other* reason
    (allowance, "exceeds max", "too early", deserialize) proves the entry point
    has NO caller gate (permissionless).

Output: <outdir>/endur-live.json
"""
import json
import os
import sys
import time
import urllib.request

# --- keccak256: prefer pycryptodome, fall back to a pure-python implementation (CI-safe) ---
try:
    from Crypto.Hash import keccak as _keccak_mod

    def _keccak256(data: bytes) -> bytes:
        h = _keccak_mod.new(digest_bits=256)
        h.update(data)
        return h.digest()
except Exception:  # noqa: BLE001
    _RC = [0x0000000000000001, 0x0000000000008082, 0x800000000000808A, 0x8000000080008000,
           0x000000000000808B, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
           0x000000000000008A, 0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
           0x000000008000808B, 0x800000000000008B, 0x8000000000008089, 0x8000000000008003,
           0x8000000000008002, 0x8000000000000080, 0x000000000000800A, 0x800000008000000A,
           0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008]
    _R = [[0, 36, 3, 41, 18], [1, 44, 10, 45, 2], [62, 6, 43, 15, 61],
          [28, 55, 25, 21, 56], [27, 20, 39, 8, 14]]
    _M = (1 << 64) - 1

    def _rotl(x, n):
        return ((x << n) | (x >> (64 - n))) & _M if n else x

    def _keccak_f(a):
        for rnd in range(24):
            c = [a[x][0] ^ a[x][1] ^ a[x][2] ^ a[x][3] ^ a[x][4] for x in range(5)]
            d = [c[(x - 1) % 5] ^ _rotl(c[(x + 1) % 5], 1) for x in range(5)]
            for x in range(5):
                for y in range(5):
                    a[x][y] ^= d[x]
            b = [[0] * 5 for _ in range(5)]
            for x in range(5):
                for y in range(5):
                    b[y][(2 * x + 3 * y) % 5] = _rotl(a[x][y], _R[x][y])
            for x in range(5):
                for y in range(5):
                    a[x][y] = b[x][y] ^ ((~b[(x + 1) % 5][y]) & b[(x + 2) % 5][y])
            a[0][0] ^= _RC[rnd]
        return a

    def _keccak256(data: bytes) -> bytes:
        rate = 136
        data = bytearray(data) + b"\x01"
        while len(data) % rate != 0:
            data += b"\x00"
        data[-1] ^= 0x80
        a = [[0] * 5 for _ in range(5)]
        for off in range(0, len(data), rate):
            blk = data[off:off + rate]
            for i in range(rate // 8):
                lane = int.from_bytes(blk[i * 8:i * 8 + 8], "little")
                a[i % 5][i // 5] ^= lane
            a = _keccak_f(a)
        out = bytearray()
        for i in range(4):
            out += a[i % 5][i // 5].to_bytes(8, "little")
        return bytes(out[:32])

RPCS = [
    "https://starknet-rpc.publicnode.com",
    "https://starknet.api.onfinality.io/public",
]

# ----------------------------------------------------------------------------- selectors
def sn_keccak(name: str) -> int:
    return int.from_bytes(_keccak256(name.encode()), "big") & ((1 << 250) - 1)


def sel(name: str) -> str:
    return hex(sn_keccak(name))


# ----------------------------------------------------------------------------- RPC
_state = {"rpc": None}


def _post(rpc, method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(
        rpc, data=body,
        headers={"Content-Type": "application/json", "User-Agent": "curl/8.5.0", "Accept": "*/*"},
    )
    with urllib.request.urlopen(req, timeout=45) as r:
        return json.load(r)


def rpc(method, params, tries=3):
    rpcs = ([_state["rpc"]] if _state["rpc"] else []) + RPCS
    last = None
    for rpc_url in rpcs:
        for _ in range(tries):
            try:
                r = _post(rpc_url, method, params)
                if "error" in r:
                    return r["error"]
                _state["rpc"] = rpc_url
                return r.get("result")
            except Exception as e:  # noqa: BLE001
                last = e
                time.sleep(1.2)
    return {"__exc": str(last)}


def _bid(b):
    return {"block_number": b} if isinstance(b, int) else b


def call_contract(addr, name, calldata=None, block=None, caller=None):
    req = {"contract_address": addr, "entry_point_selector": sel(name), "calldata": calldata or []}
    if caller:
        req["caller_address"] = caller
    return rpc("starknet_call", [req, _bid(block) if block is not None else "latest"])


def block_number():
    return rpc("starknet_blockNumber", [])


# ----------------------------------------------------------------------------- helpers
def u256(x):
    if isinstance(x, list) and len(x) == 2:
        return int(x[0], 16) + (int(x[1], 16) << 128)
    if isinstance(x, str):
        return int(x, 16)
    return x


def u256cd(v):
    return [hex(v % (1 << 128)), hex(v >> 128)]


def revert_reason(x):
    """Turn a starknet_call error object into a short human string, else None if success."""
    if not (isinstance(x, dict) and "data" in x):
        return None
    d = x["data"]
    if isinstance(d, dict):
        d = d.get("revert_error", "")
    s = str(d)
    try:
        first = s.split(",")[0].strip()
        return bytes.fromhex(first[2:]).decode("utf8", "replace")
    except Exception:  # noqa: BLE001
        return "ERR:" + s[:80]


# ----------------------------------------------------------------------------- targets
VAULTS = {
    "xSTRK":   "0x28d709c875c0ceac3dce7065bec5328186dc89fe254527084d1689910954b0a",
    "strkBTC": "0x047751b3532fabca89b0f2e35ca1cb45e5a7b11d5e3d3663dfa1f4406b45fd88",
    "xWBTC":   "0x6a567e68c805323525fe1649adb80b03cddf92c23d2629a6779f54192dffc13",
    "xtBTC":   "0x43a35c1425a0125ef8c171f1a75c6f31ef8648edcc8324b55ce1917db3f9b91",
    "xLBTC":   "0x7dd3c80de9fcc5545f0cb83678826819c79619ed7992cc06ff81fc67cd2efe0",
    "xsBTC":   "0x580f3dc564a7b82f21d40d404b3842d490ae7205e6ac07b1b7af2b4a5183dc9",
}
XSTRK_WQ = "0x0518a66e579f9eb1603f5ffaeff95d3f013788e9c37ee94995555026b9648b6"
VR       = "0x029edbca81c979decd6ee02205127e8b10c011bca1d337141170095eba690931"
STRK     = "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d"
ZERO     = "0x0"

# DefiLlama price keys (fallback coingecko ids where a token address has no feed)
PRICE_KEY = {
    "xSTRK":   "starknet:" + STRK,
    "strkBTC": "starknet:0x0787150e306e6eae6e3f79dea881770e8bbff2c1b8eb490f969669ee945b3135",
    "xWBTC":   "starknet:0x03fe2b97c1fd336e750087d68b9b867997fd64a2661ff3ca5a7c771641e8e7ac",
    "xtBTC":   "starknet:0x04daa17763b286d1e59b97c283c0b8c949994c361e426a28f743c67bdfe9a32f",
    "xLBTC":   "starknet:0x036834a40984312f7f7de8d31e3f6305b325389eaeea5b1c0664b2fb936461a4",
    "xsBTC":   "starknet:0x0593e034dda23eea82d2ba9a30960ed42cf4a01502cc2351dc9b9881f9931a68",
}


def prices():
    out = {}
    try:
        keys = ",".join(sorted(set(PRICE_KEY.values())))
        with urllib.request.urlopen("https://coins.llama.fi/prices/current/" + keys, timeout=30) as r:
            out = json.load(r).get("coins", {})
    except Exception as e:  # noqa: BLE001
        out = {"__err": str(e)}
    return out


# ----------------------------------------------------------------------------- access-control map
# (name, n_felts) of every external entry point.  n_felts = flat calldata length with zero args.
LST_EXT = [
    ("approve", 3), ("transfer", 3), ("transferFrom", 4), ("transfer_from", 4),
    ("deposit", 3), ("mint", 3), ("withdraw", 4), ("redeem", 4),
    ("deposit_to_validator", 4), ("deposit_with_referral", 6),
    ("send_to_withdraw_queue", 2), ("before_unstake", 3),
    ("set_config", 3), ("upgrade", 1), ("initializer", 1),
]
WQ_EXT = [
    ("request_withdrawal", 5), ("claim_withdrawal", 1), ("claim_withdrawal_to", 2),
    ("take_funds", 2), ("reduce_total_queue_amount", 4),
    ("approve", 3), ("transferFrom", 4), ("transfer_from", 4),
    ("safeTransferFrom", 5), ("safe_transfer_from", 5),
    ("setApprovalForAll", 2), ("set_approval_for_all", 2),
    ("set_config", 3), ("upgrade", 1), ("initializer", 1),
]
VR_EXT = [
    ("add_validator", 2), ("update_validator", 3), ("add_delegator", 4),
    ("stake_to_validator", 3), ("receive_funds", 3), ("claim_rewards_for_validator", 2),
    ("on_switch", 2), ("migrate_delegators", 2), ("send_to_withdrawal_queue", 3),
    ("set_validator_stake", 3), ("update_supported_token", 6), ("set_settings", 2),
    ("upgrade", 1),
]


def ac_map(addr, specs, block):
    rows = []
    for name, n in specs:
        r = call_contract(addr, name, [hex(0)] * n, block=block)
        reason = revert_reason(r)
        if reason is None:
            rows.append({"fn": name, "result": "SUCCESS(caller=0)", "gate": None})
        else:
            gated = any(s in reason for s in (
                "role", "Only ", "Invalid caller", "only ", "not allowed", "owner",
                "delegator member", "not found", "Zero address caller",
            ))
            rows.append({"fn": name, "revert": reason,
                         "gate": "CALLER-GATED" if gated else "no-caller-gate"})
    return rows


# ----------------------------------------------------------------------------- main
def main():
    outdir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "ci-out")
    outdir = os.path.abspath(outdir)
    os.makedirs(outdir, exist_ok=True)

    blk = block_number()
    if isinstance(blk, dict):
        raise SystemExit("cannot reach a Starknet RPC: %r" % blk)
    ts = None
    bh = rpc("starknet_getBlockWithTxHashes", [{"block_number": blk}])
    if isinstance(bh, dict):
        ts = bh.get("timestamp")
    res = {"generated_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
           "block": blk, "block_timestamp": ts, "chain_id": rpc("starknet_chainId", []),
           "vaults": {}, "wq": {}, "vr": {}, "erc4626_roundtrip": {},
           "access_control": {}, "prices": prices()}

    # ---- vaults
    for name, addr in VAULTS.items():
        asset = call_contract(addr, "asset", block=blk)
        asset = asset[0] if isinstance(asset, list) else asset
        ta = u256(call_contract(addr, "total_assets", block=blk))
        ts_ = u256(call_contract(addr, "total_supply", block=blk))
        dec = call_contract(addr, "decimals", block=blk)
        adec = call_contract(asset, "decimals", block=blk)
        cfg = call_contract(addr, "get_config", block=blk)
        v = {
            "address": addr, "asset": asset,
            "decimals": int(dec[0], 16) if isinstance(dec, list) else dec,
            "asset_decimals": int(adec[0], 16) if isinstance(adec, list) else adec,
            "total_assets_raw": ta, "total_supply_raw": ts_,
            "total_assets": ta, "total_supply": ts_,
            "rate_assets_per_share": (ta / ts_) if ts_ else None,
            "convert_to_assets_1e18": u256(call_contract(addr, "convert_to_assets", u256cd(10**18), block=blk)),
            "convert_to_shares_1e18": u256(call_contract(addr, "convert_to_shares", u256cd(10**18), block=blk)),
            "is_paused": call_contract(addr, "is_paused", block=blk),
            "governor": call_contract(addr, "governor", block=blk),
            "config_raw": cfg,
            "vault_asset_balance": u256(call_contract(asset, "balanceOf", [addr], block=blk)),
        }
        if isinstance(cfg, list) and len(cfg) >= 3:
            v["treasury"], v["withdraw_queue"], v["validator_registry"] = cfg[0], cfg[1], cfg[2]
        res["vaults"][name] = v

    # ---- xSTRK withdrawal queue
    wq = {"address": XSTRK_WQ, "get_queue_state": call_contract(XSTRK_WQ, "get_queue_state", block=blk),
          "governor": call_contract(XSTRK_WQ, "governor", block=blk)}
    for var in ["lstDisp", "token", "claim_time", "unprocessed_withdraw_queue_amount",
                "intransit_amount", "cumulative_requested_amount", "last_request_id"]:
        wq["storage_" + var] = rpc("starknet_getStorageAt", [XSTRK_WQ, hex(sn_keccak(var)), {"block_number": blk}])
    qs = wq["get_queue_state"]
    if isinstance(qs, list) and len(qs) == 7:
        wq["decoded"] = {"max_request_id": int(qs[0], 16),
                         "unprocessed": u256(qs[1:3]), "intransit": u256(qs[3:5]),
                         "cumulative_requested": u256(qs[5:7])}
    res["wq"] = wq

    # ---- validator registry
    vr = {"address": VR, "get_settings": call_contract(VR, "get_settings", block=blk),
          "get_total_validators": call_contract(VR, "get_total_validators", block=blk),
          "total_stake_STRK": u256(call_contract(VR, "total_stake", [STRK], block=blk)),
          "get_token_config_STRK": call_contract(VR, "get_token_config", [STRK], block=blk),
          "governor": call_contract(VR, "governor", block=blk)}
    res["vr"] = vr

    # ---- ERC-4626 round trip (deposit -> redeem) on xSTRK, exact + preview
    ta, tsp = res["vaults"]["xSTRK"]["total_assets"], res["vaults"]["xSTRK"]["total_supply"]
    rt = {"amounts": [], "max_profit_wei": 0, "worst_case_wei": 0}
    amts = [1, 2, 10**6, 10**12, 10**15, 10**18, 10**19, 10**21, 10**24, 2 * 10**24, 10**26]
    for a in amts:
        shares_math = (a * tsp) // ta if ta else 0
        back_math = (shares_math * ta) // tsp if tsp else 0
        shares_prev = u256(call_contract(VAULTS["xSTRK"], "preview_deposit", u256cd(a), block=blk))
        back_prev = u256(call_contract(VAULTS["xSTRK"], "preview_redeem", u256cd(shares_prev), block=blk))
        rt["amounts"].append({
            "assets_in": a,
            "shares_deposit_floor_math": shares_math,
            "assets_out_redeem_floor_math": back_math,
            "net_math": back_math - a,
            "shares_preview_deposit": shares_prev,
            "assets_preview_redeem": back_prev,
            "net_preview": back_prev - a,
        })
        rt["max_profit_wei"] = max(rt["max_profit_wei"], back_math - a, back_prev - a)
        rt["worst_case_wei"] = min(rt["worst_case_wei"], back_math - a, back_prev - a)
    # withdraw->redeem (assets in, shares ceil, redeem floor)
    rt["withdraw_roundtrip"] = []
    for a in [1, 10**12, 10**18, 10**21]:
        sh = (a * tsp + ta - 1) // ta if ta else 0  # ceil
        back = (sh * ta) // tsp if tsp else 0
        rt["withdraw_roundtrip"].append({"assets_in": a, "shares_ceil": sh, "assets_out_floor": back, "net": back - a})
    res["erc4626_roundtrip"] = rt

    # ---- total_assets composition check: total_assets ?= VR.total_stake(STRK) - WQ.unprocessed
    comp = {
        "total_assets": ta,
        "vr_total_stake_STRK": vr["total_stake_STRK"],
        "wq_unprocessed": wq.get("decoded", {}).get("unprocessed"),
    }
    if comp["wq_unprocessed"] is not None:
        comp["total_stake_minus_unprocessed"] = comp["vr_total_stake_STRK"] - comp["wq_unprocessed"]
        comp["delta_vs_total_assets"] = comp["total_stake_minus_unprocessed"] - comp["total_assets"]
    res["total_assets_composition"] = comp

    # ---- access control map (caller = 0x0, the most unprivileged)
    res["access_control"] = {
        "xSTRK_LST": ac_map(VAULTS["xSTRK"], LST_EXT, blk),
        "xSTRK_WQ": ac_map(XSTRK_WQ, WQ_EXT, blk),
        "ValidatorRegistry": ac_map(VR, VR_EXT, blk),
        "note": "caller forced to 0x0 by starknet_call; a CALLER-GATED revert proves the gate, "
                "a no-caller-gate revert proves the entry point is callable by any (unprivileged) address",
    }

    # ---- targeted probes with REAL arguments (caller still 0x0)
    val0 = call_contract(VR, "get_validator_by_index", [hex(0)], block=blk)
    val0 = val0[0] if isinstance(val0, list) else "0x0"
    ATT = "0x0123456789abcdef0123456789abcdef01234567"
    probes = []
    def probe(label, addr, fn, cd):
        r = call_contract(addr, fn, cd, block=blk)
        probes.append({"probe": label, "fn": fn, "revert": revert_reason(r),
                       "success": revert_reason(r) is None})
    probe("WQ.request_withdrawal mismatched (assets=1000e18,shares=0) caller=0",
          XSTRK_WQ, "request_withdrawal", u256cd(1000 * 10**18) + u256cd(0) + [ATT])
    probe("WQ.request_withdrawal (assets=0,shares=1e18) caller=0",
          XSTRK_WQ, "request_withdrawal", u256cd(0) + u256cd(10**18) + [ATT])
    probe("WQ.reduce_total_queue_amount(1,0) caller=0",
          XSTRK_WQ, "reduce_total_queue_amount", u256cd(1) + u256cd(0))
    probe("WQ.take_funds(1e18) caller=0 (pulls from CALLER)",
          XSTRK_WQ, "take_funds", u256cd(10**18))
    probe("LST.send_to_withdraw_queue(1e18) caller=0",
          VAULTS["xSTRK"], "send_to_withdraw_queue", u256cd(10**18))
    probe("LST.before_unstake(ATT,1,0) caller=0",
          VAULTS["xSTRK"], "before_unstake", [ATT, "0x1", "0x0"])
    probe("VR.send_to_withdrawal_queue(WQ,STRK,1e18) caller=0",
          VR, "send_to_withdrawal_queue", [XSTRK_WQ, STRK, hex(10**18)])
    probe("VR.claim_rewards_for_validator(v0,STRK) caller=0 (permissionless?)",
          VR, "claim_rewards_for_validator", [val0, STRK])
    probe("VR.receive_funds(v0,STRK,1e18) caller=0 (pulls from CALLER)",
          VR, "receive_funds", [val0, STRK, hex(10**18)])
    # allowances / balances that bound the take_funds/receive_funds donation paths
    res["allowances"] = {
        "STRK_allowance_VR_to_WQ": u256(call_contract(STRK, "allowance", [VR, XSTRK_WQ], block=blk)),
        "STRK_allowance_LST_to_WQ": u256(call_contract(STRK, "allowance", [VAULTS["xSTRK"], XSTRK_WQ], block=blk)),
        "STRK_balance_WQ": u256(call_contract(STRK, "balanceOf", [XSTRK_WQ], block=blk)),
        "STRK_balance_VR": u256(call_contract(STRK, "balanceOf", [VR], block=blk)),
        "STRK_balance_LST": u256(call_contract(STRK, "balanceOf", [VAULTS["xSTRK"]], block=blk)),
    }
    res["targeted_probes"] = probes

    # ---- class hashes (one implementation per family)
    res["class_hashes"] = {
        "xSTRK_vault": rpc("starknet_getClassHashAt", [{"block_number": blk}, VAULTS["xSTRK"]]),
        "xSTRK_WQ": rpc("starknet_getClassHashAt", [{"block_number": blk}, XSTRK_WQ]),
        "ValidatorRegistry": rpc("starknet_getClassHashAt", [{"block_number": blk}, VR]),
        "all_vaults_same_class": len({str(rpc("starknet_getClassHashAt", [{"block_number": blk}, a]))
                                      for a in VAULTS.values()}) == 1,
    }

    # ---- USD
    pr = res["prices"]
    usd_total = 0.0
    for name, v in res["vaults"].items():
        key = PRICE_KEY[name]
        p = pr.get(key, {}).get("price")
        adec = v["asset_decimals"]
        amt = v["total_assets"] / (10 ** adec)
        usd = amt * p if p else None
        v["underlying_amount"] = amt
        v["price_usd"] = p
        v["total_assets_usd"] = usd
        if usd:
            usd_total += usd
    res["total_assets_usd_all_vaults"] = usd_total

    path = os.path.join(outdir, "endur-live.json")
    with open(path, "w") as f:
        json.dump(res, f, indent=1)
    print("[endur] block", blk, "-> wrote", path)
    print("[endur] total_assets_usd_all_vaults = %.2f" % usd_total)
    print("[endur] roundtrip max_profit_wei =", rt["max_profit_wei"], " worst_case_wei =", rt["worst_case_wei"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
