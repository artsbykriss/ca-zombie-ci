import BloctoTokenStaking from 0x0f9df91c9121c460

// Unfreeze: sets BloctoTokenStaking.stakingEnabled = true.
// Only reachable by the contract account (the Admin resource lives in its storage).
transaction {
    prepare(signer: auth(Storage) &Account) {
        let admin = signer.storage
            .borrow<auth(BloctoTokenStaking.AdminEntitlement) &BloctoTokenStaking.Admin>(from: BloctoTokenStaking.StakingAdminStoragePath)
            ?? panic("could not borrow staking admin")
        admin.startStakingAuction()
    }
}
