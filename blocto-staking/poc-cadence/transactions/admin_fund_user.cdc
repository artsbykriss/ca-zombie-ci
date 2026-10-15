import BloctoToken from 0x0f9df91c9121c460
import FungibleToken from 0xf233dcee88fe0abe

// Contract account mints BLT to a user (test-harness funding only; not part of any gate).
transaction(recipient: Address, amount: UFix64) {
    prepare(signer: auth(Storage) &Account) {
        let minter = signer.storage.borrow<auth(BloctoToken.MinterEntitlement) &BloctoToken.Minter>(from: /storage/bloctoTokenStakingMinter) ?? panic("could not borrow BLT minter")
        let vault <- minter.mintTokens(amount: amount)
        let receiver = getAccount(recipient).capabilities.borrow<&{FungibleToken.Receiver}>(BloctoToken.TokenPublicReceiverPath) ?? panic("recipient has no BLT receiver")
        receiver.deposit(from: <-vault)
    }
}
