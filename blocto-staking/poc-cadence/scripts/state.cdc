import BloctoTokenStaking from 0x0f9df91c9121c460
import BloctoPass from 0x0f9df91c9121c460

// Global state of the live-mirrored staking system.
access(all) fun main(): {String: AnyStruct} {
    return {
        "stakingEnabled": BloctoTokenStaking.getStakingEnabled(),
        "totalStaked": BloctoTokenStaking.getTotalStaked(),
        "epoch": BloctoTokenStaking.getEpoch(),
        "epochTokenPayout": BloctoTokenStaking.getEpochTokenPayout(),
        "stakerRecordCount": BloctoTokenStaking.getStakerIDCount(),
        "bloctoPassTotalSupply": BloctoPass.totalSupply
    }
}
