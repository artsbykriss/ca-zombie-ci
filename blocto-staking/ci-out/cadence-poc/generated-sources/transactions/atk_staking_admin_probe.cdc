import BloctoTokenStaking from 0xe03daebed8ca0615

// C3 -- the staking Admin resource is unreachable from outside the contract account.
// Signed by an unprivileged outside account.
//
//  (a) no public capability is published for the Admin (BloctoTokenStaking.init only
//      storage.save()s it, it never capabilities.publish()es it);
//  (b) a random account has no Admin resource at /storage/bloctoTokenStakingAdmin.
transaction(contractAccount: Address) {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        let viaPublic = getAccount(contractAccount).capabilities.borrow<auth(BloctoTokenStaking.AdminEntitlement) &BloctoTokenStaking.Admin>(/public/bloctoTokenStakingAdmin)
        assert(viaPublic == nil, message: "UNEXPECTED: /public/bloctoTokenStakingAdmin yields the staking Admin")

        let plainAdmin = getAccount(contractAccount).capabilities.borrow<&BloctoTokenStaking.Admin>(/public/bloctoTokenStakingAdmin)
        assert(plainAdmin == nil, message: "UNEXPECTED: a plain &Admin is borrowable from a public path")

        let inOwnStorage = signer.storage.borrow<auth(BloctoTokenStaking.AdminEntitlement) &BloctoTokenStaking.Admin>(from: /storage/bloctoTokenStakingAdmin)
        assert(inOwnStorage == nil, message: "UNEXPECTED: unprivileged account's storage contains a staking Admin")
    }
}
