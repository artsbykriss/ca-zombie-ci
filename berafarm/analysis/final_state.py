#!/usr/bin/env python3
"""Final on-chain snapshot for the BeraFarm ZH4-06 report.
Read-only, keyless public RPC. Writes analysis/live_state.json."""
import json
import sys
import urllib.request

sys.path.insert(0, "/home/heisenberg/CA/berafarm/analysis")
from rpc import block_number, eth_call, get_code, impl_slot, rpc  # noqa: E402
from eth_utils import keccak  # noqa: E402
from eth_abi import encode  # noqa: E402

A = "/home/heisenberg/CA/berafarm/analysis/"
HONEY = "0xfcbd14dc51f0a4d49d5e53c2e0950e0bc26d0dce"
USDE = "0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34"
ISLAND = "0xe5a2ab5d2fb268e5ff43a5564e44c3309609aff9"
GAUGE = "0x75da1d58a8d97f7b626224e7e71fa44db13689f2"
STRAT = "0x1ce23321a72f2dae96809cc6192f053a7ad5d8e4"
SWAPCTL = "0x1cac0625ee3a4679dce7f9dc921ecfdd5c378987"
VAULT0 = "0x4a3c8fdd55017773fee33de4aa7e12dd60b0a054"
VAULT1 = "0xeb9ce8e12898beb918a7e36a1c30ee094ebcba0a"
VAULT3 = "0xea20a9d1b464fff7c8a6a9039c3cf94f0a09471d"
MANAGER = "0x9546b34291393fb247db7d4c677f1394d4bbe0dd"
REGISTRY = "0x0c5ab414845386758c50e7a5e08b59964a02f2bd"
ORACLE = "0xeb2cc2df8698250fb7fb6f310cbca6b3266e3b80"
CONFIG = "0x636d34ddae1459bcdeb872172b67d0c376cac493"
FEE = "0xe5061b0d8366e586a85ccde01011980247e09ca4"
POOL = "0x9e4c460645b39628c631003eb9911651d5441dd8"


def sig(s):
    name = s[: s.index(")") + 1]
    return "0x" + keccak(name.encode()).hex()[:8]


def call(to, signature, args=(), blk="latest"):
    types = []
    if args:
        inside = signature[signature.index("(") + 1: signature.index(")")]
        types = [p.strip() for p in inside.split(",") if p.strip()]
    data = sig(signature)
    if args:
        data += encode(types, list(args)).hex()
    out = eth_call(to, data, blk)
    return out


def u(to, signature, args=(), blk="latest"):
    return int(call(to, signature, args, blk), 16)


def main():
    b = block_number()
    hist = 27_270_000
    out = {"chain": "berachain", "chain_id": 80094, "latest_block": b, "historical_block": hist,
           "rpc": "https://rpc.berachain.com (public, keyless)"}

    proxis = {
        "kodiak_strategy": STRAT,
        "kodiak_swap_controller": SWAPCTL,
        "vault0_BUSD_HONEY": VAULT0,
        "vault1_WBERA": VAULT1,
        "vault3_undoc": VAULT3,
        "strategy_manager0": MANAGER,
        "protocol_registry": REGISTRY,
        "price_oracle": ORACLE,
        "vault_config0": CONFIG,
        "fee_module0": FEE,
    }
    out["current_impls"] = {k: impl_slot(v) for k, v in proxis.items()}
    out["historical_impls_27270000"] = {k: impl_slot(v, hist) for k, v in proxis.items()}

    out["protocol_paused"] = u(REGISTRY, "getProtocolState()(bool)")
    out["vault0"] = {
        "currency": "HONEY",
        "tvl_honey": u(VAULT0, "currentTrancheInformation()(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)") if False else None,
    }
    info = [u(VAULT0, "currentTrancheInformation()(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)")]
    # read tuple as raw 9 words
    raw = call(VAULT0, "currentTrancheInformation()(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)")
    words = [int(raw[i:i + 64], 16) for i in range(2, 2 + 9 * 64, 64)]
    out["vault0"] = {
        "currency": "HONEY",
        "total_actual_senior": words[0] / 1e18,
        "total_actual_junior": words[1] / 1e18,
        "senior_investments": words[4] / 1e18,
        "junior_investments": words[5] / 1e18,
        "strategy_nav": words[6] / 1e18,
        "senior_supply": words[7] / 1e18,
        "junior_supply": words[8] / 1e18,
        "is_whitelisted_vault": u(CONFIG, "isWhitelistedVault()(bool)"),
        "deposits_paused": u(CONFIG, "isDepositPausedState()(bool)"),
        "withdrawals_paused": u(CONFIG, "isWithdrawPausedState()(bool)"),
        "vault_tvl_limit": u(CONFIG, "getVaultTvlLimit()(uint256)") / 1e18,
        "junior_tranche_limit": u(CONFIG, "getTrancheLimit(uint256)(uint256)", (1,)) / 1e18,
        "vault_swap_slippage_bps": u(CONFIG, "getVaultSwapSlippage()(uint256)"),
        "vault_lp_slippage_bps": u(CONFIG, "getVaultLpSlippage()(uint256)"),
        "senior_entry_fee_bps": u(FEE, "seniorEntryFee()(uint256)"),
        "senior_exit_fee_bps": u(FEE, "seniorExitFee()(uint256)"),
        "junior_entry_fee_bps": u(FEE, "juniorEntryFee()(uint256)"),
        "junior_exit_fee_bps": u(FEE, "juniorExitFee()(uint256)"),
    }

    # strategy list + NAV
    raw = call(MANAGER, "getStrategyInformation()(address[],uint256[])")
    # decode offset pairs manually: first word offset to addresses, second to ratios
    addr_off = int(raw[2:66], 16) * 2 + 2
    n = int(raw[addr_off:addr_off + 64], 16)
    addrs = ["0x" + raw[addr_off + 64 + i * 64 + 24: addr_off + 64 + (i + 1) * 64] for i in range(n)]
    nav = call(MANAGER, "getIndividualAndAllStrategyBalance()(uint256[],uint256)")
    nav_off = int(nav[2:66], 16) * 2 + 2
    out["strategies"] = []
    labels = ["HubBend-1", "HubBend-2", "Dolomite", "Kodiak"]
    for i, a in enumerate(addrs):
        val = int(nav[nav_off + 64 + i * 64: nav_off + 64 + (i + 1) * 64], 16) / 1e18
        out["strategies"].append({"label": labels[i] if i < len(labels) else f"s{i}", "address": a,
                                  "nav_honey": val, "impl": impl_slot(a)})
    out["manager_total_nav_honey"] = int(nav[66:130], 16) / 1e18

    out["kodiak_strategy"] = {
        "getTokenBalance": u(STRAT, "getTokenBalance()(uint256)") / 1e18,
        "getUnderlyingBalance": u(STRAT, "getUnderlyingBalance()(uint256)") / 1e18,
        "hubVault": "0x75da1d58a8d97f7b626224e7e71fa44db13689f2",
        "island": ISLAND,
        "strategyManager": "0x9546b34291393fb247db7d4c677f1394d4bbe0dd",
        "gauge_balanceOf": u(GAUGE, "balanceOf(address)(uint256)", (STRAT,)) / 1e18,
        "gauge_delegateTotalStaked": u(GAUGE, "getTotalDelegateStaked(address)(uint256)", (STRAT,)) / 1e18,
        "gauge_paused": u(GAUGE, "paused()(bool)"),
    }
    out["island"] = {
        "address": ISLAND,
        "paused": u(ISLAND, "paused()(bool)"),
        "totalSupply": u(ISLAND, "totalSupply()(uint256)") / 1e18,
        "underlying_usde": u(ISLAND, "getUnderlyingBalances()(uint256,uint256)") if False else None,
    }
    raw = call(ISLAND, "getUnderlyingBalances()(uint256,uint256)")
    out["island"]["underlying_usde"] = int(raw[2:66], 16) / 1e18
    out["island"]["underlying_honey"] = int(raw[66:130], 16) / 1e18
    out["island"]["pool"] = POOL
    raw = call(POOL, "slot0()(uint160,int24,uint16,uint16,uint16,uint8,bool)")
    out["island"]["pool_tick"] = int(raw[66:130], 16)
    out["island"]["pool_sqrtPriceX96"] = int(raw[2:66], 16)

    # pre-patch historical snapshot
    raw = call(VAULT0, "currentTrancheInformation()(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)", (), hist)
    w = [int(raw[i:i + 64], 16) for i in range(2, 2 + 9 * 64, 64)]
    nav = call(MANAGER, "getIndividualAndAllStrategyBalance()(uint256[],uint256)", (), hist)
    nav_off = int(nav[2:66], 16) * 2 + 2
    out["historical_27270000"] = {
        "vault_nav_honey": w[6] / 1e18,
        "senior_investments": w[4] / 1e18,
        "junior_investments": w[5] / 1e18,
        "junior_supply": w[8] / 1e18,
        "strategy_navs": [int(nav[nav_off + 64 + i * 64: nav_off + 64 + (i + 1) * 64], 16) / 1e18 for i in range(4)],
        "kodiak_getTokenBalance": u(STRAT, "getTokenBalance()(uint256)", (), hist) / 1e18,
        "island_paused": u(ISLAND, "paused()(bool)", (), hist),
    }

    # prices
    try:
        u1 = "https://coins.llama.fi/prices/current/coingecko:honey,coingecko:berachain-bera"
        p = json.load(urllib.request.urlopen(u1, timeout=30))["coins"]
        honey = p["coingecko:honey"]["price"]
        bera = p["coingecko:berachain-bera"]["price"]
        out["prices_usd"] = {"HONEY": honey, "BERA": bera, "timestamp": p["coingecko:honey"]["timestamp"]}
    except Exception as e:
        out["prices_usd_error"] = str(e)

    out["usd"] = {
        "vault0_honey_usd": out["vault0"]["strategy_nav"] * out.get("prices_usd", {}).get("HONEY", 0.983),
        "vault1_wbera_usd": 1607.81 * out.get("prices_usd", {}).get("BERA", 0.18),
        "total_usd": out["vault0"]["strategy_nav"] * out.get("prices_usd", {}).get("HONEY", 0.983) + 1607.81 * out.get("prices_usd", {}).get("BERA", 0.18),
    }
    json.dump(out, open(A + "live_state.json", "w"), indent=1)
    print(json.dumps(out, indent=1)[:6000])


if __name__ == "__main__":
    main()
