# Deployed `_handleFlashLoanRepayment` — PATCHED (Fraxtal/Ethereum) vs UNPATCHED (Sonic)

Source of truth: Etherscan V2 verified `L2Pool` at each live EIP-1967 implementation address
(fetched 2026-10-25; raw JSON in this folder: `fraxtal_impl_raw.json`, `eth_impl_raw.json`,
`sonic_impl_raw.json`; extracted sources under `src/`).

| chain | Pool proxy | live impl (EIP-1967) | verified name | compiler | `cumulateToLiquidityIndex` on flash-loan repay |
|---|---|---|---|---|---|
| Fraxtal (252) | `0xD76C827Ee2Ce1E37c37Fc2ce91376812d3c9BCE2` | `0x20a24d51aded06b5ccbc3cc8f71d1e141391a6d7` | L2Pool | 0.8.24 | **NO (patched)** |
| Ethereum (1) | `0x6598DaD18Bda89A0E58A1F427c8CeBc0dE90F153` | `0xeaa40d04b02726a130c3fd54da7aee7835974f1a` | L2Pool | 0.8.22 | **NO (patched)** |
| Sonic (146) | `0xEdC3cfB1aa36c570cc1D374876268bDda2D460CC` | `0x179867c392add1bf4f7a3d4c70bf8f2f476bb8cc` | L2Pool | 0.8.20 | **YES (unpatched)** |

Katana (747474): **no dLEND Pool deployed** (`katana-solidity-contracts/deployments/katana_mainnet`
has no Pool/L2Pool/PoolProxy — only the dUSD/dETH stablecoin system). dLEND exists only on
Ethereum, Sonic, Fraxtal.

---

## Fraxtal impl `0x20a24d51…` — PATCHED

`contracts/lending/core/protocol/libraries/logic/FlashLoanLogic.sol`:

```solidity
function _handleFlashLoanRepayment(...) internal {
    // Route the full flash-loan premium to the protocol treasury.
    //
    // Rationale: attributing any part of the premium to suppliers via
    // `cumulateToLiquidityIndex()` makes the reserve-wide liquidity index
    // sensitive to a thin aToken supply, which is the core condition behind
    // empty / near-empty reserve index inflation exploits.
    //
    // This keeps the total premium paid by the borrower unchanged, while
    // removing the supplier-side instantaneous index jump that made the
    // exploit possible.
    uint256 premiumToProtocol = params.totalPremium;
    uint256 amountPlusPremium = params.amount + params.totalPremium;

    DataTypes.ReserveCache memory reserveCache = reserve.cache();
    reserve.updateState(reserveCache);

    reserve.accruedToTreasury += premiumToProtocol.rayDiv(reserveCache.nextLiquidityIndex).toUint128();
    reserve.updateInterestRates(reserveCache, params.asset, amountPlusPremium, 0);
    IERC20(params.asset).safeTransferFrom(params.receiverAddress, reserveCache.aTokenAddress, amountPlusPremium);
    IAToken(reserveCache.aTokenAddress).handleRepayment(...);
    emit FlashLoan(...);
}
```

→ The premium is **never** passed to `cumulateToLiquidityIndex`; the liquidity index is untouched.
The Ethereum live impl `0xeaa40d04…` contains the **identical** patched body (byte-for-byte comment block).

## Sonic impl `0x179867c3…` — UNPATCHED (stock Aave-V3 vulnerable pattern)

```solidity
function _handleFlashLoanRepayment(...) internal {
    uint256 premiumToProtocol = params.totalPremium.percentMul(params.flashLoanPremiumToProtocol);
    uint256 premiumToLP = params.totalPremium - premiumToProtocol;
    uint256 amountPlusPremium = params.amount + params.totalPremium;

    DataTypes.ReserveCache memory reserveCache = reserve.cache();
    reserve.updateState(reserveCache);
    reserveCache.nextLiquidityIndex = reserve.cumulateToLiquidityIndex(
        IERC20(reserveCache.aTokenAddress).totalSupply() +
            uint256(reserve.accruedToTreasury).rayMul(reserveCache.nextLiquidityIndex),
        premiumToLP
    );
    ...
}
```

`ReserveLogic.cumulateToLiquidityIndex` (all three impls, identical):
```solidity
uint256 result = (amount.wadToRay().rayDiv(totalLiquidity.wadToRay()) + WadRayMath.RAY).rayMul(reserve.liquidityIndex);
reserve.liquidityIndex = result.toUint128();
```
There is **no minimum-liquidity guard** — `premiumToLP / totalLiquidity` blows up when the aToken
scaled supply is tiny. This is the exact 2026-03-17 Ethereum cbBTC root cause (loss ~$257k dUSD,
aToken `0x504d0eac…`, impl `0xfDA3a0ef…`, attacker `0x08cfdff8…`).

## Other `cumulateToLiquidityIndex` call sites (all chains)
- `BridgeLogic.executeBackUnbacked` — reachable only via `Pool.backUnbacked`, gated by
  `onlyBridge` → `ACLManager.isBridge(msg.sender)` (privileged; not E-U).
- `LiquidationLogic` / `SupplyLogic` / `BorrowLogic` — only *read* `nextLiquidityIndex`; they do
  not call `cumulateToLiquidityIndex` in the patched impls.
