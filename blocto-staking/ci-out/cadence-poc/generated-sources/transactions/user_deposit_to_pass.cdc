import BloctoPass from 0xe03daebed8ca0615
import BloctoToken from 0xe03daebed8ca0615
import FungibleToken from 0x179b6b1cb6755e31

// Pass owner moves BLT from their own vault into their BloctoPass.
// BloctoPass.NFT.deposit is access(all) -- reachable through the *public* collection ref.
transaction(passID: UInt64, amount: UFix64) {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        let vault = signer.storage.borrow<auth(FungibleToken.Withdraw) &BloctoToken.Vault>(from: BloctoToken.TokenStoragePath) ?? panic("could not borrow own BLT vault")
        let coll = signer.capabilities.borrow<&{BloctoPass.CollectionPublic}>(BloctoPass.CollectionPublicPath) ?? panic("could not borrow own collection")
        let pass = coll.borrowBloctoPassPublic(id: passID)
        pass.deposit(from: <-vault.withdraw(amount: amount))
    }
}
