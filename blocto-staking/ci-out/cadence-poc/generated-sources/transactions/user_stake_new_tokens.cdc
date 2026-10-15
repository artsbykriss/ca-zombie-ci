import BloctoPass from 0xe03daebed8ca0615

// Owner path (what the Blocto frontend does): the pass owner issues themselves the
// CollectionPrivateEntitlement capability over their OWN collection and calls the
// staking method through BloctoPass.NFT (auth(BloctoPassPrivateEntitlement)).
//
// BloctoPass.NFT.stakeNewTokens -> BloctoTokenStaking.Staker.stakeNewTokens
//   { pre { BloctoTokenStaking.stakingEnabled } }
transaction(passID: UInt64, amount: UFix64) {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        let collection = signer.capabilities.storage
            .issue<auth(BloctoPass.CollectionPrivateEntitlement) &BloctoPass.Collection>(BloctoPass.CollectionStoragePath)
            .borrow()
            ?? panic("could not borrow private collection reference")

        let pass = collection.borrowBloctoPassPrivate(id: passID)
        pass.stakeNewTokens(amount: amount)
    }
}
