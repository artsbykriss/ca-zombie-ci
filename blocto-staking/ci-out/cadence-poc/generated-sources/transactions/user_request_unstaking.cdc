import BloctoPass from 0xe03daebed8ca0615

// Owner requests unstaking. Pre-condition: stakingEnabled == true
// (BloctoTokenStaking.Staker.requestUnstaking).
// With tokensCommitted >= amount the tokens land directly in tokensUnstaked.
transaction(passID: UInt64, amount: UFix64) {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        let collection = signer.capabilities.storage
            .issue<auth(BloctoPass.CollectionPrivateEntitlement) &BloctoPass.Collection>(BloctoPass.CollectionStoragePath)
            .borrow()
            ?? panic("could not borrow private collection reference")

        let pass = collection.borrowBloctoPassPrivate(id: passID)
        pass.requestUnstaking(amount: amount)
    }
}
