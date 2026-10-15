import BloctoPass from 0x0f9df91c9121c460

// NEGATIVE CONTROL for C2: the same frozen state that does NOT block
// withdrawUnstakedTokens/withdrawRewardedTokens DOES block the staking direction.
// BloctoTokenStaking.Staker.stakeUnstakedTokens has
//   pre { BloctoTokenStaking.stakingEnabled: "Cannot stake if the staking auction isn't in progress" }
// => expected to revert while frozen.
transaction(passID: UInt64, amount: UFix64) {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        let collection = signer.capabilities.storage
            .issue<auth(BloctoPass.CollectionPrivateEntitlement) &BloctoPass.Collection>(BloctoPass.CollectionStoragePath)
            .borrow()
            ?? panic("could not borrow private collection reference")

        let pass = collection.borrowBloctoPassPrivate(id: passID)
        pass.stakeUnstakedTokens(amount: amount)
    }
}
