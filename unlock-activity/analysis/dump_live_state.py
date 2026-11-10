#!/usr/bin/env python3
"""Dump Unlock governance live state to ci-out/live-state.json.
Read-only. The RPC URL is read from env and NEVER written to the output.
"""
import json, os, subprocess, urllib.request, csv, statistics, collections

RPC = os.environ.get("BASE_RPC_URL") or os.environ.get("RPC") or "https://base-rpc.publicnode.com"
GOV = "0x65bA0624403Fc5Ca2b20479e9F626eD4D78E0aD9"
TL = "0xB34567C4cA697b39F72e1a8478f285329A98ed1b"
UP = "0xaC27fa800955849d6D17cC8952Ba9dD6EAA66187"
USDC = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
WETH = "0x4200000000000000000000000000000000000006"
POOL = "0x9EF81F4E2F2f15Ff1c0C3f8c9ECc636580025242"
AERO = "0xDd295951b46B245638E3C3643299210Eea06a897"
DEPLOYER = "0x81Dd955D02D337DB81BA6c9C5F6213E647672052"
WHALE = "0xF5C28ce24Acf47849988f147d5C75787c0103534"
SAFE = "0x3074517c5F5428f42C74543C68001E0Ca86FE7dd"
TOP = [
    WHALE, "0x6554dc052d2277008DF7898dEeE0FE76B54dEd56",
    "0x38b826a4426a0d4d9b4377ac57c9af0308281c5d",
    "0xd2bc5cb641ae6f7a880c3dd5aee0450b5210be23",
    "0x87ece9936ad2254d03af83958fe3b202dc79793f",
    "0x9ded35aef86f3c826ff8fe9240f9e7a9fb2094e5",
    "0x34c2871c3d539c473e40a09158bdff522202e2d5",
    "0xca7632327567796e51920f6b16373e92c7823854",
    "0x9492510bbcb93b6992d8b7bb67888558e12dcac4",
    "0x79f16606e9a64edb8ba09c55ee1375bda883c032",
    "0x676efef0dc8be574fb8f67e272259e7d213d3577",
]


def call_raw(to, sig, *args):
    cmd = ["cast", "call", to, sig] + [str(a) for a in args] + ["--rpc-url", RPC]
    try:
        return subprocess.check_output(cmd, stderr=subprocess.DEVNULL, timeout=30).decode().strip().replace("\n", ",")
    except Exception as e:
        return "ERR:" + type(e).__name__


def call(to, sig, *args):
    cmd = ["cast", "call", to, sig] + [str(a) for a in args] + ["--rpc-url", RPC]
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, timeout=30).decode().strip()
        return out.split()[0]
    except Exception as e:
        return "ERR:" + type(e).__name__


def main():
    block = int(subprocess.check_output(["cast", "block-number", "--rpc-url", RPC], timeout=30).decode().strip())
    ts = int(subprocess.check_output(["cast", "block", str(block), "--field", "timestamp", "--rpc-url", RPC], timeout=30).decode().strip(), 0)

    usd = {}
    try:
        url = ("https://coins.llama.fi/prices/current/base:"
               + UP + ",ethereum:0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2")
        with urllib.request.urlopen(url, timeout=30) as r:
            usd = json.load(r).get("coins", {})
    except Exception:
        pass

    state = {
        "chain": "base 8453", "block": block, "timestamp": ts,
        "governor": {
            "address": GOV,
            "quorum": call(GOV, "quorum(uint256)(uint256)", ts - 1),
            "proposalThreshold": call(GOV, "proposalThreshold()(uint256)"),
            "votingDelay": call(GOV, "votingDelay()(uint256)"),
            "votingPeriod": call(GOV, "votingPeriod()(uint256)"),
            "clock": call(GOV, "clock()(uint48)"),
            "guardian": call(GOV, "guardian()(address)"),
        },
        "timelock": {
            "address": TL,
            "minDelay": call(TL, "getMinDelay()(uint256)"),
            "UP": call(UP, "balanceOf(address)(uint256)", TL),
            "ETH": None,
            "USDC": call(USDC, "balanceOf(address)(uint256)", TL),
            "WETH": call(WETH, "balanceOf(address)(uint256)", TL),
        },
        "up_token": {
            "address": UP,
            "totalSupply": call(UP, "totalSupply()(uint256)"),
            "owner": call(UP, "owner()(address)"),
        },
        "holders": {
            "deployer_0x81dd": {"balance": call(UP, "balanceOf(address)(uint256)", DEPLOYER),
                                "votes": call(UP, "getVotes(address)(uint256)", DEPLOYER)},
            "whale_0xf5c2": {"balance": call(UP, "balanceOf(address)(uint256)", WHALE),
                              "votes": call(UP, "getVotes(address)(uint256)", WHALE)},
            "safe_0x3074": {"balance": call(UP, "balanceOf(address)(uint256)", SAFE),
                             "votes": call(UP, "getVotes(address)(uint256)", SAFE)},
        },
        "pools": {
            "uniswap_v3_03": {"UP": call(UP, "balanceOf(address)(uint256)", POOL),
                               "WETH": call(WETH, "balanceOf(address)(uint256)", POOL)},
            "aerodrome": {"reserves": call_raw(AERO, "getReserves()(uint256,uint256,uint256)"),
                           "stable": call(AERO, "stable()(bool)")},
        },
        "prices": usd,
        "top_delegates": {},
    }
    # native ETH balance via cast balance
    try:
        state["timelock"]["ETH"] = str(int(subprocess.check_output(
            ["cast", "balance", TL, "--rpc-url", RPC], timeout=30).decode().strip()))
    except Exception:
        state["timelock"]["ETH"] = "ERR"
    for a in TOP:
        state["top_delegates"][a] = call(UP, "getVotes(address)(uint256)", a)

    # activity summary from the bundled decoded CSVs (full 158-proposal history)
    try:
        rows = list(csv.DictReader(open(os.path.join(os.path.dirname(__file__), "proposals.csv"))))
        votes = list(csv.DictReader(open(os.path.join(os.path.dirname(__file__), "votes.csv"))))
        turn = sorted(int(r["turnout"]) / 1e18 for r in rows)
        dep_votes = [v for v in votes if v["voter"].lower() == DEPLOYER.lower()]
        whale_votes = [v for v in votes if v["voter"].lower() == WHALE.lower()]
        state["activity"] = {
            "n_proposals": len(rows), "n_votes": len(votes),
            "turnout_min": turn[0], "turnout_median": statistics.median(turn),
            "turnout_max": turn[-1],
            "turnout_below_3m": sum(1 for t in turn if t < 3_000_000),
            "outcomes": dict(collections.Counter(r["outcome"] for r in rows)),
            "deployer_votes_cast": len(dep_votes),
            "deployer_support": dict(collections.Counter(v["support"] for v in dep_votes)),
            "whale_votes_cast": len(whale_votes),
            "whale_support": dict(collections.Counter(v["support"] for v in whale_votes)),
        }
    except Exception as e:
        state["activity"] = {"error": str(e)}

    os.makedirs("ci-out", exist_ok=True)
    with open("ci-out/live-state.json", "w") as fh:
        json.dump(state, fh, indent=1)
    print(json.dumps(state, indent=1)[:4000])


if __name__ == "__main__":
    main()
