import BloctoTokenStaking from 0xe03daebed8ca0615

// Admin-only. Pre-condition: !stakingEnabled ("Cannot move tokens if the staking
// auction is still in progress"). Committed -> Staked, requested -> Unstaked.
transaction(stakerID: UInt64) {
    prepare(signer: auth(Storage) &Account) {
        let admin = signer.storage
            .borrow<auth(BloctoTokenStaking.AdminEntitlement) &BloctoTokenStaking.Admin>(from: BloctoTokenStaking.StakingAdminStoragePath)
            ?? panic("could not borrow staking admin")
        admin.moveTokens([stakerID])
    }
}
