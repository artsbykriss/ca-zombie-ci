import BloctoPass from 0xe03daebed8ca0615

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
