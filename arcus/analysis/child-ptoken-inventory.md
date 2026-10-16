# pToken inventory summary (short)

**Chain:** Robinhood Chain 4663 — **Factory:** `0x9c3663FA9ab976E67B42939486EC4966Cb41a0BB`
**Snapshot:** block 89,750,332 — **Asset:** USDG (6dp) — **Machine-readable:** `child-ptoken-inventory.json`

**17 pTokens, 16 non-empty, total NAV = $717,274.41 USDG** (dynamic; ~30k blocks earlier it was $717,518.73).

| sym | TA (USDG) | shares | fee bps | paused | note |
|---|---|---|---|---|---|
| pTEST | 293.05 | 200.90 | 0 | no | test token; virtual-share offset 1e9 (unique) |
| pBTC3x | 97,431.83 | 553.14 | 25 | no | |
| pHOOD3x | 211,760.20 | 2,041.79 | 25 | no | largest TA |
| pTESTR | 283.03 | 307.11 | 0 | no | test token |
| pBTC | 35,381.10 | 338.85 | 25 | no | |
| sBTC | 14,191.96 | 141.98 | 25 | no | |
| sBTC3x | 31,332.88 | 366.99 | 25 | no | |
| sHOOD3x | 104,186.17 | 261.98 | 0 | no | |
| pGLD5x | 37,541.10 | 514.57 | 0 | no | |
| sGLD5x | 33,683.82 | 252.18 | 0 | no | |
| pSPCX5x | 444.13 | 5.31 | 0 | no | near-empty |
| sSPCX5x | 613.25 | 5.91 | 0 | no | near-empty |
| pGME5x | 41,385.62 | 267.85 | 0 | no | |
| sGME5x | 17,025.01 | 668.99 | 0 | no | |
| **pTEST3** | **0** | **0** | 0 | no | **empty; deposits blocked for everyone (quota=0)** |
| pSPCX3x | 47,935.58 | 477.06 | 0 | no | |
| sSPCX3x | 43,785.71 | 513.41 | 0 | no | |

* `managerOf` = `0xB7410dc44e2715161E9914272e2D55D7c5061FAa` for all 17; `requestTtl` 604800 s.
* `totalAssets` is a **stored NAV** (not `balanceOf`): pTokens hold only dust USDG on-contract.
* Conversion formula (verified exactly):
  `shares = assets·(totalSupply + vs)·1000 / (totalAssets·1000 + 1)`, `vs` = 1e7 (pTEST 1e9).
* Deposits are **quota-gated per (token, account)** — pToken ns+0x12 = `{assetQuota, shareQuota}` (maxDeposit/maxMint
  return the remainders). `deposit()` mints **exactly the pre-granted `shareQuota`** (state-override verified), not
  a live `convertToShares` figure. Only `0x001232c6…` holds a quota today (100 USDG on pBTC3x). Factory allowlist
  (`isAllowed = map5 ∥ map6`) is a second gate. pTEST3 has zero quotas for everyone → deposits impossible.
* Price/share column varies 0.92→397.7 USDG per 1e18 shares — share units are not normalized; not comparable across tokens.
* Details, gating and upgrade history: `child-ptokens-admin.md`.
