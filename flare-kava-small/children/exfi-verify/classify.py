"""Build the ABI-wide classification table (task 2) merged with live fresh-caller probe results."""
import json
import os

ABI = json.load(open(os.path.join(os.path.dirname(__file__), "stake_manager_abi.json")))

ANN = {
    "DECIMAL_PRECISION": ("VIEW", "no", "no", "no", "constant 1e18"),
    "DURATION": ("VIEW", "no", "no", "no", "86400"),
    "ZERO_EPOCH_START": ("VIEW", "no", "no", "no", "epoch origin 1759406400"),
    "_1pct": ("VIEW", "no", "no", "no", "constant helper"),
    "_totalSupply": ("VIEW", "no", "no", "no", "same storage as totalSupply"),
    "acceptOwnership": ("INIT", "no", "no", "no", "requires being pendingOwner (0x0 live)"),
    "addVoting": ("ADMIN", "no", "no", "no", "governor-only"),
    "apyCloud": ("VIEW", "no", "no", "no", "notifier address"),
    "apyCloudVault": ("VIEW", "no", "no", "no", "vault address"),
    "balanceOf": ("VIEW", "no", "no", "no", "stake balance"),
    "balanceOfEpoch": ("VIEW", "no", "no", "no", "checkpoint balance at epoch snapshot"),
    "canClaimRewards": ("VIEW", "no", "no", "no", ""),
    "checkpoints": ("VIEW", "no", "no", "no", "user checkpoint array"),
    "claimRewards": ("VALUE-OUT", "no", "no", "no", "pays only msg.sender's own sum(balanceOfEpoch*rate); advances claim epoch"),
    "epochInterval": ("VIEW", "no", "no", "no", ""),
    "epochRewardRate": ("VIEW", "no", "no", "no", ""),
    "epochSnapshotBlock": ("VIEW", "no", "no", "no", ""),
    "exit": ("VALUE-OUT", "no", "no", "no", "msg.sender only"),
    "exitWithHint": ("VALUE-OUT", "no", "no", "no", "msg.sender only"),
    "getAllUnclaimedRewards": ("VIEW", "no", "no", "no", ""),
    "getBalanceAt": ("VIEW", "no", "no", "no", "checkpoint binary search"),
    "getBalanceHint": ("VIEW", "no", "no", "no", "3 for accounts with checkpoints, 0 otherwise (live)"),
    "getCurrentEpoch": ("VIEW", "no", "no", "no", ""),
    "getLatestEpochForRewards": ("VIEW", "no", "no", "no", ""),
    "getNextEpoch": ("VIEW", "no", "no", "no", ""),
    "getPreviousEpoch": ("VIEW", "no", "no", "no", ""),
    "getRewardTokens": ("VIEW", "no", "no", "no", "8 tokens"),
    "getTotalSupplyEpochAggregationCheckpoints": ("VIEW", "no", "no", "no", ""),
    "getUserLastVotingBlock": ("VIEW", "no", "no", "no", ""),
    "getUserPendingFeesCheckpoints": ("VIEW", "no", "no", "no", ""),
    "getUserUnprocessedFees": ("VIEW", "no", "no", "no", ""),
    "getVotingCheckpoints": ("VIEW", "no", "no", "no", "3 historical votings"),
    "governors": ("VIEW", "no", "no", "no", ""),
    "initialize": ("INIT", "no", "no", "no", "already initialized (live revert)"),
    "isStakeOrWithdrawInEpoch": ("VIEW", "no", "no", "no", ""),
    "lockedFeesByEpoch": ("VIEW", "no", "no", "no", "0 for recent epochs"),
    "owner": ("VIEW", "no", "no", "no", "EOA 0x28591a8d"),
    "pendingOwner": ("VIEW", "no", "no", "no", "0x0 live"),
    "renounceOwnership": ("ADMIN", "no", "no", "no", "Ownable"),
    "rewardTokens": ("VIEW", "no", "no", "no", ""),
    "stake": ("VALUE-IN", "no", "no", "no", "pulls stakingToken from msg.sender; credits msg.sender"),
    "stakeToWithHint": ("VALUE-IN", "no", "no", "donation only", "credits arbitrary recipient with caller's tokens; no past-epoch balance"),
    "stakeToWithPermit": ("VALUE-IN", "no", "no", "donation only", "same + valid permit required"),
    "stakeWithHint": ("VALUE-IN", "no", "no", "no", "hint validated; oversized reverts (live)"),
    "stakeWithPermit": ("VALUE-IN", "no", "no", "no", "valid permit required"),
    "stakingToken": ("VIEW", "no", "no", "no", "EXFI"),
    "totalBurnedFees": ("VIEW", "no", "no", "no", "0"),
    "totalLockedFees": ("VIEW", "no", "no", "no", "0.022 EXFI historical"),
    "totalSupply": ("VIEW", "no", "no", "no", ""),
    "totalSupplyAggregatedByCheckpoint": ("VIEW", "no", "no", "no", ""),
    "totalSupplyAggregationRange": ("VIEW", "no", "no", "no", "1000"),
    "totalSupplyByEpoch": ("VIEW", "no", "no", "no", ""),
    "totalSupplyEpochAggregationCheckpoints": ("VIEW", "no", "no", "no", ""),
    "transferOwnership": ("ADMIN", "no", "no", "no", "Ownable"),
    "updateApyCloudVault": ("ADMIN", "no", "no", "no", "Ownable"),
    "updateGovernor": ("ADMIN", "no", "no", "no", "Ownable"),
    "updateRewardAmountByToken": ("ADMIN", "no", "no", "no", "notifier-only (apyCloud 0xb8d1c66a)"),
    "updateRewardTokensAdd": ("ADMIN", "no", "no", "no", "Ownable"),
    "updateRewardTokensRemove": ("ADMIN", "no", "no", "no", "Ownable"),
    "updateTotalSupplyAggregationRange": ("ADMIN", "no", "no", "no", "Ownable"),
    "updateVoting": ("ADMIN", "no", "no", "no", "governor-only"),
    "userLastCheckedVotingBlock": ("VIEW", "no", "no", "no", ""),
    "userLastRewardClaimEpoch": ("VIEW", "no", "no", "no", ""),
    "userPaidFees": ("VIEW", "no", "no", "no", ""),
    "userPendingFeesCheckpoints": ("VIEW", "no", "no", "no", ""),
    "userPendingVotingFees": ("VIEW", "no", "no", "no", ""),
    "usersCheckpointsCount": ("VIEW", "no", "no", "no", ""),
    "votingCheckpoints": ("VIEW", "no", "no", "no", ""),
    "votingsByCheckpoint": ("VIEW", "no", "no", "no", ""),
    "votingsByGovernors": ("VIEW", "no", "no", "no", ""),
    "withdraw": ("VALUE-OUT", "no", "no", "no", "amount <= balanceOf(msg.sender)"),
    "withdrawAndGetReward": ("VALUE-OUT", "no", "no", "no", ""),
    "withdrawAndGetRewardWithHint": ("VALUE-OUT", "no", "no", "no", ""),
    "withdrawReturnedFees": ("VALUE-OUT", "no", "no", "no", "own returned fees; live no-op with false"),
    "withdrawReturnedFeesTo": ("VALUE-OUT", "no", "no", "no", "recipient param; record keyed by msg.sender"),
    "withdrawTo": ("VALUE-OUT", "no", "no", "no", "recipient param; live-tested"),
    "withdrawToAndGetReward": ("VALUE-OUT", "no", "no", "no", ""),
    "withdrawToAndGetRewardWithHint": ("VALUE-OUT", "no", "no", "no", ""),
    "withdrawToWithHint": ("VALUE-OUT", "no", "no", "no", ""),
    "withdrawWithHint": ("VALUE-OUT", "no", "no", "no", ""),
}

EXTRAS = {
    "updateTotalSupplyByEpochIfNeeded(uint256) [0xa63d3646]": ("ADMIN/permissionless", "no", "no", "no",
                                                                  "settled-epoch finaliser; idempotent live (S4)"),
    "apyCloud() raw getter [0xa5032f3c]": ("VIEW", "no", "no", "no", "returns notifier 0xb8d1c66a"),
    "withdrawReturnedFeesTo(address,bool) [0x1ae78c48]": ("VALUE-OUT", "no", "no", "no", "same as withdrawReturnedFees with recipient"),
    "getBalanceHint(address) [0x0a55048a]": ("VIEW", "no", "no", "no", "search hint only"),
}


def fmt_ret(v):
    if isinstance(v, dict):
        msg = v.get("err", "")
        return "REVERT: " + msg.replace("execution reverted: ", "")[:70]
    return "SUCCESS ret=" + str(v)[:40]


def main():
    probes = {}
    if os.path.exists("probes.json"):
        probes = json.load(open("probes.json"))
    s1map = {}
    for x in probes.get("S1_fresh_direct", []):
        s1map[x["fn"]] = ("SUCCESS ret=" + str(x.get("ret"))[:40]) if x.get("success") else x.get("err", "")
    # S1 probe-list names for these two differ from the ABI signature
    alias = {
        "withdrawReturnedFees(bool)": "withdrawReturnedFees(true)",
        "withdrawReturnedFeesTo(address,bool)": "withdrawReturnedFeesTo(address,bool)-true",
        "initialize(address,uint256,address[],address)": "initialize(address,uint256,address[],address)",
    }
    for k, v in alias.items():
        if k not in s1map and v in s1map:
            s1map[k] = s1map[v]

    rows = []
    for e in ABI:
        if e.get("type") != "function":
            continue
        sig = e["name"] + "(" + ",".join(i["type"] for i in e["inputs"]) + ")"
        cls, ts, ci, ot, note = ANN.get(e["name"], ("?", "?", "?", "?", ""))
        fresh = s1map.get(sig, "")
        rows.append((sig, e.get("stateMutability"), cls, ts, ci, ot, note, fresh))

    with open("classification.md", "w") as f:
        f.write("# Stake manager — every recovered-ABI function classified (independent)\n\n")
        f.write("`fresh-caller` column = live `eth_call` from a keyless fresh EOA (0x4444…4444).\n\n")
        f.write("| function | mutability | class | to-self | claim+ | others | note | fresh-caller live |\n")
        f.write("|---|---|---|---|---|---|---|---|\n")
        for sig, mut, cls, ts, ci, ot, note, fresh in sorted(rows, key=lambda r: (r[2], r[0])):
            f.write(f"| `{sig}` | {mut} | {cls} | {ts} | {ci} | {ot} | {note} | {fresh.replace('|','/')} |\n")
        f.write("\n## Bytecode-only extras (4 selectors not in the frontend ABI)\n\n")
        f.write("| function | class | to-self | claim+ | others | note |\n|---|---|---|---|---|---|\n")
        for sig, (cls, ts, ci, ot, note) in EXTRAS.items():
            f.write(f"| `{sig}` | {cls} | {ts} | {ci} | {ot} | {note} |\n")
    print(f"wrote classification.md ({len(rows)} ABI functions + {len(EXTRAS)} extras)")


if __name__ == "__main__":
    main()
