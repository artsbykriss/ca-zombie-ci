# Exit dry-run plan — USDC: Archway → Noble → CCTP → Ethereum

**Goal:** rehearse the full exit route with a small real amount (~$10–20 USDC) BEFORE the campaign,
so every leg, address, fee, and timing is proven. Same discipline as the Polygon and Algorand runs.

**Status:** ✅ **REHEARSAL COMPLETE (2026-10-06 18:24Z).** Full round trip executed with real funds:
ETH→USDC→CCTP→Noble (19 min attestation)→IBC→Archway(+ARCH gas via Osmosis), then the **exit**:
Archway→Noble (12 s)→CCTP burn (5.8 s)→attestation (**~3 s**)→auto-relayed Ethereum mint→
USDC→ETH swap. **Exit total ~5–6 min; net cost ~$1.5–2; float returned to ETH.**
Full timings: `exec/timing.md`. Burner holds 551.7 ARCH gas reserve.
**Key finding: Noble-source attestations are near-instant — the exit's long pole is gone.**

## Accounts

| Role | Address | Key |
|---|---|---|
| Archway burner (generated) | `archway1khgqgnnpw984e70chqjc5yu5r3ed8255qy6mhw` | `exec/.archway_key.json` (chmod 600, git-ignored) |
| Noble address | same key, prefix `noble` (derived at runtime) | — |
| Ethereum destination | `0x2B2357b4BD1c7600545117B68a3FafFb8C169137` | `.env` EVM key |

## Route (each leg verified live)

```
[1] Archway burner holds USDC (ibc/43897… = Noble-native uusdc via channel-29) + a little ARCH
        │  MsgTransfer  channel-29 → Noble channel-12   (~15–30 s)
[2] Noble holds uusdc
        │  circle.cctp.v1 MsgDepositForBurn:
        │    destination_domain = 0 (Ethereum)
        │    burn_token = uusdc
        │    mint_recipient = 0x000…2B2357b4BD1c7600545117B68a3FafFb8C169137 (32-byte padded)
        │    (module live, not paused; token pair domain 0 ↔ uusdc confirmed)
        │  Noble gas payable in USDC (min gas price 0.1 uusdc/gas)
[3] Circle attestation (~13–20 min, standard CCTP v1)
        │  poll https://iris-api.circle.com/attestations/{messageHash}
[4] Ethereum mint
        │  MessageTransmitter 0x0a992d191DEeC32aFe36203Ad87D7d289a738F81
        │    .receiveMessage(message, attestation)   (~100–200k gas)
[5] USDC lands at the destination address on Ethereum
```

Verified addresses: MessageTransmitter `0x0a992d191DEeC32aFe36203Ad87D7d289a738F81`,
TokenMessenger `0xBd3fa81B58Ba92a82136038B25aDec7066af3155`, USDC `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48`.

## Timing budget (to be measured precisely in the dry run)

| Leg | Expected | Notes |
|---|---|---|
| Archway block | 5.64 s | measured |
| IBC Archway→Noble | ~15–30 s | both channels STATE_OPEN |
| Noble burn tx | 1 block | Noble ~6 s blocks |
| Circle attestation | **13–20 min** | dominates; standard CCTP v1 |
| Ethereum receiveMessage | ~15–60 s | gas ~$0.1–0.5 at current L1 |
| **TOTAL** | **~20–25 min** | critical window for pool extraction is separate (~2–3 min) |

## Fees (estimated)

| Leg | Cost |
|---|---|
| Archway IBC tx | ~0.001 ARCH (dust) |
| Noble depositForBurn | ~0.02 USDC (USDC gas denom) |
| Ethereum receiveMessage | ~$0.1–0.5 |
| **Total** | **< $1** |

## What we need from you to start the rehearsal

**Burner (Archway): `archway1khgqgnnpw984e70chqjc5yu5r3ed8255qy6mhw`**
(verified: address re-derived from `exec/.archway_key.json`; currently 0 balance)

| Asset | Amount | Purpose |
|---|---|---|
| **ARCH** | **2 ARCH** (~$0.001) | gas on Archway. Min gas price 140000000000 aarch/gas → ~0.03 ARCH per tx; 2 ARCH covers the whole rehearsal + campaign ops with margin |
| **USDC (Noble-native)** | **10–20 USDC** | the asset moved through the exit route. Denom on Archway: `ibc/43897B9739BD63E3A08A88191999C632E052724AB96BD4C74AE31375C991F48D` (= `transfer/channel-29/uusdc`, verified hash) |

**Funding routes (pick based on where your funds sit):**
- **A. USDC on Ethereum** → send to `0x2B2357b4BD1c7600545117B68a3FafFb8C169137`, then I run the
  inbound mirror: CCTP deposit (Ethereum → Noble domain 4) → IBC Noble → Archway burner.
- **B. USDC on Noble** → I run the IBC Noble → Archway transfer (leg 1 mirrored).
- **C. Exchange withdrawal** → withdraw USDC **on Noble** (preferred) or Archway; ARCH on Archway
  (or IBC from Osmosis).
- **D. USDC on Osmosis** → route Osmosis → Noble → Archway (needed to get the Noble-native denom).

## Scripts (built, syntax- and codec-validated)

| Script | Purpose | Status |
|---|---|---|
| `exec/balance.js` | balances on Archway + Noble + Ethereum | ready |
| `exec/ibc_archway_noble.js` | leg 1 (CosmJS MsgTransfer, channel-29) | ready |
| `exec/cctp_burn_noble.js` | leg 2 (custom `circle.cctp.v1.MsgDepositForBurn` codec, no extra deps) | ready (codec verified against a real on-chain message) |
| `exec/cctp_mint_eth.js` | legs 3–4 (extract message from Noble tx → Iris attestation → `receiveMessage`) | ready |
| `exec/timing.md` | filled with measured times after the run | to be filled |

Verified env facts: Archway min gas price `140000000000aarch`; Noble min gas price includes
`0.1uusdc`; Noble CCTP type `/circle.cctp.v1.MsgDepositForBurn` and event
`circle.cctp.v1.MessageSent{message=base64}` confirmed from a live tx.
