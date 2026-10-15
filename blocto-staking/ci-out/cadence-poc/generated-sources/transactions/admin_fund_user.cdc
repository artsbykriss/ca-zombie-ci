import BloctoToken from 0xe03daebed8ca0615
import FungibleToken from 0x179b6b1cb6755e31

// Contract account mints BLT to a user (test-harness funding only; not part of any gate).
transaction(recipient: Address, amount: UFix64) {
    prepare(signer: auth(Storage) &Account) {
        let minter = signer.storage.borrow<auth(BloctoToken.MinterEntitlement) &BloctoToken.Minter>(from: /storage/bloctoTokenStakingMinter) ?? panic("could not borrow BLT minter")
        let vault <- minter.mintTokens(amount: amount)
        let receiver = getAccount(recipient).capabilities.borrow<&{FungibleToken.Receiver}>(BloctoToken.TokenPublicReceiverPath) ?? panic("recipient has no BLT receiver")
        receiver.deposit(from: <-vault)
    }
}
