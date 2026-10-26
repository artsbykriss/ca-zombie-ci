# Exit-rehearsal timing book (measured)

All times UTC, 2026-10-06. Chains: Ethereum L1, Noble, Archway, Osmosis.

## Inbound funding (ETH → USDC → CCTP → Noble → IBC)

| Step | Tx / event | Time | Measured | Detail |
|---|---|---|---|---|
| ETH→USDC swap (Uniswap V3 0.05%) | `0xde3dddf969…` | 17:51:35 | — | 0.008 ETH → **21.554 USDC**, gas 137,093 @0.47 gwei |
| Approve USDC → TokenMessenger | `0x871b4bdc95…` | 17:51:47 | 12 s | gas 55,570 |
| `depositForBurn` → Noble (domain 4) | `0x451d7a4e19…` | 17:52:47 | 60 s | 21.554 USDC burned, gas 98,958 |
| **Circle attestation** | msg `0x6f47e557…` | 18:11:46 | **19 min 0 s** | CCTP v1 standard |
| Noble mint (gasless relayer) | — | 18:12:00 | **~15 s** | auto, zero-fee relayer |
| Noble → Archway IBC (20 USDC) | `36E6C65564…` | 18:13:00 | **~30–60 s** | Noble ch-12 ↔ Archway ch-29 |
| Noble → Osmosis IBC (1 USDC) | `B1BC96BC02…` | 18:13:00 | **~30–60 s** | Noble ch-1 ↔ Osmosis ch-750 |
| Osmosis swap USDC→ARCH (pool 1375) | `99BA528C0F…` | 18:14:30 | ~5 s | 0.2 USDC → **551.697 ARCH**, gas in USDC |
| Osmosis → Archway IBC (ARCH) | `E98155F860…` | 18:15:20 | **~1 min** | Osmosis ch-1429 ↔ Archway |

**Inbound total: ~24 min wall-clock (dominated by the 19-min attestation).**

## EXIT rehearsal (Archway → Noble → CCTP → Ethereum)

| Leg | Tx / event | Time | Measured | Detail |
|---|---|---|---|---|
| **Leg 1**: Archway → Noble IBC | `B91B0D10EE…` | 18:16:49 | broadcast 4.7 s | 20 USDC, Archway ch-29, gas 0.03 ARCH |
| Leg 1 arrival on Noble | — | 18:17:01 | **~12 s** | 20,453,999 uusdc |
| **Leg 2**: Noble CCTP burn → Ethereum | `8A4997281E…` | 18:17:40 | broadcast 5.8 s | 20 USDC, domain 0, gas in uusdc |
| **Leg 3**: Circle attestation | — | 18:18:0x | **~3 s (!)** | **Noble instant finality — near-instant, NOT 13–20 min** |
| **Leg 4**: Ethereum `receiveMessage` | `0x88fe403596…` (mint) | 18:19:0x | **auto-relayed** | a relayer submitted it; USDC was already in the wallet |
| **Final**: USDC → ETH swap | `0x76dbc00cea…` + unwrap `0x8eaf3b124a…` | 18:24:27 | ~2 min | 20 USDC → 0.00871456 WETH → ETH |

## ⚡ Measured exit timing (the number that matters)

**Archway → Noble → CCTP → Ethereum → ETH: ~5–6 minutes total** (not the 20–25 min originally
estimated — the 13–20 min attestation applies only to **Ethereum-source** burns; **Noble-source
burns attest in seconds**).

| Exit leg | Measured |
|---|---|
| Archway → Noble IBC | broadcast 4.7 s, arrival ~12 s |
| Noble CCTP burn | broadcast 5.8 s |
| Attestation (Noble → Ethereum) | **~3 s** |
| Ethereum mint | auto-relayed (~1–2 min) |
| USDC → ETH swap | ~2 min |
| **Total** | **~5–6 min** |

## Final balances

| Where | Amount |
|---|---|
| Ethereum wallet | **0.02061091 ETH** (started 0.02044588) — float returned |
| Archway burner | 551.7 ARCH (gas reserve) + 0 ARCH spent beyond ~0.3 |
| Noble | 0.45 USDC (dust) |
| Osmosis | ~0.5 USDC (dust) |

**Net rehearsal cost ≈ $1.5–2** (gas + slippage). Everything else returned.

## Cost log

| Item | Amount |
|---|---|
| ETH spent (swap + all gas so far) | ~0.0082 ETH (~$22) |
| USDC float in flight | 20.00 |
| Residuals | Noble 0.45 USDC, Archway 551.4 ARCH (gas), Osmosis ~0.5 USDC |
| Estimated net rehearsal cost | **~$2–3** (gas + slippage; the float returns to ETH) |

## Key takeaways for the real run

- Attestation (~19 min) dominates — start the burn first, do everything else while it confirms.
- IBC hops are fast: **12–60 s**.
- The Noble gasless relayer mints within **~15 s** of attestation — no manual relay needed.
- The final USDC→ETH swap is the last ~1 min.
- The critical extraction window (~2–3 min) can run while the exit's attestation is in flight.
