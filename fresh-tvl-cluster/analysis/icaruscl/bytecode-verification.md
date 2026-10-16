# Icarus CL — verified-source status (RISE explorer, Blockscout API)

`https://explorer.risechain.com/api?module=contract&action=getsourcecode` returns verified sources for:

| contract | address | name | notes |
|---|---|---|---|
| CLFactory | `0x6f7DA11c13Ba09A153dA06d376044e5859Db607B` | CLFactory | solc 0.7.6; old-gen Aerodrome Slipstream (has `nft`, `gaugeFactory`, `gaugeImplementation`, `setNonfungiblePositionManager`). |
| CLPool impl | `0x4356B9347D963076406187ED7BE73c526F071E53` | CLPool | diff vs aerodrome slipstream main: only old-gen `initialize(_gauge,_nft)` (no factoryRegistry / setGaugeAndPositionManager), a `tokens()` view, and the `getRewardGrowthInside` SLOAD cache. No auth drift in mint/burn/collect/swap/flash/stake/collectFees. |
| NonfungiblePositionManager | `0x195D3037cb4AF610B96EF2984b4013eE836568E1` | NonfungiblePositionManager | old-gen NPM (has `_userPositions` index, `increaseLiquidity` rejects staked positions); `collect`/`decreaseLiquidity`/`burn` all `isAuthorizedForToken`. |
| CLGauge impl | `0xe418Ae485B9057f13223dD76657eac103bCbF127` | CLGauge | `getReward(uint256)`/`withdraw(uint256)` require `_stakes[msg.sender]`; `getReward(address)` voter-only; `deposit` requires NFT ownership + pool match + `voter.isAlive`. |
| CLGaugeFactory | `0x42ac2D74117BbCFa92142Bb4CBc045fbbb959329` | CLGaugeFactory | gauge creation wired to voter. |
| owner | `0x838fc4155Fc13B3b75030950Fd9B58DbCE874aE0` | SafeProxy | 172-byte Safe proxy (contract, not EOA). |
