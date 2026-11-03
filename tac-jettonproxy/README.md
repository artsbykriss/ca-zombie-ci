# TAC JettonProxy — forged `transfer_notification` relay (TON → TAC)

**Date:** 2026-11-03
**Chains:** TON mainnet + TAC (EVM chain id 239)
**Status:** read-only; no mainnet transaction broadcast; no keys used.

## TL;DR

| Question | Answer |
|---|---|
| Is the TON-side relay unauthenticated? | **Yes.** The live JettonProxy code hash is `A808C9F0…94EDB`; the `0x7362d09c` (`transfer_notification`) branch reads the amount/sender/payload from the body and relays `0x6c582059` to the CCL with **no `SDEQ` sender check** anywhere in the branch. |
| Does that relay move the proxy's jettons? | **No.** The proxy's only jetton outflows are `0x0f8a7ea5` sends emitted from two branches, both guarded by `GETGLOB 1; SDEQ; THROWIFNOT 70` (sender must be the CCL). The CCL's release batch is itself signed by an operator key (`CHKSIGNU` against the 256-bit pubkey in the CCL data). |
| Is the EVM mint gated by a sequencer quorum? | **Yes, but the "quorum" is 1-of-1.** `Consensus.totalVoters() == 1`, one group (`TacGroup`), and the single voter is EOA `0x8f1B53B1…f9df` (nonce 44,571, no code). A `vote()` from that EOA sets `_roots[root] = now + validity`; `receiveMessage` mints only after `checkMerkleRoot(root)` is true and the message is in the tree. |
| Is the $553k USDT reachable by a TON-only path? | **No.** The proxy's USDT wallet (`0:ab2d…e372`) is owned by the proxy; the proxy releases only on a CCL message, and the CCL only emits the release op from a signed batch. |
| Is it externally extractable today? | **No — $0 E-U.** The only unverified leg is the off-chain sequencer's jetton-wallet validation (the May-2026 fix), which is not on-chain. A **1-of-1 sequencer EOA** is the on-chain gate, not a real quorum. |
| Residual latent risk | If the sequencer's post-fix filter is only "wallet code hash + minter data" (not the canonical derived address), a non-canonical contract carrying the canonical wallet code and the real minter but a different owner/balance could in principle be accepted. The post-mortem wording says "proven to be the canonical jetton wallet"; the exact deployed check is not public. |

**Headline: $0 extractable by an external unprivileged attacker (confidence: high on the TON-only and on-chain EVM gates; medium on the off-chain filter).**
**Conditional / privileged:** ~**$624,190** liquid in the proxy (USDT + BLUM + tsTON) if the off-chain filter is bypassable or the single voter key is compromised; **P** value ~$624k. **E-U-conditional** ~$624k (not currently reachable). Nominal (thin/illiquid) 67 token ≈ $718k, excluded.

## 1. The mechanism in exact terms

### 1.1 TON proxy (deposit side)

Proxy: `EQAChAswsPNsU2k3A5ZDO_cfhWknCGS6WMG2Jz15USMwxMdw`
= `0:02840b30b0f36c5369370396433bf71f8569270864ba58c1b6273d79512330c4`
Code cell hash: `A808C9F031379C60BF9604376EC5C52609B08536B1F3A366EFAC86BE25594EDB` (949-byte code cell; unchanged from the May-2026 exploit).

The `0x7362d09c` branch (disassembly `analysis/proxy.fift`, lines 63–337) parses the notification body and builds a `0x6c582059` message to `GETGLOB 1` (the CCL), with no sender comparison. This is the original defect.

### 1.2 What the relay actually does

A real deposit trace (`analysis/release_trace.json`, trace `VffcqikRw1By9gqeKH4sjmGj5Sm8l+jumD953jBDtjc=`) is:

```
user wallet → jetton wallet → proxy jetton wallet (0x178d4519)
  → JettonProxy 0x7362d09c
  → CCL 0x20a5698e 0x6c582059
  → CCL replies (excess 0xd53276db only)
```

The relayed message is a *deposit notification*, not a transfer. It does not move the proxy's own jettons.

### 1.3 Release side (TON)

The proxy's only jetton outflows are `0x0f8a7ea5` messages built in two branches:

- `0xae7df95b` (lines 340–437): `GETGLOB 1; SDEQ; THROWIFNOT 70` before building the transfer.
- `0x7817b330` (lines 438–530): same `GETGLOB 1; SDEQ; THROWIFNOT 70` gate.

`GETGLOB 1` is the CCL `0:20a5698e…ee2f`. A live release trace (`analysis/release_trace.json`, trace at lt 114177802000014) is:

```
0:20a5698e (CCL) → JettonProxy 0x7817b330
  → proxy's jetton wallet 0x90d4cc16… 0x0f8a7ea5
  → recipient jetton wallet 0x178d4519
```

Across the last 200 proxy transactions: **96** inbound `0x7362d09c`, **82** inbound `0x7817b330` (all from the CCL), **64** outbound `0x6c582059`, **82** outbound `0x0f8a7ea5` (`analysis/tx_op_counts.json`). No release came from any other sender.

### 1.4 The CCL TON gate

CCL TON: `EQAgpWmO8nBUrmfOOldIEmRkLEwV-IIfVAlJsphYswnuL80R`
= `0:20a5698ef27054ae67ce3a57481264642c4c15f8821f540949b29858b309ee2f`
Code cell hash: `B83804BBE2408DF8136DA74DD40BFCC5F5A85814D753A9814563108E4134E988` (6,430 bytes).

- The signed external entry is op `0x4b19e42a`; the code does `GETGLOB 4; CHKSIGNU; THROWIFNOT 32` (disassembly `analysis/ccl.fift`, lines 21–91). `GETGLOB 4` is the 256-bit public key `0xb76b6f562313156bb3b5c269da1f56baf03014a422ab033485416817081c3cd8` decoded from the CCL data cell.
- The release-batch handler `0x497dae1d` checks a 256-bit key against a dictionary in `GETGLOB 6` (`DICTUGET; NULLSWAPIFNOT; THROWIFNOT 201`) and a hash/address check (`SDEQ; THROWIFNOT 71`) before sending the embedded `0x7817b330` message (lines 881–2100; the `0x7817b330` bytes are embedded in the inbound body at hex offset 1274 of the live trace's 0x497dae1d message).
- The 0x6c582059 deposit handler is **not** signature-gated; that is the deposit queue feed. The release side is signature/dict-gated.

So a TON-only attacker can inject a deposit notification (the original defect) but cannot make the CCL release the proxy's jettons.

## 2. EVM mint gate (TAC)

- EVM CCL proxy: `0x9fee01e948353E0897968A3ea955815aaA49f58d` (ERC-1967) → impl `0x01BC6bbf156436F09E07ab0392332f6d2636026d` (`CrossChainLayer`, verified, solc 0.8.28).
- Consensus proxy: `0xae635de674cfe4afd179cde441abbe6504a20a98` → impl `0xA216fB1456901d04F2D51fE04bCBb8878f5B41D9`.

`receiveMessage` (`analysis/crosschainlayer_impl.sol`, lines 633–676) calls `_checkInMessage` (lines 261–304):

1. `messageHash = keccak256(bytes.concat(keccak256(encodedMessage)))`
2. revert if `_processedInMessages[messageHash]`
3. `_checkMerkleRoot(MerkleProof.processProofCalldata(proof, messageHash))`; `_checkMerkleRoot` calls `_consensus.checkMerkleRoot(root)` (line 255).
4. `message.evmValidExecutors` must contain `msg.sender` — **this field is attacker-supplied and is not a real gate**; the Merkle root is the binding control.
5. `_processInMessageTokens` mints `message.mint[]` to `message.target` and unlocks `message.unlock[]`.

`Consensus.checkMerkleRoot(root)` = `_roots[root] > block.timestamp` (line 423–424). `_roots` is written only in `vote()` (lines 348–373), which is `onlyVoter` and requires the in-group + group thresholds. Live state at block **28,090,507** (timestamp 1,793,715,249):

| Read | Value |
|---|---|
| `totalVoters()` | `1` |
| `totalGroups()` | `1` (group id `TacGroup`) |
| `inGroupVotersNum(TacGroup)` | `1` |
| voter | `0x8f1B53B1Bf9b24BAa2054Bd2d8C0b7923ABff9df` — **EOA**, code `0x`, nonce 44,571 |
| `voterToGroupId(voter)` | `TacGroup` |
| `hasRole(ADMIN, voter)` | `false` (voting is via `voterToGroupId`, not ADMIN) |
| current root (`getCurrentEpochInfo`) | `0x75708b8f99b1e360101691d53e9d103bc91fa14f100a694f464fa41246d5d24f` |
| `_roots(currentRoot)` | `1,793,715,832` (valid at measurement) |
| `checkMerkleRoot(currentRoot)` | `true` |
| `_simulationMode` (CCL storage slot 5) | `0` (`None`) |
| forged `receiveMessage(1,0x1234,[],0,0x)` from `0x1111…` | revert `0xb05e92fa` = `InvalidMerkleProof()` |

A valid root exists, so the bridge is live; but the root is produced by **one EOA**. A vote tx from that EOA (`analysis/last_vote_tx.json`, tx `0x3117e264…acda`) set an earlier root in one call — there is no multi-party quorum on-chain.

### 2.1 Why the forged deposit does not mint

The forged TON notification only enters the CCL's deposit queue. The EVM mint requires a Merkle root that commits to the exact `encodedMessage`; the root is produced by the single voter from the sequencer's off-chain batch. The May-2026 exploit required the sequencer to accept the fake jetton wallet as a valid deposit (the post-mortem: "the software did not verify the minter code of the sender jetton wallet"). The fix is **sequencer-side**, not in the TON contracts — so the unchanged `JettonProxy` code is expected, not proof of a live hole.

## 3. Live value

Address / block: proxy `0:02840b30…30c4`, code hash `A808C9F0…94EDB`, last tx lt 114240958000060, active.
USDT wallet `0:ab2d4b7c1c11305197fff4ccbfdd855f737c1cd5d58f1f4cf28b0f37d957e372`; `get_wallet_data` returns balance `553,035,299,947` raw (553,035.155657 USDT), owner = the proxy, jetton master = `EQCxE6mU…` (USDT).

| Jetton | Amount | Price (tonapi, 2026-11-03) | USD |
|---|---:|---:|---:|
| USD₮ | 553,035.155657 | $0.9986917 | **$552,311.63** |
| BLUM | 74,263,651.686793 | $0.000916913 | **$68,093.30** |
| tsTON | 2,780.212482 | $1.3614213 | **$3,785.04** |
| 67 (whitelist, thin) | 77,387,304.975 | $0.00927454 | $717,731.65 (nominal) |
| 67 (second wallet) | 5,509.255 | $0.00927454 | $51.10 (nominal) |
| fake/blacklisted tokens | — | — | excluded |

**Liquid (USDT + BLUM + tsTON): $624,189.97.** Nominal including 67: $1,341,972.72. The 67 token is excluded from extractable value because its exit liquidity is unverified.

## 4. What an attacker can and cannot do

Can:
- Send a forged `0x7362d09c` to the proxy from any contract; the proxy relays a `0x6c582059` deposit message to the CCL. This is the real defect and is reproducible by TVM disassembly.
- Trigger the proxy's refund branch (`0x0f8a7ea5`) with a forged notification. The refund is sent to the *source* of the notification (a real jetton wallet) for the body-stated amount; a forged source cannot be the proxy's jetton wallet (TON sets the source), so it does not move proxy funds.
- Call `receiveMessage` with a valid proof for a legitimate message; this can claim the `feeReceiver` fee for a message another executor was going to process (self-asserted `evmValidExecutors`). This is small MEV, not a drain.

Cannot:
- Make the proxy release jettons: both release branches require `msg.sender == CCL` (`THROWIFNOT 70`).
- Make the CCL release without a signed batch: the external entry is `CHKSIGNU`-gated by the operator pubkey `0xb76b6f56…`, and the release handler requires the message key in the signed dictionary.
- Make the EVM CCL mint without a root accepted by `Consensus`: the forged call reverts `InvalidMerkleProof`; the root is 1-of-1 and only the voter EOA can write it.

## 5. Residual risk and blockers

1. **Off-chain sequencer filter (only unverified control).** The deployed sequencer binary is not public. The post-mortem says the fix verifies the sender wallet's code hash and that its data points to the expected minter. If the check does not also enforce the canonical derived address, a non-canonical contract with the canonical wallet code + the real minter but a different owner/balance could in principle pass. The wording "proven to be the canonical jetton wallet" suggests the address is checked; 6 months of undrained balance is consistent with the fix working. This is a latent, not a demonstrated, path.
2. **1-of-1 voter.** The on-chain "quorum" is a single EOA. A compromise of `0x8f1B53B1…f9df` (or its operator) would let an attacker sign an arbitrary root and mint. That is a key-compromise scenario (P), not external unprivileged (E-U).
3. **Bridge liveness.** At measurement the current root was valid, but roots rotate and the voter can stop; the forged path needs the operator to include the fake deposit in a root. No such inclusion was observed.

**Verdict:** the TON-side relay defect is real and unpatched, but it is **inert for the $553k** because the release is CCL-gated and the CCL release is operator-signed, while the EVM mint is gated by a root only the 1-of-1 voter can produce. **$0 E-U today.** The honest residual is the off-chain filter and the single key.

## 6. CI

GitHub Actions run (public repo `artsbykriss/ca-zombie-ci`):

- https://github.com/artsbykriss/ca-zombie-ci/actions/runs/41653084535 — `ci/run.sh`: live TAC EVM + TON checks, all 9 assertions PASS (`ci-out/assert.txt`).

## 7. Methodology / sources

- TON: `toncenter.com/api/v3` (`addressInformation`, `transactions`, `runGetMethod`), `tonapi.io/v2` (account jettons, trace), live code cells disassembled with `tonpy`/Fift (`analysis/proxy.fift`, `analysis/ccl.fift`).
- EVM: `https://rpc-public.tac.build` (`eth_call`, `eth_getStorageAt`, `eth_getLogs`), Blockscout `explorer.tac.build/api/v2` verified sources (`analysis/*.sol`).
- Post-mortem: `https://tac.build/blog/post-mortem-report-tac-bridge` (2026-05-20), quoted for the sequencer-side fix and the paused status.
- All calls read-only at block 28,090,507 / TON lt 114240958000060. No transaction was signed or sent.

### Files

| File | Content |
|---|---|
| `analysis/proxy.fift` | Live JettonProxy disassembly (642 lines) |
| `analysis/ccl.fift` | Live CCL TON disassembly (4,895 lines) |
| `analysis/proxy_state.json` | Proxy code hash, balances, jetton wallets |
| `analysis/valuation.json` | Jetton amounts/prices/USD |
| `analysis/tx_op_counts.json` | 200-tx inbound/outbound op counts |
| `analysis/release_trace.json` | tonapi trace of a live CCL→proxy release |
| `analysis/live_checks.json` | TAC EVM consensus/CCL state + forged-call revert |
| `analysis/last_vote_tx.json` | The single voter's `vote()` transaction |
| `analysis/crosschainlayer_impl.sol`, `consensus.sol` | Verified EVM sources |
| `analysis/live_checks.py` | Reproducible read-only check script |
