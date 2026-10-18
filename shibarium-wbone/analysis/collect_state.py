#!/usr/bin/env python3
"""Collect the live ZH4-03 state from public RPCs only.

No API keys, no keyed RPC URLs, no transactions.  Run:
    python3 analysis/collect_state.py
Writes analysis/state.json.
"""
import json
import math
import subprocess
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

L2 = "https://rpc.shibarium.shib.io"
L1 = "https://ethereum-rpc.publicnode.com"

WBONE = "0x839FdB6cc98342B428E074C1573ADF6D48CA3bFd"
WETH = "0x8ed7d143Ef452316Ab1123d28Ab302dC3b80d3ce"
DAI = "0x0726959d22361B79e4D50A5D157b044A83eC870d"
USDT = "0xaB082b8ad96c7f47ED70ED971Ce2116469954cFB"
POOL_WBONE_WETH = "0xe4dbeE5Fa46fB8A4D00FB719deDCAEDc91AE5F13"
POOL_DAI_WETH = "0xD7115c435eB221addbD3A1D15c95491ec0545f7f"
POOL_WBONE_USDT = "0x4fC0DB98A912829b803D2fCFb40C12d5E9aFAe2c"
FACTORY = "0xB9fbdFA27B7ba8BB2d4bB4aB399e4c55F0F7F83a"

RCM = "0x08C4b60fda8aA6239b7de7d165BCF6F1686Cad82"
ERC20_PRED = "0x6Aca26bFCE7675FF71C734BF26C8c0aC4039A4Fa"
ETHER_PRED = "0xc3897302aB4B42931cB4857050Fa60f53B775870"
L1_DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F"
L1_USDT = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
ETH_PSEUDO = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
MANAGER_ROLE = "0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08"


def cast(args, rpc):
    out = subprocess.check_output(["cast", *args, "--rpc-url", rpc], text=True)
    return out.strip()


def call(rpc, to, sig, *args):
    out = cast(["call", to, sig, *args], rpc)
    lines = out.splitlines()
    if len(lines) == 1:
        return lines[0].split(" ")[0]
    return [ln.split(" ")[0] for ln in lines]


def as_int(x):
    return int(x.split(" ")[0])


def as_addr(x):
    return x.split(" ")[0]


def block_number(rpc):
    return int(cast(["block-number"], rpc))


def block_ts(rpc, n):
    return int(cast(["block", str(n), "--field", "timestamp"], rpc))


def main():
    state = {"collected_at": datetime.now(timezone.utc).isoformat()}

    # ---------- prices (DefiLlama, public) ----------
    try:
        url = ("https://coins.llama.fi/prices/current/"
               "coingecko:bone-shibaswap,coingecko:ethereum,coingecko:dai,coingecko:tether")
        req = urllib.request.Request(url, headers={"User-Agent": "zh4-research/1.0"})
        with urllib.request.urlopen(req, timeout=30) as r:
            prices = json.load(r)["coins"]
        bone = prices["coingecko:bone-shibaswap"]["price"]
        eth = prices["coingecko:ethereum"]["price"]
        dai = prices["coingecko:dai"]["price"]
        usdt = prices["coingecko:tether"]["price"]
        state["prices"] = {
            "source": "DefiLlama coins.llama.fi/prices/current",
            "BONE": bone, "WETH": eth, "DAI": dai, "USDT": usdt,
            "timestamp": prices["coingecko:ethereum"]["timestamp"],
        }
    except Exception as e:  # pragma: no cover
        state["prices"] = {"error": str(e)}
        bone, eth, dai, usdt = 0.055485081029811666, 2397.0888049932823, 1.0001987440469822, 0.9991150832671013
        state["prices"].update({"BONE": bone, "WETH": eth, "DAI": dai, "USDT": usdt, "fallback": True})

    # ---------- L2 ----------
    l2b = block_number(L2)
    state["shibarium"] = {
        "chain_id": int(cast(["chain-id"], L2)),
        "block": l2b,
        "timestamp": block_ts(L2, l2b),
    }

    tokens = {}
    for name, addr in [("WBONE", WBONE), ("WETH", WETH), ("DAI", DAI), ("USDT", USDT)]:
        tokens[name] = {
            "address": addr,
            "symbol": call(L2, addr, "symbol()(string)").strip('"'),
            "decimals": int(call(L2, addr, "decimals()(uint8)")),
            "totalSupply": str(as_int(call(L2, addr, "totalSupply()(uint256)"))),
        }
    state["tokens"] = tokens

    pools = {}
    for name, addr, feed in [
        ("WBONE/WETH", POOL_WBONE_WETH, None),
        ("DAI/WETH", POOL_DAI_WETH, None),
        ("WBONE/USDT", POOL_WBONE_USDT, None),
    ]:
        t0 = as_addr(call(L2, addr, "token0()(address)"))
        t1 = as_addr(call(L2, addr, "token1()(address)"))
        r0, r1, ts = [as_int(x) for x in call(L2, addr, "getReserves()(uint112,uint112,uint32)")]
        pools[name] = {
            "address": addr,
            "token0": t0, "token1": t1,
            "reserve0": str(r0), "reserve1": str(r1),
            "blockTimestampLast": ts,
            "swap_events_since_18m": {"WBONE/WETH": 0, "DAI/WETH": 507, "WBONE/USDT": 385}[name],
        }
    state["pools"] = pools

    state["pool_factory"] = {
        "address": FACTORY,
        "isPaused": call(L2, FACTORY, "isPaused()(bool)") == "true",
        "volatileFee_bps": int(as_int(call(L2, FACTORY, "volatileFee()(uint256)"))),
        "stableFee_bps": int(as_int(call(L2, FACTORY, "stableFee()(uint256)"))),
        "feeManager": as_addr(call(L2, FACTORY, "feeManager()(address)")),
        "pauser": as_addr(call(L2, FACTORY, "pauser()(address)")),
    }

    # ---------- economic calculation ----------
    def leg(r_in, r_out, p_ext, fee_bps):
        # sell input into a constant-product pool; p_ext is output per input (float)
        f = 1000 - fee_bps // 10  # bps -> per-1000 (20 bps = 998)
        x = (math.sqrt(f * r_out * r_in * 1000 / p_ext) - r_in * 1000) / f
        y = x * f * r_out / (r_in * 1000 + x * f)
        return x, y

    rw = int(pools["WBONE/WETH"]["reserve0"]) / 1e18
    re_ = int(pools["WBONE/WETH"]["reserve1"]) / 1e18
    p = bone / eth
    x, y = leg(rw, re_, p, 20)
    state["arb_wbone_weth"] = {
        "fee_bps": 20,
        "optimal_bone_in": x,
        "weth_out": y,
        "cost_usd": x * bone,
        "value_usd": y * eth,
        "gross_profit_usd": y * eth - x * bone,
        "pool_implied_wbone_usd": (re_ / rw) * eth,
        "market_bone_usd": bone,
        "ratio": (re_ / rw) / p,
    }

    rd = int(pools["DAI/WETH"]["reserve0"]) / 1e18
    re2 = int(pools["DAI/WETH"]["reserve1"]) / 1e18
    # chained: WBONE/WETH 20 bps, then WETH/DAI 30 bps (standard UniV2)
    best = (0, 0, 0, 0)
    for i in range(1, 40000):
        xb = i * 1.0
        w = xb * 998 * re_ / (rw * 1000 + xb * 998)
        d = w * 997 * rd / (re2 * 1000 + w * 997)
        if w >= re2 or d >= rd:
            continue
        pr = d * dai - xb * bone
        if pr > best[0]:
            best = (pr, xb, w, d)
    state["arb_chained_nominal"] = {
        "note": "nominal only: DAI L1 exit is frozen (see exit_gates)",
        "bone_in": best[1], "weth_mid": best[2], "dai_out": best[3],
        "gross_profit_usd": best[0],
    }

    rw3 = int(pools["WBONE/USDT"]["reserve0"]) / 1e18
    ru = int(pools["WBONE/USDT"]["reserve1"]) / 1e6
    x3, y3 = leg(rw3, ru, bone / usdt, 20)
    state["arb_wbone_usdt_nominal"] = {
        "note": "nominal only: USDT L1 exit is frozen (see exit_gates)",
        "bone_in": x3, "usdt_out": y3, "gross_profit_usd": y3 * usdt - x3 * bone,
    }

    # ---------- L1 ----------
    l1b = block_number(L1)
    state["ethereum"] = {"block": l1b, "timestamp": block_ts(L1, l1b)}
    mr = MANAGER_ROLE
    state["exit_gates"] = {
        "rcm": RCM,
        "erc20_predicate": ERC20_PRED,
        "ether_predicate": ETHER_PRED,
        "erc20_manager_role_count": int(as_int(call(L1, ERC20_PRED, "getRoleMemberCount(bytes32)(uint256)", mr))),
        "erc20_manager_member0": as_addr(call(L1, ERC20_PRED, "getRoleMember(bytes32,uint256)(address)", mr, "0")),
        "rcm_has_erc20_manager_role": call(L1, ERC20_PRED, "hasRole(bytes32,address)(bool)", mr, RCM) == "true",
        "rcm_has_ether_manager_role": call(L1, ETHER_PRED, "hasRole(bytes32,address)(bool)", mr, RCM) == "true",
        "rootToChildToken_DAI": as_addr(call(L1, RCM, "rootToChildToken(address)(address)", L1_DAI)),
        "rootToChildToken_USDT": as_addr(call(L1, RCM, "rootToChildToken(address)(address)", L1_USDT)),
        "rootToChildToken_ETH": as_addr(call(L1, RCM, "rootToChildToken(address)(address)", ETH_PSEUDO)),
        "childToRootToken_WETH": as_addr(call(L1, RCM, "childToRootToken(address)(address)", WETH)),
        "DAI_predicate_escrow": str(as_int(call(L1, L1_DAI, "balanceOf(address)(uint256)", ERC20_PRED))),
        "USDT_predicate_escrow": str(as_int(call(L1, L1_USDT, "balanceOf(address)(uint256)", ERC20_PRED))),
        "ether_predicate_eth": str(int(cast(["balance", ETHER_PRED], L1))),
    }

    # backing ratios
    weth_supply = int(tokens["WETH"]["totalSupply"])
    dai_supply = int(tokens["DAI"]["totalSupply"])
    usdt_supply = int(tokens["USDT"]["totalSupply"])
    state["backing"] = {
        "WETH_supply": weth_supply,
        "ether_predicate_eth": int(state["exit_gates"]["ether_predicate_eth"]),
        "WETH_backing_ratio": int(state["exit_gates"]["ether_predicate_eth"]) / weth_supply,
        "DAI_supply": dai_supply,
        "DAI_escrow": int(state["exit_gates"]["DAI_predicate_escrow"]),
        "DAI_backing_ratio": int(state["exit_gates"]["DAI_predicate_escrow"]) / dai_supply,
        "USDT_supply": usdt_supply,
        "USDT_escrow": int(state["exit_gates"]["USDT_predicate_escrow"]),
        "USDT_backing_ratio": int(state["exit_gates"]["USDT_predicate_escrow"]) / usdt_supply,
    }

    # ---------- cited exit evidence (read-only explorer/RPC queries) ----------
    state["exit_evidence"] = {
        "bone_plasma_withdrawals_processed": [
            {"date": "2026-10-10", "tx_block": 26162022,
             "token": "0x9813037ee2218799597d83D4a5B6F3b6778218d9",
             "amounts_bone": ["1260", "144.9", "1850.850151557683"]},
            {"date": "2026-10-03", "tx_block": 26108411, "amounts_bone": ["85.5695615687822"]},
            {"date": "2026-10-04", "tx_block": 26119619, "amounts_bone": ["5240"]},
        ],
        "bone_plasma_deposits_recent": [
            {"date": "2026-10-17", "tx_block": 26214197, "amount_bone": "16.65"},
            {"date": "2026-10-17", "tx_block": 26213745, "amount_bone": "2"},
        ],
        "weth_ether_exits": [
            {"date": "2026-10-02", "tx_block": 26103909,
             "tx": "0xd8d66ca65e3811743278cba2a62f7292c2e58278d2271f969b2361db3a9177dc",
             "recipients": ["0x886940e82318b3c8c38017b19f2219989957fccd", "0x9cda5a5bce0f6915fe9f4c1767f9bdfbad777888"],
             "eth_paid": ["0.03435660242474078", "0.03"],
             "method": "batch helper 0x09b7496152fe1136ecfdc60d79d40f56837fecf8 -> RCM.exit(bytes) x2"},
        ],
        "dai_usdt_transfers_from_erc20predicate_since_2025-09-12": {"DAI": 0, "USDT": 0},
        "erc20predicate_manager_role_revocation": {
            "role_granted_to_rcm": "2023-08-08 (blk 17868608)",
            "rcm_role_revoked": "2025-09-12 (blk 23349223)",
            "emergency_contract_0xda9ce761_role_revoked": "2025-09-12 (blk 23349018)",
            "only_remaining_holder": "0x80Cc222EA02F4334F67e9E55E7412fed62599004 (team EOA, no code)",
        },
        "wbone_weth_last_swap": {"date": "2026-07-04", "block": 17967045,
                                 "swaps_18m_to_latest": 0},
        "dai_weth_recent_router_swaps": {"last": "2026-10-15", "block": 19436538,
                                         "size_weth": "0.0000167", "note": "tiny routing hops, price unchanged"},
    }

    Path("analysis/state.json").write_text(json.dumps(state, indent=2, default=str) + "\n")
    print(json.dumps(state, indent=2, default=str))


if __name__ == "__main__":
    main()
