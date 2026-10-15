import BloctoTokenStaking from 0xe03daebed8ca0615
import BloctoPass from 0xe03daebed8ca0615

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
