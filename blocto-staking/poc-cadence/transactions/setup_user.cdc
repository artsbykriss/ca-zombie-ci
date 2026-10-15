import BloctoPass from 0x0f9df91c9121c460
import BloctoToken from 0x0f9df91c9121c460
import NonFungibleToken from 0x1d7e57aa55817448
import FungibleToken from 0xf233dcee88fe0abe

// A fresh, unprivileged account creates its own BloctoPass collection and BLT vault.
// Nothing here needs any permission from the Blocto contract account.
transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        signer.storage.save(
            <-BloctoPass.createEmptyCollection(nftType: Type<@BloctoPass.NFT>()),
            to: BloctoPass.CollectionStoragePath
        )
        signer.capabilities.publish(
            signer.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>(
                BloctoPass.CollectionStoragePath
            ),
            at: BloctoPass.CollectionPublicPath
        )

        signer.storage.save(
            <-BloctoToken.createEmptyVault(vaultType: Type<@BloctoToken.Vault>()),
            to: BloctoToken.TokenStoragePath
        )
        signer.capabilities.publish(
            signer.capabilities.storage.issue<&{FungibleToken.Receiver, FungibleToken.Balance}>(
                BloctoToken.TokenStoragePath
            ),
            at: BloctoToken.TokenPublicReceiverPath
        )
        // mirrors BloctoToken.init, which publishes the same vault at BOTH paths
        signer.capabilities.publish(
            signer.capabilities.storage.issue<&{FungibleToken.Balance}>(
                BloctoToken.TokenStoragePath
            ),
            at: BloctoToken.TokenPublicBalancePath
        )
    }
}
