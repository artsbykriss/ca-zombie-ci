"""Adversarial live probes for the Enosys EXFI stake manager + FarmingPool (rebuilt after
the parent tree was deleted mid-verification).

Technique: eth_call with state overrides.
 - Multicall3 is deployed on Songbird (0xcA11...). By overriding the *code* of an EOA
   with Multicall3's runtime and calling aggregate3 from that EOA, the nested calls have
   msg.sender = that EOA, and state changes persist within the single eth_call, so we can
   read state after write calls. No tx is ever sent.
 - EXFI token storage overrides fund a fresh account (balance slot 2, allowance slot 3 in
   the YieldFlare layout 0:_owner,1:_newOwner,2:_balances,3:_allowances,4:_frozen,5:_totalSupply).

Everything is read-only: eth_call only.
"""
import json
from lib import *
from Crypto.Hash import keccak as K

MGR = "0xc4D89F8f593F215f3636793E3353A36C196Cf87A"
SFIN_MGR = "0xA83E90337e2711b1c84df0AD7428403dBd0ce730"
FARM = "0xb78ebd4b13a2202068618bf98f952c0271159107"
EXFI = "0xC348F894d0E939FE72c467156E6d7DcbD6f16e21"
TOKENS = [
    "0x02f0826ef6ad107cfc861152b32b52fd11bab9ed",
    "0xc348f894d0e939fe72c467156e6d7dcbd6f16e21",
    "0x0d94e59332732d18cf3a3d457a8886a2ae29ea1b",
    "0xc54de96302981f87a6f80e4607593681b44d670c",
    "0xf9a84f4ec903f4eab117a9c1098bec078ba7027d",
    "0x36b84a93820175c02f57e5c87a7ea33df58e5c94",
    "0x1a7b46656b2b8b29b1694229e122d066020503d0",
    "0x4a771cc1a39fdd8aa08b8ea51f7fd412e73b3d2b",
]
SYM = ["WSGB", "EXFI", "SFIN", "exXDC", "FXRP", "exETH", "exUSDT", "USDX"]
FRESH = "0x4444444444444444444444444444444444444444"
FRESH2 = "0x7777777777777777777777777777777777777777"
ATTACKER = "0x6666666666666666666666666666666666666666"
VICTIM = "0x0B465f43db2F05a3A68F838c5080aCae649f28d4"   # staked 4,405,406 EXFI
U2 = "0xFAA9f4d3dF9bd35fEb56105691748DAf65F420D8"      # staked 383,427 EXFI, canClaim

results = {}

def kh(*parts):
    x = K.new(digest_bits=256)
    x.update(bytes.fromhex("".join(p[2:] if p.startswith("0x") else p for p in parts)))
    return "0x" + x.hexdigest()

def tok_balance_slot(owner):
    return kh(waddr(owner), w(2))

def tok_allowance_slot(owner, spender):
    # empirically verified live: allowance(owner,spender) reads keccak(pad32(spender)+keccak(pad32(owner)+pad32(3)))
    # (reversed nesting vs the YieldFlare source layout; proven by storage override + view round-trip)
    return kh(waddr(spender), kh(waddr(owner), w(3)))

def mc3_over(target, calls, extra=None):
    return mc3_override_call(target, calls, extra=extra)

def direct(tag, to, data, frm=FRESH):
    try:
        r = rpc("eth_call", [{"from": frm, "to": to, "data": data}, "latest"])
        return {"fn": tag, "success": True, "ret": r}
    except Exception as e:
        return {"fn": tag, "success": False, "err": str(e)}

# ------------------------------------------------------------------ section 1
def section1_fresh_direct():
    cur = dec_uint(one_call(MGR, sel("getCurrentEpoch()")))
    wfuncs = [
        ("acceptOwnership()", sel("acceptOwnership()")),
        ("initialize(address,uint256,address[],address)", sel("initialize(address,uint256,address[],address)") + addr(EXFI) + uint(1000) + w(0x80) + addr(FRESH) + w(0)),
        ("addVoting(uint256,uint256)", sel("addVoting(uint256,uint256)") + uint(1) + uint(100 * 10**18)),
        ("claimRewards()", sel("claimRewards()")),
        ("exit()", sel("exit()")),
        ("exitWithHint(uint256)", sel("exitWithHint(uint256)") + uint(3)),
        ("renounceOwnership()", sel("renounceOwnership()")),
        ("stake(uint256)", sel("stake(uint256)") + uint(1)),
        ("stakeWithHint(uint256,uint256)", sel("stakeWithHint(uint256,uint256)") + uint(1) + uint(0)),
        ("stakeWithPermit(uint256,uint256,uint256,uint8,bytes32,bytes32)",
         sel("stakeWithPermit(uint256,uint256,uint256,uint8,bytes32,bytes32)") + uint(1) + uint(0) + uint(2**40) + uint(27) + w(0) + w(0)),
        ("stakeToWithHint(uint256,address,uint256)", sel("stakeToWithHint(uint256,address,uint256)") + uint(1) + addr(FRESH) + uint(0)),
        ("stakeToWithPermit(uint256,address,uint256,uint256,uint8,bytes32,bytes32)",
         sel("stakeToWithPermit(uint256,address,uint256,uint256,uint8,bytes32,bytes32)") + uint(1) + addr(FRESH) + uint(0) + uint(2**40) + uint(27) + w(0) + w(0)),
        ("transferOwnership(address)", sel("transferOwnership(address)") + addr(FRESH)),
        ("updateApyCloudVault(address)", sel("updateApyCloudVault(address)") + addr(FRESH)),
        ("updateGovernor(address,bool)", sel("updateGovernor(address,bool)") + addr(FRESH) + uint(1)),
        ("updateRewardAmountByToken(address,uint256)", sel("updateRewardAmountByToken(address,uint256)") + addr(EXFI) + uint(10**18)),
        ("updateRewardTokensAdd(address)", sel("updateRewardTokensAdd(address)") + addr(EXFI)),
        ("updateRewardTokensRemove(uint256)", sel("updateRewardTokensRemove(uint256)") + uint(0)),
        ("updateTotalSupplyAggregationRange(uint256)", sel("updateTotalSupplyAggregationRange(uint256)") + uint(1)),
        ("updateVoting(uint256,bool)", sel("updateVoting(uint256,bool)") + uint(1) + uint(1)),
        ("withdraw(uint256)", sel("withdraw(uint256)") + uint(1)),
        ("withdrawWithHint(uint256,uint256)", sel("withdrawWithHint(uint256,uint256)") + uint(1) + uint(3)),
        ("withdrawAndGetReward(uint256)", sel("withdrawAndGetReward(uint256)") + uint(1)),
        ("withdrawAndGetRewardWithHint(uint256,uint256)", sel("withdrawAndGetRewardWithHint(uint256,uint256)") + uint(1) + uint(3)),
        ("withdrawTo(uint256,address)", sel("withdrawTo(uint256,address)") + uint(1) + addr(FRESH)),
        ("withdrawToWithHint(uint256,address,uint256)", sel("withdrawToWithHint(uint256,address,uint256)") + uint(1) + addr(FRESH) + uint(3)),
        ("withdrawToAndGetReward(uint256,address)", sel("withdrawToAndGetReward(uint256,address)") + uint(1) + addr(FRESH)),
        ("withdrawToAndGetRewardWithHint(uint256,address,uint256)", sel("withdrawToAndGetRewardWithHint(uint256,address,uint256)") + uint(1) + addr(FRESH) + uint(3)),
        ("withdrawReturnedFees(true)", sel("withdrawReturnedFees(bool)") + uint(1)),
        ("withdrawReturnedFees(false)", sel("withdrawReturnedFees(bool)") + uint(0)),
        ("withdrawReturnedFeesTo(address,bool)-true", sel("withdrawReturnedFeesTo(address,bool)") + addr(FRESH) + uint(1)),
        ("withdrawReturnedFeesTo(address,bool)-false", sel("withdrawReturnedFeesTo(address,bool)") + addr(FRESH) + uint(0)),
        ("updateTotalSupplyByEpochIfNeeded(cur-2)", "0xa63d3646" + uint(cur - 2)),
        ("updateTotalSupplyByEpochIfNeeded(cur)", "0xa63d3646" + uint(cur)),
    ]
    out = []
    for name, data in wfuncs:
        out.append(direct(name, MGR, data, FRESH))
    for name, data in [
        ("SFIN claimRewards()", sel("claimRewards()")),
        ("SFIN addVoting(uint256,uint256)", sel("addVoting(uint256,uint256)") + uint(1) + uint(100)),
        ("SFIN updateRewardAmountByToken(address,uint256)", sel("updateRewardAmountByToken(address,uint256)") + addr(EXFI) + uint(10**18)),
        ("SFIN withdrawTo(uint256,address)", sel("withdrawTo(uint256,address)") + uint(1) + addr(FRESH)),
        ("SFIN withdrawReturnedFees(false)", sel("withdrawReturnedFees(bool)") + uint(0)),
        ("SFIN updateApyCloudVault(address)", sel("updateApyCloudVault(address)") + addr(FRESH)),
    ]:
        out.append(direct(name, SFIN_MGR, data, FRESH))
    return out

# ------------------------------------------------------------------ section 2
def section2_staker_context():
    out = {}
    cur = dec_uint(one_call(MGR, sel("getCurrentEpoch()")))
    res = mc3_over(U2, [
        (EXFI, True, sel("balanceOf(address)") + addr(U2)),
        (MGR, True, sel("getAllUnclaimedRewards(address)") + addr(U2)),
        (MGR, True, sel("userLastRewardClaimEpoch(address)") + addr(U2)),
        (MGR, True, sel("claimRewards()")),
        (EXFI, True, sel("balanceOf(address)") + addr(U2)),
        (MGR, True, sel("userLastRewardClaimEpoch(address)") + addr(U2)),
        (MGR, True, sel("getAllUnclaimedRewards(address)") + addr(U2)),
        (MGR, True, sel("claimRewards()")),
        (MGR, True, sel("getAllUnclaimedRewards(address)") + addr(U2)),
    ])
    claim = {
        "exfi_before": dec_uint(res[0][1]) if res[0][0] else None,
        "unclaimed_before": dec_uarr(res[1][1]) if res[1][0] else None,
        "lastClaim_before": dec_uint(res[2][1]) if res[2][0] else None,
        "claim_success": res[3][0], "claim_revert": None if res[3][0] else reason(res[3][1]),
        "exfi_after": dec_uint(res[4][1]) if res[4][0] else None,
        "lastClaim_after": dec_uint(res[5][1]) if res[5][0] else None,
        "unclaimed_after": dec_uarr(res[6][1]) if res[6][0] else None,
        "second_claim_success": res[7][0], "second_claim_revert": None if res[7][0] else reason(res[7][1]),
        "unclaimed_after2": dec_uarr(res[8][1]) if res[8][0] else None,
    }
    claim["exfi_delta"] = (claim["exfi_after"] - claim["exfi_before"]) if claim["exfi_after"] is not None else None
    claim["sum_unclaimed_before"] = sum(claim["unclaimed_before"]) if claim["unclaimed_before"] else None
    calls = []
    for t in TOKENS:
        calls.append((t, True, sel("balanceOf(address)") + addr(U2)))
    calls.append((MGR, True, sel("claimRewards()")))
    for t in TOKENS:
        calls.append((t, True, sel("balanceOf(address)") + addr(U2)))
    r2 = mc3_over(U2, calls)
    deltas = {}
    for i, t in enumerate(TOKENS):
        before = dec_uint(r2[i][1]) if r2[i][0] else None
        after = dec_uint(r2[9 + i][1]) if r2[9 + i][0] else None
        deltas[SYM[i]] = {"before": before, "after": after, "delta": (after - before) if (before is not None and after is not None) else None}
    claim["per_token_delta"] = deltas
    claim["second_run_claim_success"] = r2[8][0]
    out["claim_settlement_U2"] = claim

    def run_withdraw(fnname, calldata):
        calls = [
            (EXFI, True, sel("balanceOf(address)") + addr(ATTACKER)),
            (EXFI, True, sel("balanceOf(address)") + addr(VICTIM)),
            (MGR, True, sel("balanceOf(address)") + addr(VICTIM)),
            (MGR, True, calldata),
            (EXFI, True, sel("balanceOf(address)") + addr(ATTACKER)),
            (EXFI, True, sel("balanceOf(address)") + addr(VICTIM)),
            (MGR, True, sel("balanceOf(address)") + addr(VICTIM)),
            (MGR, True, sel("userLastRewardClaimEpoch(address)") + addr(VICTIM)),
        ]
        res = mc3_over(VICTIM, calls)
        return {
            "fn": fnname,
            "attacker_exfi_before": dec_uint(res[0][1]) if res[0][0] else None,
            "victim_exfi_before": dec_uint(res[1][1]) if res[1][0] else None,
            "victim_stake_before": dec_uint(res[2][1]) if res[2][0] else None,
            "call_success": res[3][0], "call_revert": None if res[3][0] else reason(res[3][1]),
            "attacker_exfi_after": dec_uint(res[4][1]) if res[4][0] else None,
            "victim_exfi_after": dec_uint(res[5][1]) if res[5][0] else None,
            "victim_stake_after": dec_uint(res[6][1]) if res[6][0] else None,
            "victim_lastClaim_after": dec_uint(res[7][1]) if res[7][0] else None,
        }
    amt = 10**18
    out["victim_withdrawTo_attacker"] = run_withdraw("withdrawTo(1e18, ATTACKER) from VICTIM",
                                                     sel("withdrawTo(uint256,address)") + uint(amt) + addr(ATTACKER))
    out["victim_withdrawTo_self"] = run_withdraw("withdrawTo(1e18, VICTIM) from VICTIM",
                                                 sel("withdrawTo(uint256,address)") + uint(amt) + addr(VICTIM))
    out["victim_withdrawToAndGetReward_attacker"] = run_withdraw("withdrawToAndGetReward(1e18, ATTACKER) from VICTIM",
                                                                 sel("withdrawToAndGetReward(uint256,address)") + uint(amt) + addr(ATTACKER))
    out["victim_exit"] = run_withdraw("exit() from VICTIM", sel("exit()"))

    vbal = dec_uint(one_call(MGR, sel("balanceOf(address)") + addr(VICTIM)))
    out["attack_withdrawTo_victim_balance_to_attacker"] = direct(
        f"withdrawTo(victimBal={vbal}, ATTACKER) from ATTACKER", MGR,
        sel("withdrawTo(uint256,address)") + uint(vbal) + addr(ATTACKER), ATTACKER)
    out["attack_withdrawTo_victim_balance_to_victim"] = direct(
        "withdrawTo(victimBal, VICTIM) from ATTACKER", MGR,
        sel("withdrawTo(uint256,address)") + uint(vbal) + addr(VICTIM), ATTACKER)
    out["attack_withdrawToAndGetReward_victim_balance"] = direct(
        "withdrawToAndGetReward(victimBal, ATTACKER) from ATTACKER", MGR,
        sel("withdrawToAndGetReward(uint256,address)") + uint(vbal) + addr(ATTACKER), ATTACKER)
    out["attack_withdrawToWithHint_victim_balance"] = direct(
        "withdrawToWithHint(victimBal, ATTACKER, 3) from ATTACKER", MGR,
        sel("withdrawToWithHint(uint256,address,uint256)") + uint(vbal) + addr(ATTACKER) + uint(3), ATTACKER)
    out["attack_withdrawToAndGetRewardWithHint_victim_balance"] = direct(
        "withdrawToAndGetRewardWithHint(victimBal, ATTACKER, 3) from ATTACKER", MGR,
        sel("withdrawToAndGetRewardWithHint(uint256,address,uint256)") + uint(vbal) + addr(ATTACKER) + uint(3), ATTACKER)
    out["attack_exitWithHint_from_attacker"] = direct("exitWithHint(3) from ATTACKER", MGR, sel("exitWithHint(uint256)") + uint(3), ATTACKER)
    out["attack_exit_from_attacker"] = direct("exit() from ATTACKER", MGR, sel("exit()"), ATTACKER)
    out["attack_wdTo_attacker_no_balance"] = direct(
        "withdrawTo(1, ATTACKER) from ATTACKER (0 balance)", MGR,
        sel("withdrawTo(uint256,address)") + uint(1) + addr(ATTACKER), ATTACKER)

    bal_slot = tok_balance_slot(FRESH2)
    allow_slot = tok_allowance_slot(FRESH2, MGR)
    fund = {EXFI: {"stateDiff": {bal_slot: "0x" + w(10**21), allow_slot: "0x" + w(2**255)}}}
    res = mc3_over(FRESH2, [
        (MGR, True, sel("balanceOf(address)") + addr(FRESH2)),
        (MGR, True, sel("stakeWithHint(uint256,uint256)") + uint(1000) + uint(0)),
        (MGR, True, sel("balanceOf(address)") + addr(FRESH2)),
        (EXFI, True, sel("balanceOf(address)") + addr(FRESH2)),
        (MGR, True, sel("balanceOfEpoch(address,uint256)") + addr(FRESH2) + uint(cur - 1)),
        (MGR, True, sel("balanceOfEpoch(address,uint256)") + addr(FRESH2) + uint(cur)),
        (MGR, True, sel("getAllUnclaimedRewards(address)") + addr(FRESH2)),
        (MGR, True, sel("claimRewards()")),
        (MGR, True, sel("withdrawWithHint(uint256,uint256)") + uint(500) + uint(0)),
        (EXFI, True, sel("balanceOf(address)") + addr(FRESH2)),
        (MGR, True, sel("stakeWithHint(uint256,uint256)") + uint(1000) + uint(2**64)),
        (MGR, True, sel("withdrawWithHint(uint256,uint256)") + uint(1) + uint(2**64)),
    ], extra=fund)
    out["funded_fresh_stake_flow"] = {
        "stake_before": dec_uint(res[0][1]) if res[0][0] else None,
        "stakeCall_success": res[1][0], "stakeCall_revert": None if res[1][0] else reason(res[1][1]),
        "stake_after": dec_uint(res[2][1]) if res[2][0] else None,
        "exfi_after": dec_uint(res[3][1]) if res[3][0] else None,
        "balEp_cur1_after_stake": dec_uint(res[4][1]) if res[4][0] else None,
        "balEp_cur_after_stake": dec_uint(res[5][1]) if res[5][0] else None,
        "unclaimed_after_stake": dec_uarr(res[6][1]) if res[6][0] else None,
        "claim_after_stake_success": res[7][0], "claim_after_stake_revert": None if res[7][0] else reason(res[7][1]),
        "withdraw_success": res[8][0], "withdraw_revert": None if res[8][0] else reason(res[8][1]),
        "exfi_final": dec_uint(res[9][1]) if res[9][0] else None,
        "oversized_hint_stake_success": res[10][0], "oversized_hint_stake_revert": None if res[10][0] else reason(res[10][1]),
        "oversized_hint_withdraw_success": res[11][0], "oversized_hint_withdraw_revert": None if res[11][0] else reason(res[11][1]),
    }

    res = mc3_over(FRESH2, [
        (MGR, True, sel("balanceOf(address)") + addr(FRESH)),
        (MGR, True, sel("balanceOfEpoch(address,uint256)") + addr(FRESH) + uint(cur - 1)),
        (MGR, True, sel("stakeToWithHint(uint256,address,uint256)") + uint(1000) + addr(FRESH) + uint(0)),
        (MGR, True, sel("balanceOf(address)") + addr(FRESH)),
        (MGR, True, sel("balanceOfEpoch(address,uint256)") + addr(FRESH) + uint(cur - 1)),
        (MGR, True, sel("balanceOfEpoch(address,uint256)") + addr(FRESH) + uint(cur)),
        (MGR, True, sel("getAllUnclaimedRewards(address)") + addr(FRESH)),
    ], extra=fund)
    out["donation_to_FRESH"] = {
        "fresh_balance_before": dec_uint(res[0][1]) if res[0][0] else None,
        "fresh_balEp_cur1_before": dec_uint(res[1][1]) if res[1][0] else None,
        "stakeTo_success": res[2][0], "stakeTo_revert": None if res[2][0] else reason(res[2][1]),
        "fresh_balance_after": dec_uint(res[3][1]) if res[3][0] else None,
        "fresh_balEp_cur1_after": dec_uint(res[4][1]) if res[4][0] else None,
        "fresh_balEp_cur_after": dec_uint(res[5][1]) if res[5][0] else None,
        "fresh_unclaimed_after": dec_uarr(res[6][1]) if res[6][0] else None,
    }
    return out, cur

# ------------------------------------------------------------------ section 3
def section3_fresh_sweep():
    cur = dec_uint(one_call(MGR, sel("getCurrentEpoch()")))
    writes = [
        ("claimRewards", sel("claimRewards()")),
        ("exit", sel("exit()")),
        ("exitWithHint", sel("exitWithHint(uint256)") + uint(3)),
        ("withdraw1", sel("withdraw(uint256)") + uint(1)),
        ("withdrawWithHint", sel("withdrawWithHint(uint256,uint256)") + uint(1) + uint(3)),
        ("withdrawAndGetReward", sel("withdrawAndGetReward(uint256)") + uint(1)),
        ("withdrawAndGetRewardWithHint", sel("withdrawAndGetRewardWithHint(uint256,uint256)") + uint(1) + uint(3)),
        ("withdrawTo", sel("withdrawTo(uint256,address)") + uint(1) + addr(FRESH)),
        ("withdrawToWithHint", sel("withdrawToWithHint(uint256,address,uint256)") + uint(1) + addr(FRESH) + uint(3)),
        ("withdrawToAndGetReward", sel("withdrawToAndGetReward(uint256,address)") + uint(1) + addr(FRESH)),
        ("withdrawToAndGetRewardWithHint", sel("withdrawToAndGetRewardWithHint(uint256,address,uint256)") + uint(1) + addr(FRESH) + uint(3)),
        ("withdrawReturnedFees_true", sel("withdrawReturnedFees(bool)") + uint(1)),
        ("withdrawReturnedFees_false", sel("withdrawReturnedFees(bool)") + uint(0)),
        ("withdrawReturnedFeesTo_true", sel("withdrawReturnedFeesTo(address,bool)") + addr(FRESH) + uint(1)),
        ("withdrawReturnedFeesTo_false", sel("withdrawReturnedFeesTo(address,bool)") + addr(FRESH) + uint(0)),
        ("stake", sel("stake(uint256)") + uint(1)),
        ("stakeWithHint", sel("stakeWithHint(uint256,uint256)") + uint(1) + uint(0)),
        ("stakeToWithHint", sel("stakeToWithHint(uint256,address,uint256)") + uint(1) + addr(FRESH) + uint(0)),
        ("updateTotalSupplyByEpochIfNeeded", "0xa63d3646" + uint(cur - 2)),
    ]
    calls = [(MGR, True, cd) for _, cd in writes]
    for t in TOKENS:
        calls.append((t, True, sel("balanceOf(address)") + addr(FRESH)))
    res = mc3_over(FRESH, calls)
    sweep = {}
    for i, (name, _) in enumerate(writes):
        ok, ret = res[i]
        sweep[name] = {"success": ok, "revert": None if ok else reason(ret), "ret": ret[:66] if ok and ret != "0x" else None}
    fresh_balances = {}
    for i, t in enumerate(TOKENS):
        ok, ret = res[len(writes) + i]
        fresh_balances[SYM[i]] = {"call_ok": ok, "balance": dec_uint(ret) if ok else None}
    return {"sweep": sweep, "fresh_balances_after": fresh_balances, "cur": cur}

# ------------------------------------------------------------------ section 4
def section4_epoch_totals():
    cur = dec_uint(one_call(MGR, sel("getCurrentEpoch()")))
    out = []
    for e in [cur - 2, cur - 3, cur - 5, cur, cur + 1]:
        stored_before = dec_int(one_call(MGR, sel("totalSupplyByEpoch(uint256)") + uint(e)))
        d = direct("direct", MGR, "0xa63d3646" + uint(e), FRESH)
        res = mc3_over(FRESH, [
            (MGR, True, "0xa63d3646" + uint(e)),
            (MGR, True, sel("totalSupplyByEpoch(uint256)") + uint(e)),
        ])
        out.append({
            "epoch": e, "stored_before": stored_before, "direct": d,
            "call_success": res[0][0], "call_revert": None if res[0][0] else reason(res[0][1]),
            "returned": res[0][1] if res[0][0] else None,
            "stored_after_in_call": dec_int(res[1][1]) if res[1][0] else None,
        })
    return out

# ------------------------------------------------------------------ section 5
def section5_farm():
    out = {}
    allowedA = "0x9EbF96373f24A8836d3899C9ff17451F802E8c72"
    allowedB = "0x43fc122D6dDa2c07301ee131Fa2afa8Bf5854A07"
    for name, a in [("allowedA_9EbF", allowedA), ("allowedB_43fc", allowedB), ("fresh", FRESH)]:
        checks = []
        for fn, data in [
            ("withdrawFor(1,FRESH)", sel("withdrawFor(uint256,address)") + uint(1) + addr(FRESH)),
            ("withdrawAndGetRewardFor(1,FRESH)", sel("withdrawAndGetRewardFor(uint256,address)") + uint(1) + addr(FRESH)),
            ("stakeFor(1,FRESH)", sel("stakeFor(uint256,address)") + uint(1) + addr(FRESH)),
            ("withdraw(1)", sel("withdraw(uint256)") + uint(1)),
            ("exit()", sel("exit()")),
            ("getReward()", sel("getReward()")),
            ("rescueUnclaimedTokens(FRESH,1)", sel("rescueUnclaimedTokens(address,uint256)") + addr(FRESH) + uint(1)),
            ("rescue(FRESH,1)", sel("rescue(address,uint256)") + addr(FRESH) + uint(1)),
            ("updateAllowedCaller(FRESH,true)", sel("updateAllowedCaller(address,bool)") + addr(FRESH) + uint(1)),
            ("notifyRewardAmount(1,0)", sel("notifyRewardAmount(uint256,uint256)") + uint(1) + uint(0)),
        ]:
            checks.append(direct(fn, FARM, data, a))
        out[name] = checks
    res = mc3_over(allowedB, [
        (FARM, True, sel("balanceOf(address)") + addr(allowedB)),
        (EXFI, True, sel("balanceOf(address)") + addr(allowedB)),
        (FARM, True, sel("exit()")),
        (EXFI, True, sel("balanceOf(address)") + addr(allowedB)),
        (FARM, True, sel("balanceOf(address)") + addr(allowedB)),
    ])
    out["allowedB_exit_self"] = {
        "farm_bal_before": dec_uint(res[0][1]) if res[0][0] else None,
        "exfi_before": dec_uint(res[1][1]) if res[1][0] else None,
        "exit_success": res[2][0], "exit_revert": None if res[2][0] else reason(res[2][1]),
        "exfi_after": dec_uint(res[3][1]) if res[3][0] else None,
        "farm_bal_after": dec_uint(res[4][1]) if res[4][0] else None,
    }
    return out

# ------------------------------------------------------------------ section 6
def section6_fees():
    """Fee-path read-after-write for a no-fee account and for U2 (which holds 0.0011 EXFI of
    unprocessed fees): does any call move tokens, and does a third party's call touch U2's records?"""
    out = {}
    def run(caller, calls, tag):
        res = mc3_over(caller, calls)
        return {"tag": tag, "res": [{"ok": r[0], "ret": r[1][:80], "reason": None if r[0] else reason(r[1])} for r in res]}
    # fresh: withdrawReturnedFees(false) and To(ATTACKER,false) with balances + locked fees around
    calls = []
    for t in TOKENS:
        calls.append((t, True, sel("balanceOf(address)") + addr(FRESH)))
    calls += [
        (MGR, True, sel("totalLockedFees()")),
        (MGR, True, sel("withdrawReturnedFees(bool)") + uint(0)),
        (MGR, True, sel("totalLockedFees()")),
        (MGR, True, sel("withdrawReturnedFeesTo(address,bool)") + addr(ATTACKER) + uint(0)),
        (MGR, True, sel("totalLockedFees()")),
    ]
    for t in TOKENS:
        calls.append((t, True, sel("balanceOf(address)") + addr(ATTACKER)))
    for t in TOKENS:
        calls.append((t, True, sel("balanceOf(address)") + addr(FRESH)))
    res = mc3_over(FRESH, calls)
    out["fresh_fee_calls"] = {
        "fresh_before": {SYM[i]: dec_uint(res[i][1]) for i in range(8)},
        "locked_before": dec_uint(res[8][1]),
        "call_false": {"ok": res[9][0], "ret": res[9][1]},
        "locked_mid": dec_uint(res[10][1]),
        "callTo_attacker_false": {"ok": res[11][0], "ret": res[11][1]},
        "locked_after": dec_uint(res[12][1]),
        "attacker_after": {SYM[i]: dec_uint(res[13 + i][1]) for i in range(8)},
        "fresh_after": {SYM[i]: dec_uint(res[21 + i][1]) for i in range(8)},
    }
    # attacker-as-caller with attacker as recipient: does anything reach the attacker or touch U2?
    res = mc3_over(ATTACKER, [
        (EXFI, True, sel("balanceOf(address)") + addr(U2)),
        (MGR, True, sel("getUserUnprocessedFees(address)") + addr(U2)),
        (MGR, True, sel("withdrawReturnedFeesTo(address,bool)") + addr(ATTACKER) + uint(0)),
        (EXFI, True, sel("balanceOf(address)") + addr(ATTACKER)),
        (EXFI, True, sel("balanceOf(address)") + addr(U2)),
        (MGR, True, sel("getUserUnprocessedFees(address)") + addr(U2)),
    ])
    b = res[1][1][2:]; fees_before = [int(b[i * 64:(i + 1) * 64], 16) for i in range(3)]
    b = res[5][1][2:]; fees_after = [int(b[i * 64:(i + 1) * 64], 16) for i in range(3)]
    out["attacker_fee_calls"] = {
        "u2_exfi_before": dec_uint(res[0][1]), "u2_fees_before": fees_before,
        "call_ok": res[2][0], "call_reason": None if res[2][0] else reason(res[2][1]),
        "attacker_exfi_after": dec_uint(res[3][1]), "u2_exfi_after": dec_uint(res[4][1]),
        "u2_fees_after": fees_after,
    }
    # U2 self: withdrawReturnedFees(true) and (false) with balance reads
    res = mc3_over(U2, [
        (EXFI, True, sel("balanceOf(address)") + addr(U2)),
        (MGR, True, sel("withdrawReturnedFees(bool)") + uint(1)),
        (MGR, True, sel("withdrawReturnedFees(bool)") + uint(0)),
        (EXFI, True, sel("balanceOf(address)") + addr(U2)),
    ])
    out["u2_fee_calls"] = {
        "exfi_before": dec_uint(res[0][1]),
        "true_ok": res[1][0], "true_reason": None if res[1][0] else reason(res[1][1]),
        "false_ok": res[2][0], "false_reason": None if res[2][0] else reason(res[2][1]),
        "exfi_after": dec_uint(res[3][1]),
    }
    return out


def main():
    block0 = int(rpc("eth_blockNumber", []), 16)
    results["meta"] = {"block_start": block0}
    for name, fn in [("S1_fresh_direct", section1_fresh_direct),
                     ("S2_staker_context", section2_staker_context),
                     ("S3_fresh_sweep", section3_fresh_sweep),
                     ("S4_epoch_totals", section4_epoch_totals),
                     ("S5_farm", section5_farm),
                     ("S6_fees", section6_fees)]:
        try:
            r = fn()
            if name == "S2_staker_context":
                r, cur = r
                results["cur"] = cur
            results[name] = r
            print(f"## {name} OK")
        except Exception as e:
            results[name] = {"EXCEPTION": str(e)}
            print(f"## {name} EXCEPTION: {e}")
        json.dump(results, open("probes.json", "w"), indent=1, default=str)
    results["meta"]["block_end"] = int(rpc("eth_blockNumber", []), 16)
    json.dump(results, open("probes.json", "w"), indent=1, default=str)
    print("saved probes.json")

if __name__ == "__main__":
    main()
