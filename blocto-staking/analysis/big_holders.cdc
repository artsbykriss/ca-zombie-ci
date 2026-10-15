import BloctoTokenStaking from 0x0f9df91c9121c460

access(all) fun main(start: UInt64, end: UInt64, threshold: UFix64): [[AnyStruct]] {
    let ids = BloctoTokenStaking.getStakerIDsSlice(start: start, end: end)
    var out: [[AnyStruct]] = []
    for id in ids {
        let info = BloctoTokenStaking.StakerInfo(stakerID: id)
        if info.tokensStaked + info.tokensUnstaked + info.tokensRewarded + info.tokensCommitted > threshold {
            out.append([id, info.tokensStaked, info.tokensUnstaked, info.tokensRewarded, info.tokensCommitted, info.tokensRequestedToUnstake] as [AnyStruct])
        }
    }
    return out
}
