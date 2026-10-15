import BloctoTokenStaking from 0xe03daebed8ca0615

// Freeze: sets BloctoTokenStaking.stakingEnabled = false (the live mainnet state).
// Only reachable by the contract account (the Admin resource lives in its storage).
transaction {
    prepare(signer: auth(Storage) &Account) {
        let admin = signer.storage
            .borrow<auth(BloctoTokenStaking.AdminEntitlement) &BloctoTokenStaking.Admin>(from: BloctoTokenStaking.StakingAdminStoragePath)
            ?? panic("could not borrow staking admin")
        admin.endStakingAuction()
    }
}
