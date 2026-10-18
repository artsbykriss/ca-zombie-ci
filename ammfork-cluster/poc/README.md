# PoC status — AMM-fork drift cluster

No Foundry exploit PoC is included for the three primary lanes (Zappy, PegaSys, Arbitris/DORY).

Why:

- **Zappy:** the only candidate paths are redemption/liquidation arithmetic. The single USDM trove is at 358% ICR; redemption pays 49.12 TLOS per USDM = $0.834 at market, exactly the observed USDM price, minus a 5.15% fee. The DEX has zero skim surplus. A fork test would only re-derive the same arithmetic.
- **PegaSys:** every pair's `balanceOf(pair)` equals `getReserves()`; the pair has no `skim()`. The "Chef quest" address is an ERC20, not a farm. There is no call path to test.
- **Arbitris/DORY:** the hook's permission bits are AFTER_SWAP only, with no return-delta flags; the hook holds 0 USDC and 0 DORY and has no withdraw/sweep/claim. The $4.5M is LP-owned PoolManager liquidity. A swap-level fork test would exercise the afterSwap reward mint, but without a hook bug it cannot produce an E-U path.

The cluster CI job (`../ci/run.sh`) re-reads the structural facts on public RPCs and writes `ci-out/verification.json`; it is the reproducibility artifact for these negative results.
