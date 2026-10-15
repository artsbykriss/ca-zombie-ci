import BloctoPass from 0xe03daebed8ca0615
import NonFungibleToken from 0xf3fcd2c1a78f5eee

// C1: an unprivileged external account mints a BloctoPass through the PUBLIC
// minter capability only. No owner/admin rights are used anywhere in this tx.
//
// BloctoPass.NFTMinter.mintBasicNFT -> mintNFT -> mintNFTWithCustomLockup -> create NFT
//   -> BloctoPass.NFT.init -> BloctoPass.account.storage[/storage/bloctoTokenStakingAdmin]
//      .addStakerRecord(id:)  { pre { BloctoTokenStaking.stakingEnabled } }
//
// minterAccount = the account publishing /public/bloctoPassMinter
// the minted BloctoPass is deposited into the SIGNER's own collection
transaction(minterAccount: Address) {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        let minter = getAccount(minterAccount).capabilities.borrow<&{BloctoPass.MinterPublic}>(BloctoPass.MinterPublicPath) ?? panic("could not borrow public minter capability")
        let collection = signer.capabilities.borrow<&{NonFungibleToken.CollectionPublic}>(BloctoPass.CollectionPublicPath) ?? panic("could not borrow own collection")
        minter.mintBasicNFT(recipient: collection)
    }
}
