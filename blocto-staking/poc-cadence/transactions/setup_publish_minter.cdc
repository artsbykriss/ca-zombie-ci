import BloctoPass from 0x0f9df91c9121c460

// Mirror of the live mainnet state: the contract account publishes the NFTMinter
// at /public/bloctoPassMinter, typed &{BloctoPass.MinterPublic}
// (verified live by the parent session; MinterPublic only declares mintBasicNFT).
transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        let cap = signer.capabilities.storage
            .issue<&{BloctoPass.MinterPublic}>(BloctoPass.MinterStoragePath)
        signer.capabilities.publish(cap, at: BloctoPass.MinterPublicPath)
    }
}
