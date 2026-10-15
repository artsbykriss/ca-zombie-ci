import BloctoPass from 0x0f9df91c9121c460
import BloctoToken from 0x0f9df91c9121c460
import NonFungibleToken from 0x1d7e57aa55817448
import FungibleToken from 0xf233dcee88fe0abe

// Read-only view of an account: BloctoPass ids, balance held inside the first pass,
// and the account's own BLT vault balance.
// Everything is read through PUBLIC capabilities only.
access(all) fun main(user: Address): {String: AnyStruct} {
    let acct = getAccount(user)
    let out: {String: AnyStruct} = {}

    let coll = acct.capabilities.borrow<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>(BloctoPass.CollectionPublicPath)
    out["publicCollectionBorrowable"] = coll != nil

    if let c = coll {
        let ids = c.getIDs()
        out["passIDs"] = ids
        if ids.length > 0 {
            let pass = c.borrowBloctoPassPublic(id: ids[0])
            out["firstPassID"] = pass.id
            out["passVaultBalance"] = pass.getIdleBalance()
            out["passTotalBalance"] = pass.getTotalBalance()
        }
    }

    let balanceRef = acct.capabilities.borrow<&{FungibleToken.Balance}>(BloctoToken.TokenPublicBalancePath)
    out["bltVaultBalance"] = balanceRef?.balance ?? 0.0

    return out
}
