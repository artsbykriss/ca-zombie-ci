import BloctoPass from 0x0f9df91c9121c460
import BloctoTokenStaking from 0x0f9df91c9121c460

access(all) fun main(): {String: AnyStruct} {
    let acct = getAccount(0x0f9df91c9121c460)

    // probe public minter capability
    let minterCap = acct.capabilities.get<&{BloctoPass.MinterPublic}>(/public/bloctoPassMinter)
    let minterRef = minterCap.borrow()

    // probe public collection capability
    let collCap = acct.capabilities.get<&{BloctoPass.CollectionPublic}>(/public/bloctoPassCollection)

    return {
        "blockHeight": getCurrentBlock().height,
        "minterCapExists": minterCap != nil,
        "minterBorrowOk": minterRef != nil,
        "minterCapAddress": minterCap != nil ? minterCap!.address : nil,
        "minterCapId": minterCap != nil ? minterCap!.id : nil,
        "collectionCapExists": collCap != nil,
        "publicStakingAdminExists": acct.capabilities.exists(/public/bloctoTokenStakingAdmin),
        "publicBLTReceiverExists": acct.capabilities.exists(/public/bloctoTokenReceiver),
        "publicBLTBalanceExists": acct.capabilities.exists(/public/bloctoTokenBalance)
    }
}
