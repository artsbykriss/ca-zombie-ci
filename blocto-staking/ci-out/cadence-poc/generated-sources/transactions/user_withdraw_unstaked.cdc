import BloctoPass from 0xe03daebed8ca0615

// C2 (core): withdraw tokens from the staker's tokensUnstaked bucket.
//
// BloctoPass.NFT.withdrawUnstakedTokens -> BloctoTokenStaking.Staker.withdrawUnstakedTokens
// NOTE: BloctoTokenStaking.Staker.withdrawUnstakedTokens has NO `stakingEnabled` precondition
// (unlike stakeNewTokens / stakeUnstakedTokens / stakeRewardedTokens / requestUnstaking / unstakeAll).
// => works while the system is frozen.
transaction(passID: UInt64, amount: UFix64) {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        let collection = signer.capabilities.storage
            .issue<auth(BloctoPass.CollectionPrivateEntitlement) &BloctoPass.Collection>(BloctoPass.CollectionStoragePath)
            .borrow()
            ?? panic("could not borrow private collection reference")

        let pass = collection.borrowBloctoPassPrivate(id: passID)
        pass.withdrawUnstakedTokens(amount: amount)
    }
}
