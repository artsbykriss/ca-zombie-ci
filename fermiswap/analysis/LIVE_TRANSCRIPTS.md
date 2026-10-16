# Live-path transcripts and on-chain evidence

## A. On-chain proof that the permissionless swap path executes when an update lands (real txs)

Block **26202487** (2026-10-16 03:45 UTC):
- Provider update: `engine4.acee8aab(lane WETH/USDC, price = 243194999381)` from `0x14e870f0…` (real tx in block).
- Same block, public solver tx `0x03e511a2eca0182f5312753ee27b1b85bfc5368eced3fc4686167213936cafe8`
  (from solver contract `0x6f805b2b…`; no privileges): vault transfer **1.339012289233801726 WETH in →
  3,256.135292 USDC out** (effective $2,431.75/WETH; posted $2,431.95; market ~$2,427.70).

Block **26202488** (same minute):
- Public solver tx `0x9adc7aa2c2960c674d69baf44c32e4e37f7c8e23ef162f607729c4f5a7a28566`: solver contract
  `0x3884cf9171f53f3cb29bbca1594af8a0efd5567e` calls `FermiSwapper(0x5979458912).swap` (0x9908fc8b)
  → engine4 `swap` (balanceOf(vault) staticcalls visible) → vault pays **123.106949 USDT** and receives
  **0.050559455267006784 WETH**. Trace: `analysis/trace_0x9adc7aa2c296.json`.

Block **26202530**:
- Provider update: `acee8aab(lane WETH/USDC, price = 243671600507)` = $2,436.71600507 from `0x14e870f0…`.
- Fork run of `test_T12_unprivileged_live_probe` at that block (fresh EOA, no privileges):
  `unlocked at fork block: true` → swap **1 WETH → 2,436.503792 USDC** (effective $2,436.50 vs market
  $2,435.72, +0.03 % gross; engine spread vs posted = 0.87 bps).

## B. Transcript (session capture, local fork at ~block 26202530)

```
[PASS] test_T12_unprivileged_live_probe() (gas: 186004)
Logs:
  unlocked at fork block: true
  UNPRIVILEGED swap succeeded: in: 1000000000000000000
  UNPRIVILEGED swap succeeded: out USDC: 2436503792
  effective price 8dp: 2436503792
```

Note: when the fork block contains no update, the same test reverts `"SP"` (observed 3× in a row at
blocks ~26,202,58x and in CI at block 26,202,605 — see `ci-out/forge_test_vvv.log`). This is the
same-block freshness rule; the attacker cannot create the update (`NP`).

## C. Band ratchet transcript (fork, `BandProbe`)

```
base price: 243671600507 ($2436.72)
1.21x..1.45x: OK   (swap executed at each posted price)
1.49x: REVERT "PB" (0x…5042…)
walk +20% steps: 1.20x OK, 1.44x OK, 1.728x REVERT
walk +3% steps x12: reached 1.426x OK
+40% steps with vm.roll / vm.warp(+1h): 1.40x OK, 1.96x REVERT
=> practical bound ≈ +45% price inflation per epoch; steps inside the band pass.
```

## D. Donation sensitivity transcript (fork, `DonationProbe` at block 26,202,605)

```
baseline out (1 WETH): 2427507653
vault USDC bal: 2731601402287   vault WETH bal: 874926142761492545997
donate +1 USDC      -> out unchanged
donate +10k USDC    -> +788
donate +100k USDC   -> +8486
donate +1,000,000 USDC -> +58,359  (0.0024%)
donate +0.1/1/10/100 WETH -> -0 / -0.0007% / -0.002% / -0.008% (net, after USDC donations)
=> sensitivity ≈ 7e-8 per unit donated; donation is unrecoverable; gain/cost ≈ 1e-7.
```
