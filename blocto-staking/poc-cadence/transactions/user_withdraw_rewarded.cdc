import BloctoPass from 0x0f9df91c9121c460

// C2 (core): withdraw tokens from the staker's tokensRewarded bucket.
//
// BloctoPass.NFT.withdrawRewardedTokens -> BloctoTokenStaking.Staker.withdrawRewardedTokens
// NOTE: BloctoTokenStaking.Staker.withdrawRewardedTokens has NO `stakingEnabled` precondition.
// => works while the system is frozen.
transaction(passID: UInt64, amount: UFix64) {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        let collection = signer.capabilities.storage
            .issue<auth(BloctoPass.CollectionPrivateEntitlement) &BloctoPass.Collection>(BloctoPass.CollectionStoragePath)
            .borrow()
            ?? panic("could not borrow private collection reference")

        let pass = collection.borrowBloctoPassPrivate(id: passID)
        pass.withdrawRewardedTokens(amount: amount)
    }
}
