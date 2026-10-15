import BloctoPass from 0x0f9df91c9121c460
import NonFungibleToken from 0x1d7e57aa55817448

// C3 -- CHECK-TIME GATE (the transaction is rejected by the Cadence checker during
// transaction preprocessing; the body never executes, no state can change).
//
// A third party can only obtain the PUBLISHED public capability; that capability is
// typed &{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}.
// BloctoPass.Collection.borrowBloctoPassPrivate is declared
//   access(CollectionPrivateEntitlement)
// on the concrete resource and is NOT a member of BloctoPass.CollectionPublic,
// therefore the call cannot even be compiled.
//
// This tx is signed by the *contract* account, i.e. it is NOT the pass owner.
transaction(victim: Address) {
    prepare(signer: auth(Storage) &Account) {
        let publicRef = getAccount(victim).capabilities.borrow<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>(BloctoPass.CollectionPublicPath) ?? panic("no public collection capability")

        // EXPECTED: checker error -- "has no member `borrowBloctoPassPrivate`"
        publicRef.borrowBloctoPassPrivate(id: 0)
    }
}
