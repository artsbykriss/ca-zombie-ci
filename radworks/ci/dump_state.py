#!/usr/bin/env python3
"""Read-only Radworks live-state dump for CI. No secrets are written."""
import json, os, subprocess, sys, time, urllib.request

RPC = os.environ.get("FORK_RPC_URL") or os.environ.get("RPC_URL") or "https://ethereum-rpc.publicnode.com"
GOV = "0xD64D01D04498bFc60f04178e0B62a757C5048212"
TL = "0x8dA8f82d2BbDd896822de723F55D6EdF416130ba"
RAD = "0x31c8EAcBFFdD875c74b94b077895Bd78CF1E64A3"
USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
GTC = "0xDe30da39c46104798bB5aA3fe8B9e0e1F348163F"
PAIR = "0x8C1c499b1796D7F3C2521AC37186B52De024e58c"
DRIPS = "0x219dfbD6B0e414CCCb52C2e4d93160De99918456"

def cast(args):
    out = subprocess.check_output(["cast", *args, "--rpc-url", RPC], text=True, stderr=subprocess.STDOUT)
    return out.strip()

def call(to, sig, *args, block=None):
    a = ["call", to, sig, *[str(x) for x in args]]
    if block is not None:
        a += ["--block", str(block)]
    return cast(a)

def num(x):
    return int(x.split()[0]) if x and x.split()[0].lstrip("-").isdigit() else None

def token_balance(token, who):
    return num(call(token, "balanceOf(address)(uint256)", who))

def main():
    block = int(cast(["block-number"]))
    out = {
        "generated_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "chain_id": int(cast(["chain-id"])),
        "block": block,
        "governor": {
            "address": GOV,
            "quorum": num(call(GOV, "quorum(uint256)(uint256)", block - 1)),
            "proposal_threshold": num(call(GOV, "proposalThreshold()(uint256)")),
            "voting_delay": num(call(GOV, "votingDelay()(uint256)")),
            "voting_period": num(call(GOV, "votingPeriod()(uint256)")),
            "timelock": call(GOV, "timelock()(address)"),
            "name": call(GOV, "name()(string)").strip('"'),
            "counting_mode": call(GOV, "COUNTING_MODE()(string)").strip('"'),
        },
        "timelock": {
            "address": TL,
            "admin": call(TL, "admin()(address)"),
            "pending_admin": call(TL, "pendingAdmin()(address)"),
            "delay": num(call(TL, "delay()(uint256)")),
            "grace_period": num(call(TL, "GRACE_PERIOD()(uint256)")),
        },
        "balances": {
            "RAD": token_balance(RAD, TL),
            "USDC": token_balance(USDC, TL),
            "WETH": token_balance(WETH, TL),
            "GTC": token_balance(GTC, TL),
            "LP_RAD_USDC": token_balance(PAIR, TL),
            "ETH": int(cast(["balance", TL])),
            "RAD_total_supply": num(call(RAD, "totalSupply()(uint256)")),
            "RAD_delegates_timelock": call(RAD, "delegates(address)(address)", TL),
            "RAD_timelock_getPriorVotes": num(call(RAD, "getPriorVotes(address,uint256)(uint96)", TL, block - 1)),
            "drips_votes": num(call(RAD, "getCurrentVotes(address)(uint96)", DRIPS)),
        },
        "lp": {
            "pair": PAIR,
            "total_supply": num(call(PAIR, "totalSupply()(uint256)")),
            "timelock_share": token_balance(PAIR, TL),
            "token0": call(PAIR, "token0()(address)"),
            "token1": call(PAIR, "token1()(address)"),
        },
    }
    _res_lines = call(PAIR, "getReserves()(uint112,uint112,uint32)").splitlines()
    out["lp"]["reserves"] = [int(_res_lines[0].split()[0]), int(_res_lines[1].split()[0])]
    try:
        url = "https://coins.llama.fi/prices/current/ethereum:" + RAD + ",ethereum:" + WETH + ",ethereum:" + GTC
        p = json.load(urllib.request.urlopen(url, timeout=20))["coins"]
        out["prices"] = {k.split(":")[-1].lower(): v["price"] for k, v in p.items()}
    except Exception as e:
        out["prices_error"] = str(e)
    json.dump(out, sys.stdout, indent=1)
    print()

if __name__ == "__main__":
    main()
