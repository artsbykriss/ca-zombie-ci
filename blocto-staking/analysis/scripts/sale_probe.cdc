import BloctoTokenSale from 0x0f9df91c9121c460

access(all) fun main(): {String: AnyStruct} {
    return {
        "blockHeight": getCurrentBlock().height,
        "isSaleActive": BloctoTokenSale.getIsSaleActive(),
        "price": BloctoTokenSale.getPrice(),
        "bltVaultBalance": BloctoTokenSale.getBltVaultBalance(),
        "tusdtVaultBalance": BloctoTokenSale.getTusdtVaultBalance(),
        "purchaserCount": BloctoTokenSale.getPurchasers().length,
        "personalCap": BloctoTokenSale.getPersonalCap()
    }
}
