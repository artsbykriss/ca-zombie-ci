# PoC — JustLend Energy Rental (MarketG1)

**TRON is not EVM-forkable with Foundry.** A `vm.createSelectFork` on an EVM chain cannot execute
TVM contracts or the TIP-467 stake precompiles. The PoC therefore uses two read-only methods
against the **deployed proxy**:

1. **`triggerconstantcontract` dry-runs** — TronGrid executes the real deployed bytecode against the
   latest state and returns the ABI return value, event logs and revert reason. Nothing is signed or
   broadcast (`triggerconstantcontract` never changes state).
2. **Shadow ledger** — an exact replay of the verified `MarketG1.sol` repay formulas
   (`_internalRepayForLiquidate`, `_internalRepayForReturn`, `_calculateFee`, `_liquidateCheck`)
   with the live parameters, used to sweep amounts and show the sign of the attacker P&L.

## Files

| File | Purpose |
|---|---|
| `poc.py` | T1 double-refund, T2 dirty-rent, T3 fresh self-liquidation / shadow ledger |
| `tronlib.py` | minimal read-only TRON helper (base58, ABI encode, TronGrid reads) |
| `inputs/liquidated_pairs.json` | 3 public liquidated pairs (tx hashes, block, amounts) |
| `inputs/live_rental_pair.json` | one live rental used for the dirty-rent dry-run |
| `inputs/live_state.json` | snapshot used for parameter context |
| `results/poc_results.json` | full output (return values, logs, reverts, shadow ledger) |

## Results (2026-10-18, block ~87,210,5xx)

* **T1** — 2/2 real liquidated pairs: `rentals = [0,0,index]`; `returnResource` reverts
  `"resource return: no enough rental resource"`; `liquidate` reverts
  `"liquidate: no resource to liquidate"`. The third sampled pair had re-rented after its
  liquidation and is excluded.
* **T2** — live pair `TPWZPDjW…/TS93Z2vg…` (amount 1,042,980.044 TRX): full-return dry-run returns
  `sendBack = 1,027.828748 TRX` and emits `usageRental = 157.363156 TRX`; the effective deposit is
  1,185.191904 TRX, so `deposit - sendBack = 157.363156 TRX` exactly. Energy usage is **charged**;
  it is not free.
* **T3** — shadow ledger: minimum deposit `fee + oneDayRent + 1 sun`. A 1-block self-liquidation has
  net ≈ 0 (rounding only, `−0.000012 TRX` per 1,000 TRX); a 1.2-day self-liquidation has net
  `−oneDayRent` (`−0.371954 TRX` per 1,000 TRX, `−371.95 TRX` per 1M TRX). The market books
  `74.39 TRX` of bad debt per 1M order in the 1.2-day case, but that is not a profit to the attacker.
* **Live state** — `badDebt = badDebtCovered = 481,464,141 sun`, gap 0; energy market unpaused.

## Run

```bash
cd justlend-energy
python3 poc/poc.py                      # writes poc/results/poc_results.json
bash ci/run.sh                          # CI: snapshot + PoC + invariant checks -> ci-out/
```

No API key, no `.env`, no secrets. Public `api.trongrid.io` only, with retries/backoff.
