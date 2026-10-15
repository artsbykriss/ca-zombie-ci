import BloctoPass from 0x0f9df91c9121c460
import BloctoTokenStaking from 0x0f9df91c9121c460
import NonFungibleToken from 0x1d7e57aa55817448

access(all) fun main(): {String: AnyStruct} {
    let acct = getAccount(0x0f9df91c9121c460)
    // contract account's own BloctoPass collection
    let collRef = acct.capabilities.borrow<&{NonFungibleToken.CollectionPublic}>(/public/bloctoPassCollection)
    var ids: [UInt64] = []
    if collRef != nil {
        ids = collRef!.getIDs()
    }
    var nftInfo: [[AnyStruct]] = []
    let passRef = acct.capabilities.borrow<&{BloctoPass.CollectionPublic}>(/public/bloctoPassCollection)
    if passRef != nil {
        for id in ids {
            let nft = passRef!.borrowBloctoPassPublic(id: id)
            nftInfo.append([id, nft.getIdleBalance(), nft.getTotalBalance(), nft.getStakingInfo().totalTokensInRecord()] as [AnyStruct])
        }
    }
    return {
        "blockHeight": getCurrentBlock().height,
        "bloctoPassTotalSupply": BloctoPass.totalSupply,
        "contractAccountCollectionIDs": ids,
        "nftInfo": nftInfo,
        "publicStampCollectionExists": acct.capabilities.exists(/public/bloctoPassStampCollection),
        "publicStampMinterExists": acct.capabilities.exists(/public/bloctoPassStampMinter)
    }
}
