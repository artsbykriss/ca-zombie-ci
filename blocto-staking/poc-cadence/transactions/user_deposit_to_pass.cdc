import BloctoPass from 0x0f9df91c9121c460
import BloctoToken from 0x0f9df91c9121c460
import FungibleToken from 0xf233dcee88fe0abe

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
