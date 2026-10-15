import BloctoToken from 0x0f9df91c9121c460

// Contract account creates the BLT minter and stores it at
// /storage/bloctoTokenStakingMinter -- the exact path BloctoTokenStaking.Admin.payRewards
// borrows (live mainnet has a minter there; we reproduce it).
transaction {
    prepare(signer: auth(Storage) &Account) {
        let administrator = signer.storage
            .borrow<auth(BloctoToken.AdministratorEntitlement) &BloctoToken.Administrator>(from: /storage/bloctoTokenAdmin)
            ?? panic("could not borrow BloctoToken administrator")
        let minter <- administrator.createNewMinter(allowedAmount: 1_000_000.0)
        signer.storage.save(<-minter, to: /storage/bloctoTokenStakingMinter)
    }
}
