import BloctoTokenStaking from 0x0f9df91c9121c460

// Read-only view of one staker record (id == BloctoPass NFT id).
access(all) fun main(stakerID: UInt64): {String: AnyStruct} {
    let info = BloctoTokenStaking.StakerInfo(stakerID: stakerID)
    return {
        "id": info.id,
        "tokensStaked": info.tokensStaked,
        "tokensCommitted": info.tokensCommitted,
        "tokensUnstaked": info.tokensUnstaked,
        "tokensRewarded": info.tokensRewarded,
        "tokensRequestedToUnstake": info.tokensRequestedToUnstake,
        "totalTokensInRecord": info.totalTokensInRecord()
    }
}
