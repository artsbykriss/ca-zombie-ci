import BloctoTokenStaking from 0xe03daebed8ca0615

// Admin-only. Pre-condition: !stakingEnabled ("Cannot pay rewards if the staking
// auction is still in progress"). Mints epochTokenPayout * staked/totalStaked BLT
// into the staker's tokensRewarded bucket, using the minter stored at
// /storage/bloctoTokenStakingMinter.
transaction(stakerID: UInt64) {
    prepare(signer: auth(Storage) &Account) {
        let admin = signer.storage
            .borrow<auth(BloctoTokenStaking.AdminEntitlement) &BloctoTokenStaking.Admin>(from: BloctoTokenStaking.StakingAdminStoragePath)
            ?? panic("could not borrow staking admin")
        admin.payRewards([stakerID])
    }
}
