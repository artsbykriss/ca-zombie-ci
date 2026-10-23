#!/usr/bin/env python3
"""Read-only Gitcoin live-state dump for CI. Writes only ci-out/state.json. No secrets."""
import json, os, subprocess, sys, time, urllib.request

RPC = os.environ.get("FORK_RPC_URL") or os.environ.get("RPC_URL") or "https://ethereum-rpc.publicnode.com"
ACTIVE_GOV = "0xef41CbD211076E8b1901e214Bf751d404cf06638"
LEGACY_GOV = "0x9D4C63565D5618310271bF3F3c01b2954C1D1639"
TL = "0x57a8865cfB1eCEf7253c27da6B4BC3dAEE5Be518"
GTC = "0xDe30da39c46104798bB5aA3fe8B9e0e1F348163F"
GUARDIAN_SAFE = "0x5743E35477363241300FcEdc2F5eB0195F300817"
USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
RAD = "0x31c8EAcBFFdD875c74b94b077895Bd78CF1E64A3"


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


def main():
    block = int(cast(["block-number"]))
    out = {
        "generated_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "chain_id": int(cast(["chain-id"])),
        "block": block,
        "active_governor": {
            "address": ACTIVE_GOV,
            "name": call(ACTIVE_GOV, "name()(string)").strip('"'),
            "token": call(ACTIVE_GOV, "token()(address)"),
            "timelock": call(ACTIVE_GOV, "timelock()(address)"),
            "proposal_guardian": call(ACTIVE_GOV, "proposalGuardian()(address)"),
            "quorum": num(call(ACTIVE_GOV, "quorum(uint256)(uint256)", block - 1)),
            "proposal_threshold": num(call(ACTIVE_GOV, "proposalThreshold()(uint256)")),
            "voting_delay": num(call(ACTIVE_GOV, "votingDelay()(uint256)")),
            "voting_period": num(call(ACTIVE_GOV, "votingPeriod()(uint256)")),
            "late_quorum_vote_extension": num(call(ACTIVE_GOV, "lateQuorumVoteExtension()(uint64)")),
        },
        "legacy_governor": {
            "address": LEGACY_GOV,
            "timelock": call(LEGACY_GOV, "timelock()(address)"),
        },
        "timelock": {
            "address": TL,
            "admin": call(TL, "admin()(address)"),
            "pending_admin": call(TL, "pendingAdmin()(address)"),
            "delay": num(call(TL, "delay()(uint256)")),
            "grace_period": num(call(TL, "GRACE_PERIOD()(uint256)")),
            "eth": int(cast(["balance", TL])),
        },
        "guardian_safe": {
            "address": GUARDIAN_SAFE,
            "threshold": num(call(GUARDIAN_SAFE, "getThreshold()(uint256)")),
            "owners": call(GUARDIAN_SAFE, "getOwners()(address[])").replace("\n", " "),
            "gtc_votes": num(call(GTC, "getCurrentVotes(address)(uint96)", GUARDIAN_SAFE)),
        },
        "gtc": {
            "address": GTC,
            "total_supply": num(call(GTC, "totalSupply()(uint256)")),
            "timelock_balance": num(call(GTC, "balanceOf(address)(uint256)", TL)),
            "timelock_delegates": call(GTC, "delegates(address)(address)", TL),
            "timelock_votes": num(call(GTC, "getCurrentVotes(address)(uint96)", TL)),
        },
        "timelock_tokens": {
            "GTC": num(call(GTC, "balanceOf(address)(uint256)", TL)),
            "USDC": num(call(USDC, "balanceOf(address)(uint256)", TL)),
            "RAD": num(call(RAD, "balanceOf(address)(uint256)", TL)),
        },
    }
    out["prices"] = {"GTC": price(GTC), "RAD": price(RAD)}
    p = out["prices"]["GTC"] or 0
    out["economics"] = {
        "treasury_usd": round(
            (out["timelock_tokens"]["GTC"] or 0) / 1e18 * p
            + (out["timelock_tokens"]["USDC"] or 0) / 1e6
            + (out["timelock_tokens"]["RAD"] or 0) / 1e18 * (out["prices"]["RAD"] or 0)
            + (out["timelock"]["eth"] or 0) / 1e18 * 2400,
            2,
        ),
        "quorum_cost_usd": round(1_500_000 * p, 2),
        "guardian_votes_usd": round((out["guardian_safe"]["gtc_votes"] or 0) / 1e18 * p, 2),
    }
    json.dump(out, sys.stdout, indent=1)
    print()


if __name__ == "__main__":
    main()
