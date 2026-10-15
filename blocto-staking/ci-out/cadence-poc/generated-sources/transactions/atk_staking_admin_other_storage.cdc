import BloctoTokenStaking from 0xe03daebed8ca0615

// C3 -- COMPILE-TIME GATE (expected to be rejected by the Cadence checker).
// Account.storage is access(Storage); no outside account can even name another
// account's storage to reach /storage/bloctoTokenStakingAdmin.
transaction(contractAccount: Address) {
    prepare(signer: auth(Storage) &Account) {
        // EXPECTED: checker error, `storage` requires authorization on the target account.
        let admin = getAccount(contractAccount).storage
            .borrow<auth(BloctoTokenStaking.AdminEntitlement) &BloctoTokenStaking.Admin>(from: /storage/bloctoTokenStakingAdmin)
        admin?.setEpochTokenPayout(0.0)
    }
}
