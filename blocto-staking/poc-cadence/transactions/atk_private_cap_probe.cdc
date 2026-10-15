import BloctoPass from 0x0f9df91c9121c460
import NonFungibleToken from 0x1d7e57aa55817448
import FungibleToken from 0xf233dcee88fe0abe

// C3 -- RUNTIME GATE. Executes successfully ONLY if none of the private-capable
// borrows from the victim's PUBLIC capability succeed. Any success aborts with a
// distinct "UNEXPECTED" message, so the tx result is a clean PASS/FAIL signal.
//
// Signed by a third party (the contract account) -- not the victim.
transaction(victim: Address) {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        let acct = getAccount(victim)

        // 1. entitled reference to the concrete Collection (would expose every private method)
        let entitledConcrete = acct.capabilities.borrow<auth(BloctoPass.CollectionPrivateEntitlement) &BloctoPass.Collection>(BloctoPass.CollectionPublicPath)
        assert(entitledConcrete == nil, message: "UNEXPECTED: public path yielded an entitled concrete &BloctoPass.Collection")

        // 2. NOTE / documented nuance: a plain *unentitled* &BloctoPass.Collection IS
        //    borrowable from the public capability (ordinary Cadence reference narrowing
        //    of &{CollectionPublic} to the concrete type). That grants NO extra authority:
        //    every staking/withdraw method on the concrete resource is declared
        //    access(CollectionPrivateEntitlement), and the entitlement-bearing borrows
        //    in checks 1, 3 and 4 are the ones that must stay nil.
        let concrete = acct.capabilities.borrow<&BloctoPass.Collection>(BloctoPass.CollectionPublicPath)
        assert(concrete != nil, message: "expected narrowing to the plain concrete reference to succeed (it is unentitled and harmless)")

        // 3. interface-typed private reference
        let privateIface = acct.capabilities.borrow<&{BloctoPass.CollectionPrivate}>(BloctoPass.CollectionPublicPath)
        assert(privateIface == nil, message: "UNEXPECTED: public path yielded a &{BloctoPass.CollectionPrivate}")

        // 4. entitled FungibleToken.Withdraw reference (drain the pass vault directly)
        let withdrawRef = acct.capabilities.borrow<auth(FungibleToken.Withdraw) &BloctoPass.NFT>(BloctoPass.CollectionPublicPath)
        assert(withdrawRef == nil, message: "UNEXPECTED: public path yielded an entitled &BloctoPass.NFT")

        // 5. sanity: the public interface really is reachable (otherwise the test is vacuous)
        let publicRef = acct.capabilities.borrow<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>(BloctoPass.CollectionPublicPath)
        assert(publicRef != nil, message: "expected the public collection capability to be borrowable")
        assert(publicRef!.getIDs().length >= 0, message: "unreachable")
    }
}
