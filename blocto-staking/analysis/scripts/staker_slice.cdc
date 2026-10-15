import BloctoTokenStaking from 0x0f9df91c9121c460

access(all) fun main(start: UInt64, end: UInt64): {String: AnyStruct} {
    let ids = BloctoTokenStaking.getStakerIDsSlice(start: start, end: end)
    var sStaked = 0.0
    var sCommitted = 0.0
    var sUnstaked = 0.0
    var sRewarded = 0.0
    var sRequested = 0.0
    var nStaked = 0
    var nAny = 0
    for id in ids {
        let info = BloctoTokenStaking.StakerInfo(stakerID: id)
        sStaked = sStaked + info.tokensStaked
        sCommitted = sCommitted + info.tokensCommitted
        sUnstaked = sUnstaked + info.tokensUnstaked
        sRewarded = sRewarded + info.tokensRewarded
        sRequested = sRequested + info.tokensRequestedToUnstake
        if info.tokensStaked > 0.0 { nStaked = nStaked + 1 }
        if info.totalTokensInRecord() > 0.0 { nAny = nAny + 1 }
    }
    return {
        "blockHeight": getCurrentBlock().height,
        "start": start,
        "end": end,
        "count": ids.length,
        "sumStaked": sStaked,
        "sumCommitted": sCommitted,
        "sumUnstaked": sUnstaked,
        "sumRewarded": sRewarded,
        "sumRequestedToUnstake": sRequested,
        "nWithStaked": nStaked,
        "nWithAnyTokens": nAny
    }
}
