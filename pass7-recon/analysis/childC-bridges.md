# ZH4-PASS7 · child-C — bridge/framework watchlist + oracle-lane residual · live sanity check

**Date:** 2026-10-25 (UTC) · **Mode:** READ-ONLY — `eth_call`/`eth_getCode`/`eth_getStorageAt` + public RPCs + explorer/DefiLlama/GitHub reads only. **No tx signed or sent. No keys/secrets/keyed-RPC-URLs written.**
**Scope:** pass7 bridge/framework "watchlist" (child-A) + Payy/Barretenberg class + the oracle-lane "Unresolved LOW" tail. Purpose = **quick live sanity check + prior-coverage determination** (does it still exist, is there live custody, is it OPEN / LANE-CLOSED / PRIOR-COVERED / NOT-A-PROTOCOL).

---

## 0. Verdict table (top)

| # | Target | EXISTS? | Live custody (block) | Verdict | Prior coverage |
|---|---|---|---|---|---|
| 1 | Hyperlane `TrustedRelayerIsm` in a **threshold-1** `staticAggregationIsm` (USDC/base, USDC/op, USDC/arb, VRA/eth, ctUSD/eth) | **yes** | **dust** — USDC/base router 28.35 USDC · USDC/op synthetic 28.35 · USDC/arb router 71 USDC · VRA/eth 25.00 M VRA ≈ **$219** · ctUSD/eth **$0** | **PRIOR-COVERED** — **H-O/P, NOT E-U** (needs the relayer EOA key). No material custody on the named routes. | pass7 child-A `_child_lz_hyperlane.md` §1#1/§2.1; `bridges.md` §1#7/§2.3 |
| 2 | EIP-7702-delegated trusted relayer `0x690f4e2f…` (delegate MetaMask `EIP7702StatelessDeleGator` v1.3.0) | **yes** | n/a (relayer; route it serves = ctUSD/eth, **$0**) | **LANE-CLOSED** — **no permissionless `execute`**: `execute(...)` reverts `NotEntryPointOrSelf`; only EntryPoint / self / signed EIP-712 delegation. | child-A §1#3/§2.3 |
| 3 | Payy `RollupV1` + Barretenberg/UltraHonk class | **yes** | RollupV1 **710.75 USDC** (unchanged); HonkVerifier 0 | **PRIOR-COVERED / LANE-CLOSED** — E-U $0; **no on-chain pause** (pass7 "paused" is wrong) but drain is `onlyProver`-gated. No other funded **< v5.0.0** verifier on ETH/Base/Arb. | `bridges.md` §1#2/§2.2 |
| 4a | **Flying Tulip Lend** (oracle unlocated in pass7) | **yes** | DL **≈$9.17 M** (ETH $7.591 M + Sonic $1.545 M + BNB $0.036 M); borrowed $6.009 M | **OPEN** — assigned `p7-oracle-residual`. Oracle **located** = `OracleRouterChainlink` (Chainlink `latestRoundData`). | lane-level (oracle.md tail); assigned ZH4P7 tracker |
| 4b | **Parallel V3** (Diamond) | **yes** | DL **≈$0.909 M** (ETH $254.6 k + Base $162.5 k + Hyperliquid $380.7 k + Avax $111.0 k) | **OPEN** — assigned `p7-oracle-residual`. EIP-2535 Diamond located. | lane-level; assigned ZH4P7 tracker |
| 4c | **Sturdy V2** | **yes** | DL **≈$0.230 M** (Mode $199.7 k + ETH $19.9 k + Linea $4.3 k + Flow $1.2 k + OP $4.6 k); **Sei leg = $0** | **OPEN / PRIOR-PARTIAL** — assigned `p7-oracle-residual`. pass4 closed only the **Sei** leg; ETH/Mode/Linea/Flow/OP legs unexamined. Oracle contracts located. | pass4 `gap-chains.md` #11 (Sei only) |
| 5 | USDT0 OFT adapter (assigned elsewhere) | **yes** | proxy `0x6C96dE32…` → impl `0xcd979b10…` holds **3,196,899,512.94 USDT ≈ $3.197 B** | **LANE-CLOSED** (assigned `usdt0-oft/`) — dormant 1-of-1 EIDs **30165/30214/30375/30243 still `peer == 0`** (no new live 1-of-1 route). | `bridges.md` §2.0; README §3 P7-04 |

**Bottom line:** nothing on the pass7 bridge watchlist became E-U. Item 1 stays a **key-compromise (H-O/P) centralization risk** and its named routes are **dust today** (largest = VRA/eth ≈ $219). Item 2 has **no open entry**. Item 3 is **$0 E-U** and no sibling verifier was locatable on ETH/Base/Arb. The only genuinely still-open bridge-adjacent surface is the **oracle-lane tail (4a–4c)**, which is already **assigned** to `p7-oracle-residual` — I located the oracle/source for each (see §4).

---

## 1. Item 1 — Hyperlane `TrustedRelayerIsm` inside a threshold-1 aggregation

**Mechanism re-confirmed live** (read-only `eth_call`): each route's `interchainSecurityModule()` is a `staticAggregationIsm` (`moduleType 2`) with `modulesAndThreshold(...) = ([...], 1)`, and one of the two modules is a `TrustedRelayerIsm` (`moduleType 6`) whose `trustedRelayer()` is a **single EOA**. Because the aggregation **threshold is 1**, *either* module alone suffices ⇒ that one EOA can mint/release on the route. `Mailbox.process` sets `processor = msg.sender` before `verify`, so **only the relayer key passes** → **not unprivileged**.

| Route | Chain (block) | Router | ISM (type / threshold) | TrustedRelayerIsm module | `trustedRelayer` (single EOA) | Live custody |
|---|---|---|---|---|---|---|
| USDC/base | base 53,083,494 | `0x524410b1e64f689eeBa15E7E511110438811B3dC` | `0x373788b7fC11D74fcfd5637aea1246C442516362` (2 / 1) | `0x2c77045eC271934F92219968FEC12Ae188707D27` | `0x6aA5468dd26181A0CBF50808D12f0AFED775402c` | **28.353873 USDC** (`balanceOf`) |
| USDC/optimism | op 158,678,780 | `0x2DBe8c163f080b244D420be781abD37c1bfc51A6` | `0x2C66b4Ab397c1bBC93ecD401f4dB7580f7086197` (2 / 1) | `0x251F1D2EF903704c7A957c9F0D15363Fc43ae02F` | `0x6aA5468dd26181A0CBF50808D12f0AFED775402c` | synthetic `totalSupply` **28.353873 USDC** |
| USDC/arbitrum (cheesechain route) | arb 518,227,549 | `0xC9e048011E4A47584CE5b91AbD8695338A640648` | `0x443e5802f11EbC75b2f233A6142998748Cd7D02d` (2 / 1) | `0xE010B1fff922ADf36fFf6b44970684A85d54d2F3` | `0xE8DACd5D916195DcAC441FeD31E6eCD2F4b5C378` | **71 USDC** (`balanceOf`) |
| VRA/ethereum | eth 26,271,769 | `0xde1bb600f24e9c6E49d51765fB836b070762e45D` | `0x331F7E25C43Be7705535E9784360Ac900870938E` (2 / 1) | `0x848477d027124781488945Abecf738e3ae39075d` | `0x712F7FD748A3B1162aB331556E6B97f17A97ecDb` | **25,003,623.29 VRA ≈ $219** |
| ctUSD/ethereum | eth 26,271,769 | `0x6372e1C8a08940C7e95AF2891B9201aC48De6519` | `0x02F02A24dd6135d7d4aD15f42B16D7F5f3a16421` (2 / 1) | `0xc216Ab6522A7b3303a07ACbE3DF52e8B3B20fa43` | `0x690f4e2f19717A06E1C146B2dCE68c2d23e36f4c` (**EIP-7702**, see §2) | **0 USDC** |

- VRA price read from DefiLlama `coins.llama.fi` (`ethereum:0xF411903c…` = `$0.000008781`); 25.0036 M VRA = **$219.6**.
- **Material custody? No.** Across all five named routes the largest is **VRA/ethereum ≈ $219**; the USDC routes are $0–$71; ctUSD/eth is $0. This matches child-A's "dust on the sampled routers" (USDT/eth 4,195 units, WBTC/eth 900 sat). The pass7 line "larger routes are the $M-class synthetic minters" refers to the **synthetic side**; the named watchlist routers themselves carry dust today.
- **Verdict: H-O/P — needs the relayer EOA key (or a key-leak), NOT E-U. PRIOR-COVERED** by child-A and `bridges.md`. Only re-arm trigger = the relayer key being compromised / rotated to an attacker (no on-chain forge exists; `Mailbox.process` from `0x…dEaD` reverts, child-A §3).

## 2. Item 2 — EIP-7702-delegated trusted relayer `0x690f4e2f…`

- `eth_getCode(0x690f4e2f19717A06E1C146B2dCE68c2d23e36f4c)` = `0xef0100 ‖ 0x63c0c19a282a1b52b07dd5a65b58948a07dae32b` ⇒ **EIP-7702 delegation** (23-byte code) to the MetaMask delegate.
- `VERSION()` on the EOA returns **`"1.3.0"`** ⇒ `EIP7702StatelessDeleGator` v1.3.0 (matches `MetaMask/delegation-framework` v1.3.0 source). Delegate code size 11,185 B.
- **Permissionless `execute` probe (from `0x…dEaD`):**
  - `execute((address,uint256,bytes))` → **revert `NotEntryPointOrSelf`** (`0x0796d945`).
  - `execute(bytes32,bytes)` → **revert `NotEntryPointOrSelf`**.
  - Source confirms: `EIP7702DeleGatorCore.execute(...)` and `redeemDelegations(...)` are both `onlyEntryPointOrSelf`; `_isValidSignature` requires `ECDSA.recover(hash,sig) == address(this)` (the EOA).
- `delegationManager()` = `0xdb9B1e94B5b69Df7e401DDbedE43491141047dB3`; `entryPoint()` = `0x0000000071727De22E5E9d8BAf0edAc6f37da032` (canonical ERC-4337 v0.7).
- **Verdict: LANE-CLOSED** — the "make the relayer EOA call `Mailbox.process`" idea requires the **EOA key** or a **valid EIP-712 delegation**; no unprivileged `execute`/`redeemDelegations` path exists. (Novel surface, but closed.)

## 3. Item 3 — Payy / Barretenberg–UltraHonk class

- **Payy `RollupV1`** `0x367C1eAF14AA06b78ce76bd0243297de79d85270` = ERC-1967 proxy (806 B) → impl `0x7d8837b547f4fea0053571cb149e845fc58e9b2d` (**verified source: `RollupV1`**).
  - **USDC balance = 710.752696 USDC** (`balanceOf`, eth 26,271,769) — **unchanged** from pass7's $710.75.
  - **No `paused()` / `frozen()` / `halted()` / `isPaused()`** on the impl (all revert) ⇒ **the pass7 "network paused" is not an on-chain pause.** The value-moving path `verifyRollup(...)` is guarded by `onlyProver` (`require(provers[msg.sender]==1)`), and the verifier is only usable once `addZkVerifier` (`onlyOwner`) enabled it. So the residual is **P (a registered/compromised prover)**, not E-U, regardless of pause.
  - `HonkVerifier` `0x14DACD534ddc676601B27f41Eb541a7951524a2F` still deployed (23,661 B), balance 0.
  - **Verdict: E-U $0 · PRIOR-COVERED / LANE-CLOSED** (`bridges.md` §2.2).
- **Other live on-chain UltraHonk/Barretenberg (< v5.0.0) verifier with real value (ETH/Base/Arb)?** **None locatable.** pass7's name search stands. A web pass surfaced **one new live set** outside ETH/Base/Arb:
  - **StealthPay** (0G mainnet **chain 16661**, block 48,268,928): `ShieldVerifier` `0x3F2Fd4E070a333446FF0D8886F513a0419A0BAF5` (24,244 B) and `SpendVerifier` `0x190314E281C7f92bBe0945a4a059Fa74883F0B9C` (24,245 B) — **both live**, behind `PrivacyPool` proxy `0x154d75521D449974d18c85600149b885DA5bBA85`. Its own review states the verifiers are **auto-generated by Barretenberg 5.x** (i.e. **post-v5.0.0 fix**) and **immutable/stateless** ⇒ **NOT the Payy class**; flagged as a **class-watch data point, not a finding**.
  - Note: the two Aztec GHSAs of 2026-10-08 (`GHSA-2hc8-mq24-76v2`, `GHSA-73xc-j27q-wg75`) affect the **native** UltraHonk verifier only; **generated Solidity verifiers are explicitly not affected**.
- **Verdict: LANE-CLOSED / PRIOR-COVERED** — no funded < v5.0.0 Solidity verifier on the target chains.

## 4. Item 4 — Oracle-lane "Unresolved LOW" tail (all **OPEN**, assigned `p7-oracle-residual`)

DefiLlama `currentChainTvls` (protocols fetched 2026-10-25). Oracle/source located read-only:

- **4a · Flying Tulip Lend — EXISTS, ≈$9.17 M.** ETH $7,591,689 + Sonic $1,545,212 + BNB $35,778; borrowed $6,008,726 (ETH $3,840,591 / Sonic $2,158,470). **Oracle located:** `OracleRouterChainlink` (impl `0xefd7d5471839e8cf1ee4cd6078de720262b705e9`) behind an ERC-1967 proxy; reads Chainlink `latestRoundData` (3 call sites). Supporting: `ConfigRegistry`, `LendingLens`; two lending proxies `0xa8777c3d446fa7f0b0fc97a80c1ea1d37f1ca33e` (impl `0x897bded2d9ac7478208958d14b2133d6d7506b17`) and `0xbe4050a73a7fb384c65e885a15c33461a4b20055` (impl `0x89b6f9179671c0b471734b897e31f8760a94dc53`). **Verdict: OPEN** — Chainlink-router oracle ⇒ check heartbeat/staleness + the hybrid PCA/PUT soft-liquidation path (not scoped in pass6 `d2d:94`).
- **4b · Parallel Protocol V3 — EXISTS, ≈$0.909 M.** ETH $254,576 + Base $162,547 + Hyperliquid $380,698 + Avax $110,979. **Source located:** EIP-2535 **Diamond** (`DiamondProxy`, facet impl `0xf659fac08300d204f84af28f66ea3d630acaa72c`); facets incl. `0x58426574855da7a8c47e1d134d51fd17dca5129b` (4,591 B) and `0x4731f7c0a3b670f78ccb2e3620ae636465ca5279` (2,448 B). **Verdict: OPEN** — oracle facet still to be pinned (assigned).
- **4c · Sturdy V2 — EXISTS, ≈$0.230 M; PRIOR-PARTIAL.** Mode $199,733 + ETH $19,896 + Linea $4,324 + Flow $1,211 + OP $4,564; **Sei leg = $0** (this is the only leg pass4 closed, `gap-chains.md` #11). **Source/oracles located:** DataProvider = **`AggregatorDataProvider`** `0x69764E3e0671747A7768A1C1AfB7C0C39868CC9e` with **23 live strategies** (assets crvUSD/WETH/GHO/USDC/WBTC/sUSDe…); per-pair oracle contracts e.g. `0x1121ddd2007d2c6677e9987e289c3d52aaa9668c`, `0x3bd929574ff5dea4a23d3bb3b1ad0b95d0fe1e1d`, `0xdb6ce32d36a9d807bab0c3947b31b06706758492` — **custom adapters (1.2–2.4 kB, no Chainlink `latestAnswer`/`latestRoundData` interface)**, so the pass7 "spot/oracle" question is live. **Verdict: OPEN / PRIOR-PARTIAL** (pass4 closed Sei only; ETH/Mode/Linea/Flow/OP unexamined).

> All three are already **assigned to `p7-oracle-residual`** (`ci/ZH4P7-RESULTS-TRACKER.md` line 54). My contribution = independent **existence + live-custody + oracle/source location** confirmation.

## 5. Item 5 — USDT0 OFT adapter (assigned elsewhere — existence only)

- Proxy `0x6C96dE32CEa08842dcc4058c14d3aaAD7Fa41dee` → impl `0xcd979b10a55fcdac23ec785ce3066c6ef8a479a4` (unchanged). **`balanceOf` = 3,196,899,512.94 USDT ≈ $3.197 B** (eth 26,271,769; pass7 read $3,197,754,613 → **−$0.86 M drift**, immaterial).
- **No NEW live 1-of-1 DVN:** the four dormant inbound EIDs still have **no peer** — `peers(30165 zkSync)=0`, `peers(30214 Scroll)=0`, `peers(30375 Katana)=0`, `peers(30243)=0`; the live routes `peers(30109 Polygon)`, `peers(30110 Arbitrum)`, `peers(30111 OP)` are non-zero. **Verdict: LANE-CLOSED** (deep-dive assigned to `usdt0-oft/`).

---

## 6. Prior-coverage determination (vs pass7 README §5 / tracker)

- **PRIOR-COVERED (do not re-audit):** items **1, 2, 3, 5** — all appear in `zombie-hunt-iv/pass7/bridges.md` / `_child_lz_hyperlane.md`, and README §5 lists "Bridges (~1,470 contracts) $0 E-U" as VERIFIED-CLOSED. Re-read this pass found **no drift** (same ISM modules, same dormant peers, same Payy balance).
- **ASSIGNED / OPEN (in-flight elsewhere):** items **4a, 4b, 4c** → `p7-oracle-residual` (ZH4P7 tracker line 54). **4c is PRIOR-PARTIAL** (pass4 closed the Sei leg only).
- **NOT-A-PROTOCOL:** none of the six (all are real deployed protocols).
- No target on the list is a **fresh E-U** lead.

## 7. What ran locally (repro)

Public RPCs only (no keys written): `ethereum-rpc.publicnode.com`, `base-rpc.publicnode.com`, `optimism-rpc.publicnode.com`, `arbitrum-one-rpc.publicnode.com`, `bsc-rpc.publicnode.com`, `evmrpc.0g.ai`.
- `cast call/codesize/code/storage/balance/block-number` for every read above (blocks: eth 26,271,769 · base 53,083,494 · op 158,678,780 · arb 518,227,549 · bsc 129,761,267 · 0G 48,268,928).
- Selectors used: `interchainSecurityModule()` `0xde523cf3`, `moduleType()` `0x6465e69f`, `modulesAndThreshold(bytes)` `0x6f72df75`, `trustedRelayer()` `0x8596c226`, `peers(uint32)`.
- Sources: `eth.blockscout.com/api/v2/smart-contracts/<addr>` (Payy `RollupV1` source); `raw.githubusercontent.com/hyperlane-xyz/hyperlane-registry/...` (route deploy/config YAMLs → router addresses); `raw.githubusercontent.com/MetaMask/delegation-framework/v1.3.0/...` (`EIP7702DeleGatorCore`); `coins.llama.fi/prices` (VRA); DefiLlama `protocols` (TVLs).
- No fork, no tx, no signing. Web content treated as untrusted data.

**Limitations.** (i) I did not re-enumerate all ~30 Hyperlane routes or all USDT0 peers — the **named** five routes + the four dormant EIDs were re-read; the rest are carried from child-A. (ii) Payy "pause" is not an on-chain flag; the residual is `onlyProver`, so the pass7 wording should be corrected (not "paused" — "**prover-gated**"). (iii) The oracle-tail verdicts (4a–4c) are **existence/locate** confirmations, not mechanism verdicts — those belong to `p7-oracle-residual`. (iv) Point-in-time **2026-10-25**; re-read live state before acting. *Nothing here is an instruction to transact.*
