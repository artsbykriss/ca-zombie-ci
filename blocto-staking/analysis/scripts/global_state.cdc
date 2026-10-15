import BloctoTokenStaking from 0x0f9df91c9121c460
import BloctoToken from 0x0f9df91c9121c460

access(all) fun main(): {String: AnyStruct} {
    let acct = getAccount(0x0f9df91c9121c460)
    let defaultVault = acct.capabilities.borrow<&BloctoToken.Vault>(/public/bloctoTokenBalance)
    return {
        "blockHeight": getCurrentBlock().height,
        "stakingEnabled": BloctoTokenStaking.getStakingEnabled(),
        "totalStaked": BloctoTokenStaking.getTotalStaked(),
        "stakerIDCount": BloctoTokenStaking.getStakerIDCount(),
        "epoch": BloctoTokenStaking.getEpoch(),
        "epochTokenPayout": BloctoTokenStaking.getEpochTokenPayout(),
        "bltTotalSupply": BloctoToken.totalSupply,
        "contractDefaultVaultBalance": defaultVault != nil ? defaultVault!.balance : -1.0,
        "hasPublicBloctoPassMinter": acct.capabilities.exists(/public/bloctoPassMinter),
        "hasPublicBloctoPassCollection": acct.capabilities.exists(/public/bloctoPassCollection)
    }
}
