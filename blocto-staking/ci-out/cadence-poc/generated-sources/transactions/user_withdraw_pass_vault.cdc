import BloctoPass from 0xe03daebed8ca0615
import BloctoToken from 0xe03daebed8ca0615
import FungibleToken from 0x179b6b1cb6755e31

// After a staker withdrawal, the value sits in the BloctoPass NFT's own vault.
// The owner can pull it out to their own BLT vault (Collection.borrowWithdraw gives
// auth(FungibleToken.Withdraw) &BloctoPass.NFT).
transaction(passID: UInt64, amount: UFix64) {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        let cap = signer.capabilities.storage.issue<auth(BloctoPass.CollectionPrivateEntitlement) &BloctoPass.Collection>(BloctoPass.CollectionStoragePath)
        let collection = cap.borrow() ?? panic("could not borrow private collection reference")
        let vault <- collection.borrowWithdraw(id: passID).withdraw(amount: amount)
        let receiver = signer.capabilities.borrow<&{FungibleToken.Receiver}>(BloctoToken.TokenPublicReceiverPath) ?? panic("could not borrow own BLT receiver")
        receiver.deposit(from: <-vault)
    }
}
