import BloctoPass from 0x0f9df91c9121c460

// C3 -- CHECK-TIME GATE #2 (the sharper one).
//
// A third party CAN narrow the public capability to the plain concrete reference
// &BloctoPass.Collection (see atk_private_cap_probe.cdc check 2). This transaction shows
// that this is worthless: calling the entitled staking method through an unentitled
// reference does not compile, because BloctoPass.Collection.borrowBloctoPassPrivate is
//   access(CollectionPrivateEntitlement)
// and the reference carries no entitlements.
//
// EXPECTED: checker error -- missing entitlement authorization. The body never executes.
transaction(victim: Address) {
    prepare(signer: auth(Storage) &Account) {
        let concrete = getAccount(victim).capabilities.borrow<&BloctoPass.Collection>(BloctoPass.CollectionPublicPath) ?? panic("no concrete collection borrowed")

        // EXPECTED: checker error -- requires BloctoPass.CollectionPrivateEntitlement
        concrete.borrowBloctoPassPrivate(id: 0)
    }
}
