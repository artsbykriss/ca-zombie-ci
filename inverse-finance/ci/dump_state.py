#!/usr/bin/env python3
"""Read-only Inverse Finance live-state + economics dump for CI. Writes only ci-out/state.json.
No secrets or keyed RPC URLs are written."""
import json, os, subprocess, sys, time, urllib.request

RPC = os.environ.get("FORK_RPC_URL") or os.environ.get("RPC_URL") or "https://ethereum-rpc.publicnode.com"
GOV = "0xBeCCB6bb0aa4ab551966A7E4B97cec74bb359Bf6"
TL = "0x926dF14a23BE491164dCF93f4c468A50ef659D5B"
DOLA = "0x865377367054516e17014CcdED1e7d814EDC9ce4"
INV = "0x41D5D79431A913C4aE7d69a668ecdfE5fF9DFB68"
XINV = "0x1637e4e9941D55703a7A5E7807d6aDA3f7DCD61B"
GUARDIAN = "0x941c2699eC7E55a50Bde030d8E1e70649839259D"
DEPLOYER = "0x3FcB35a1CbFB6007f9BC638D388958Bc4550cB28"
RWG = "0x4b6c63E6a94ef26E2dF60b89372db2d8e211F1B7"
INCUMBENT = "0x962228a90eaC69238c7D1F216d80037e61eA9255"
DBR = "0xAD038Eb671c44b853887A7E32528FaB35dC5D710"
WBTC = "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"
SDOLA = "0xb45ad160634c528cc3d2926d9807104fa3157305"
POOL_SUSDE = "0x744793b5110f6ca9cc7cdfe1ce16677c3eb192ef"
POOL_SUSDS = "0x8b83c4aa949254895507d09365229bc3a8c7f710"
SUSDE = "0x9D39A5DE30e57443BfF2A8307A4256c8797A3497"
SUSDS = "0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD"


def cast(args):
    out = subprocess.check_output(["cast", *args, "--rpc-url", RPC], text=True, stderr=subprocess.STDOUT)
    return out.strip()


def call(to, sig, *args, block=None):
    a = ["call", to, sig, *[str(x) for x in args]]
    if block is not None:
        a += ["--block", str(block)]
    return cast(a)


def num(x):
    try:
        return int(x.split()[0])
    except Exception:
        return None


def price(addr):
    for _ in range(3):
        try:
            url = "https://coins.llama.fi/prices/current/ethereum:" + addr
            coins = json.load(urllib.request.urlopen(url, timeout=25))["coins"]
            return list(coins.values())[0]["price"]
        except Exception:
            time.sleep(2)
    return None


def get_dy(pool, i, j, amt):
    try:
        return num(call(pool, "get_dy(int128,int128,uint256)(uint256)", i, j, amt))
    except Exception:
        return None


def main():
    block = int(cast(["block-number"]))
    out = {
        "generated_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "chain_id": int(cast(["chain-id"])),
        "block": block,
        "governor": {
            "address": GOV,
            "name": call(GOV, "name()(string)").strip('"'),
            "quorum_votes": num(call(GOV, "quorumVotes()(uint256)")),
            "proposal_threshold": num(call(GOV, "proposalThreshold()(uint256)")),
            "voting_delay": num(call(GOV, "votingDelay()(uint256)")),
            "voting_period": num(call(GOV, "votingPeriod()(uint256)")),
            "proposal_count": num(call(GOV, "proposalCount()(uint256)")),
            "timelock": call(GOV, "timelock()(address)"),
            "guardian": call(GOV, "guardian()(address)"),
            "inv": call(GOV, "inv()(address)"),
            "xinv": call(GOV, "xinv()(address)"),
        },
        "timelock": {
            "address": TL,
            "admin": call(TL, "admin()(address)"),
            "pending_admin": call(TL, "pendingAdmin()(address)"),
            "delay": num(call(TL, "delay()(uint256)")),
            "grace_period": num(call(TL, "GRACE_PERIOD()(uint256)")),
            "eth": int(cast(["balance", TL])),
        },
        "guardian": {
            "address": GUARDIAN,
            "governor_mills": call(GUARDIAN, "governorMills()(address)"),
            "deployer": call(GUARDIAN, "deployer()(address)"),
            "rwg": call(GUARDIAN, "rwg()(address)"),
            "deployer_codesize": len(cast(["code", DEPLOYER]).replace("0x", "")) // 2,
            "rwg_threshold": num(call(RWG, "getThreshold()(uint256)")),
            "rwg_owners": call(RWG, "getOwners()(address[])").replace("\n", " "),
        },
        "dola": {
            "address": DOLA,
            "operator": call(DOLA, "operator()(address)"),
            "total_supply": num(call(DOLA, "totalSupply()(uint256)")),
            "timelock_balance": num(call(DOLA, "balanceOf(address)(uint256)", TL)),
            "attacker_is_minter": call(DOLA, "minters(address)(bool)", "0x000000000000000000000000000000000000dEaD"),
        },
        "inv": {
            "address": INV,
            "total_supply": num(call(INV, "totalSupply()(uint256)")),
            "owner": call(INV, "owner()(address)"),
            "tradable": call(INV, "tradable()(bool)"),
            "timelock_balance": num(call(INV, "balanceOf(address)(uint256)", TL)),
            "timelock_delegates": call(INV, "delegates(address)(address)", TL),
            "incumbent_inv_votes": num(call(INV, "getCurrentVotes(address)(uint96)", INCUMBENT)),
            "incumbent_xinv_votes": num(call(XINV, "getCurrentVotes(address)(uint96)", INCUMBENT)),
        },
        "xinv": {
            "address": XINV,
            "total_supply": num(call(XINV, "totalSupply()(uint256)")),
            "exchange_rate": num(call(XINV, "exchangeRateCurrent()(uint256)")),
            "inv_held": num(call(INV, "balanceOf(address)(uint256)", XINV)),
        },
        "timelock_tokens": {
            "DOLA": num(call(DOLA, "balanceOf(address)(uint256)", TL)),
            "DBR": num(call(DBR, "balanceOf(address)(uint256)", TL)),
            "WBTC": num(call(WBTC, "balanceOf(address)(uint256)", TL)),
            "INV": num(call(INV, "balanceOf(address)(uint256)", TL)),
        },
        "sdola_total_assets": num(call(SDOLA, "totalAssets()(uint256)")),
        "dola_liquidity": {
            "pool_susde": POOL_SUSDE,
            "pool_susde_dola_bal": num(call(POOL_SUSDE, "balances(uint256)(uint256)", 0)),
            "pool_susde_other_bal": num(call(POOL_SUSDE, "balances(uint256)(uint256)", 1)),
            "pool_susds_dola_bal": num(call(POOL_SUSDS, "balances(uint256)(uint256)", 0)),
            "pool_susds_other_bal": num(call(POOL_SUSDS, "balances(uint256)(uint256)", 1)),
            "get_dy_5m": get_dy(POOL_SUSDE, 0, 1, 5_000_000 * 10**18),
            "get_dy_10m": get_dy(POOL_SUSDE, 0, 1, 10_000_000 * 10**18),
            "get_dy_20m": get_dy(POOL_SUSDE, 0, 1, 20_000_000 * 10**18),
            "get_dy_25m": get_dy(POOL_SUSDE, 0, 1, 25_000_000 * 10**18),
        },
    }
    out["prices"] = {
        "INV": price(INV),
        "DOLA": price(DOLA),
        "sUSDe": price(SUSDE),
        "sUSDS": price(SUSDS),
        "WBTC": price(WBTC),
    }
    p_inv = out["prices"]["INV"] or 0
    p_susde = out["prices"]["sUSDe"] or 1.0
    out["economics"] = {
        "quorum_cost_usd": round(24_000 * p_inv, 2),
        "threshold_cost_usd": round(7_270 * p_inv, 2),
        "incumbent_votes_weighted": round(
            (out["inv"]["incumbent_inv_votes"] or 0) / 1e18
            + (out["inv"]["incumbent_xinv_votes"] or 0) / 1e18 * (out["xinv"]["exchange_rate"] or 0) / 1e18,
            2,
        ),
        "extract_10m_dola_usd": round((out["dola_liquidity"]["get_dy_10m"] or 0) / 1e18 * p_susde, 2),
        "extract_25m_dola_usd": round((out["dola_liquidity"]["get_dy_25m"] or 0) / 1e18 * p_susde, 2),
        "timelock_assets_usd": round(
            (out["timelock_tokens"]["DOLA"] or 0) / 1e18 * (out["prices"]["DOLA"] or 1)
            + (out["timelock_tokens"]["DBR"] or 0) / 1e18 * 0.0468
            + (out["timelock_tokens"]["WBTC"] or 0) / 1e8 * (out["prices"]["WBTC"] or 0)
            + (out["timelock_tokens"]["INV"] or 0) / 1e18 * p_inv,
            2,
        ),
    }
    json.dump(out, sys.stdout, indent=1)
    print()


if __name__ == "__main__":
    main()
