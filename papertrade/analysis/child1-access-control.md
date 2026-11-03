# Child 1 — Papertrade access control (Q1–Q5)

Scope: HyperEVM (chain 999) Papertrade perp venue. Read-only analysis: `eth_call` / `eth_getStorageAt` / `eth_getCode` / `eth_getLogs` via the public keyless RPC `https://rpc.hyperliquid.xyz/evm`. No keys, no signing, no transactions. All bytecode claims referenced by opcode offset in the parent's disassembly (`zombie-hunt-iii/work/raw/zh3v/disasm_batchexec_impl.txt`, `disasm_exchange.txt`) and my own disassembly of the oracle impl (`child1/oracle_impl_disasm.txt`).

Contracts (EIP-1967 impl slots verified live at block 48646665):

| Contract | Proxy | Impl |
|---|---|---|
| Exchange | `0x6cd5661646289fb6e65ea5c032310fded797d0a2` | `0x0f3febfc94876b0c895f7acecdc8f5c863b549ee` |
| BatchExecutor | `0x233Ff29b239abc1D7748605dA9b205C3e008626E` | `0xe0bc9cc7b067060aafccbaa3e250700c9cdd7262` |
| PriceOracle | `0xa9B4c7b7Ca5835652d81E25739c870D49F39cC2e` | `0x3997ffc8cbd281d4fc8d0548e505ae2fbbbd985a` |

> **Correction to the task brief:** the two signed trading entries are the other way round from the task text. `0xec6783f0` = **open** (margin + leverage args); `0x2792e706` = **close** (array of position ids). Proof below (Q2/Q3).

Live state anchors (block if noted):
- BatchExecutor owner `0xb915fa41e824d6aa31bb833ee81220c0f2c8ea0f`; slot0 = `(Exchange<<16)|1`; slot1 = SessionKeyManager `0x8326eb8896e358717f10502ec73ce8d28e37b108`; slot2 = paperStaking `0xaad6c7b0cc3014fc80ffedae0ed7ce5967b0f016`; slot5 = 1.
- Exchange slot `0x58` = `0x233Ff29b239abc1D7748605dA9b205C3e008626E` (BatchExecutor); slot `0x1d` = `(SessionKeyManager<<8)|0`; slot `0x2` = oracle; `tradingPaused()` = 0; `nextPositionId` = 0xd348f (865,423) @ blk 48646665.

---

## Q1 — Relayer registration and current relayer set

**Registration is owner-only. There is no self-serve path.**

- **Gate for using the batch entry** `0x251fb27d`: impl offset `0x0466–0x0477` — `mem[0]=CALLER; mem[0x20]=4; keccak256; SLOAD; AND 0xff; ISZERO → revert`. Mapping base slot **4**: key = `keccak256(abi.encode(relayer, uint256(4)))`. Revert path `0x0828–0x0833`: `PUSH4 0x0bfd9033 << 1` ⇒ error selector **`0x17fb2066`**, which keccak brute-force matches **`NotAuthorizedRelayer()`**.
- **Setter = `setAuthorizedRelayer(address,bool)`, selector `0x9011e5f9`** (keccak-verified). Impl `0x031b–0x038a`: requires `CALLER == SLOAD(0x03)` (owner slot) else error `0x30cd7471` = **`NotOwner()`** (offset `0x00f5–0x0106`); args `(address,bool)`; writes `mapping[base 4][addr]` (low byte) and emits `LOG2` with topic0 `0x431c9efc75fd5a8b5d510e3458e1c31ac5c3de0385743f60f76491e1e0867391` = **`AuthorizedRelayerUpdated(address,bool)`** (keccak-verified; const stored in code at `0xce6`, `LOG2` at `0x038a`).
- **Getter `0x29e295c5`** = **`authorizedRelayers(address)`** (keccak match); impl `0x03d6–0x0412` reads the same `keccak(addr‖4)` slot.
- **No other writer** to mapping base 4 exists in the impl: the only other occurrence is inside the initializer `0x9ccae24e` (batch slots `0x0225–0x02d1`, guarded by slot0 flag bits). Re-initialization is impossible: my `eth_call` of `0x9ccae24e` from a fresh EOA reverts **`AlreadyInitialized()` `0x0dc149f0`**. Proxy-admin function `0x0f71c8bc` (checks EIP-1967 admin slot `0xb5312768…`) does **not** touch mapping 4.
- **Empirical proof (eth_call, latest):**
  - `0x251fb27d` (empty batch) from `0x1111…1111` → revert **`0x17fb2066` (`NotAuthorizedRelayer`)**;
  - same calldata from `0xc916e55b1909be6582bf1b2f017aaf82ad8eb0b4` → **`0x` (success)**;
  - `0x9011e5f9(fresh,true)` from fresh EOA → `NotOwner()`; from owner `0xb915fa41…` → succeeds (simulation only);
  - `0xf2fde38b` transferOwnership from fresh EOA → `NotOwner()`.
- **Current registered set (live reads, blk 48646665, two independent read paths):**
  - `authorizedRelayers(0xc916e55b1909be6582bf1b2f017aaf82ad8eb0b4)` = 1; raw `keccak(addr‖4)` = `0x…01`.
  - `authorizedRelayers(0xe726b15cfa8808b2b033dd324a61e754dc6c1686)` = 1; raw mapping = `0x…01`.
  - Negative checks (=0): owner `0xb915fa41…`; marketKeeper `0x3721476d…`; pauseGuardian `0x69629276…`; Exchange slot6 address `0x75174549…`; zero address.
  - All 68 collected BatchExecutor txs (blocks ≈48,628,002 → 48,646,178) were sent by exactly these two EOAs — consistent with the set being `{c916e55b…, e726b15c…}`.
- **Limitation:** full historical enumeration of register/unregister events was not completed — the public RPC caps `eth_getLogs` at 1,000 blocks and rate-limits aggressively; a partial topic-filtered scan found no relayer-set events in the sampled windows. Membership of the two EOAs and non-membership of the candidates above are the verified facts.

**Consequence:** a fresh attacker cannot register themselves; they must get the official relayer (or the owner) to submit their intent.

---

## Q2 — Open/close entries and their gates

**Entries:** exactly two signed trading entries on Exchange; both require `CALLER == SLOAD(0x58)` = BatchExecutor (`0x233Ff29b…`):
- **Open = `0xec6783f0`** — handler at impl `0x0729`; gate `0x07ae–0x07bc` (`SLOAD 0x58; CALLER; SUB; JUMPI` → error path `0x0fcb` building `0x6d4b785b<<1` = **`0xda96f0b6`**).
- **Close = `0x2792e706`** — handler at impl `0x313e`; same gate `0x318b–0x3198`.

**Calldata layout (decoded from real txs in `es_batchexec_recent.json` / `batchexec_txs*.json`; all offsets are calldata word offsets after the 4-byte selector):**

- **Open `0xec6783f0`** — 11 static words:
  `w0 user(address)`, `w1 instrumentId(0=BTC,1=ETH)`, `w2 isLong(bool, 0=short/1=long)`, `w3 margin (uint128, 1e18 USD)`, `w4 leverage (uint32)`, `w5 fundingFlag(bool)`, `w6 nonce`, `w7 deadline`, `w8 v`, `w9 r`, `w10 s`.
  Mask/bool checks at offsets `0x074d–0x07ac` (`w2` bool, `w3 ≤ 2^128−1`, `w4 ≤ 2^32−1`, `w5` bool, `w8` ≤ 0xff).
  Real example (blk 48628019, user `0x1ff24cbb…`, BTC, w2=0, margin=0x8ac7230489e80000=10e18, lev=0x14d=333, nonce 0x1851c76e, deadline 0x6ad1160d, v=0x1b).
- **Close `0x2792e706`** — 7 fixed words + dynamic `uint256[]`:
  `w0 user`, `w1 offset=0xe0 → uint256[] positionIds`, `w2 nonce`, `w3 deadline`, `w4 v`, `w5 r`, `w6 s`.
  Real example: user `0xf26da589…`, ids `[0xc50ed, 0xc50e7]`, nonce 0x4973324b/4c, deadline 0x6ad123e7.
  **Semantics proof:** `positions(807149)` (`0xc50ed`) live at blk 48646869 decodes to owner `0xf26da589c149efa79b2be62f4b81b1b63a8ea7cd` (the tx's `user`), BTC, margin 10e18, isOpen=0 — the ids are position ids, so `0x2792e706` closes. Recent batches (blk 48,646,xxx) contain only closes.

**Checks besides the caller gate:**
1. **Signature validation via SessionKeyManager** (`0x8326eb8896e358717f10502ec73ce8d28e37b108` = `SLOAD(0x1d)>>8`, `EXTCODESIZE` checked):
   - a state-changing `CALL` with effective selector **`0xb002b9fa`** (encoded as `PUSH4 0x58015cfd; PUSH1 0xe1; SHL`) passing `(nonce, deadline)` — open: `0x07d8–0x0801` (args from `cd 0xc4` = nonce, `cd 0xe4` = deadline); close: `0x31b3–0x31dc` (args from `cd 0x44`, …). This is the nonce/deadline consumer.
   - a `STATICCALL` with effective selector **`0x7f608253`** passing the EIP-712-style digest + `v,r,s` + user; recovered address must equal the user (or a session key authorized for that user) — open: `0x08c2–0x0916`; close: `0x3281–0x32c4`.
   - Digest struct-typehash constants embedded in bytecode: **open** `0xfce2fb41f9ff0457a0f012e62cfd6a7cff4e8439ae20008ab6979c740ba5a983` (built `0x080f–0x08c2`); **close** `0x9cc23a52214afa42e1ae53cdb2e79dc2d0cd33c33faca383ed3b149300adcb13` (built `0x3222–0x3280`). (Type-string preimages were not recovered by brute force.)
   - **Empirical:** replaying real (already-executed) open and close calldata with `from = BatchExecutor` reverts **`ExpiredDeadline()` `0xf87d9271`** (deadlines 0x6ad1160d/0x6ad123e7 are now past) — nonce/deadline enforcement confirmed; replaying from a fresh EOA **and even from the owner EOA** reverts `0xda96f0b6` (caller gate).
2. **Market config (mapping base `0x07`, key `keccak(marketId‖7)`):** `SLOAD>>224`… actually top-32 bits = max leverage. Live: BTC and ETH configs both have top 32 bits `0x3e8` = **1000** ⇒ max leverage 1000× (open path compares leverage and reverts **`LeverageTooHigh()` `0x0a4f5a07`**, offset `0x0f24`). `mapping7[market]==0` (unlisted market) reverts (offset `0x0f36`, selector `0x1907e1ff<<2 = 0x641f87fc`, name unmatched).
3. **Market paused flag (mapping base `0x23`):** open path `0x0948–0x0955` — if `keccak(marketId‖0x23)` low byte ≠ 0 → revert **`MarketIsPaused()` `0x741df939`** (offset `0x0f48`). Live BTC/ETH = 0 (not paused).
4. **Global minimums (slot `0x1c`):** low 128 bits = `0x8ac7230489e80000` = **10e18 ($10 minimum margin)**; high 128 bits = `0x3635c9adc5dea00000` = **1e21 ($1000 minimum notional = margin × leverage)**. Checks at `0x0977–0x0990` and `0x09a7–0x09b5`; notional computed by checked multiply helper `0x435f`.
5. **Per-side OI caps (mapping base `0x24`, slot = `scale63‖uint96 longOI‖uint96 shortOI`, slot+1 = `capShort_high128‖capLong_low128`):** open path compares long OI (low 96) vs cap (low 128) when `isLong!=0` (offsets `0x0a19–0x0a55`) and short OI (bits 96–191) vs cap (`slot+1 >> 128`) when `isLong==0` (offsets `0x0eb6–0x0eda`); exceeding reverts (`0x0ea4`, selector `0x40f92143`).
6. **Funding flag (`w5`)**: selects between funding from the user's available balance vs queued collateral — mapping base `0x13` check at `0x0a5f–0x0a85` in one branch, alternative branch at `0x0e08` (inferred semantics; see limitations).

**Per-account limits:** none found — no max-open-positions count, no per-account OI cap, no cooldown, and no per-user margin cap in the open path. Limits are per-market/per-side and global minimums only.

---

## Q3 — Close path and liquidations

- **Close is relayer-only.** `0x2792e706` requires `CALLER == 0x233Ff29b…` (offset `0x318b`); fresh EOA and owner EOA both revert `0xda96f0b6` in `eth_call`.
- Internally it loops the `positionIds` array, reads `positions[id]` (mapping base `0x0a`, e.g. offset `0x3634–0x3642`), and settles at the oracle price via helper `0x5331` (call site `0x36b5`) → `0x5838` → oracle `getMid` (`0xc0182669`).
- **Liquidations are permissionless.** Handler for `liquidate(uint256)` `0x415f1240` at impl `0x2a14`; `liquidateBatch(uint256[])` `0x599dc539` at impl `0x2706`. The whole region `0x2706–0x2c60` contains **zero `CALLER` checks** (grep count = 0). Empirical: fresh EOA `eth_call` to `liquidate(0)` and to a real closed position `liquidate(807149)` both revert **`PositionNotOpen()` `0x94e88a21`** — the call passed authentication (none exists) and failed on position state.
- **Liquidation price = oracle BBO.** The liquidate handler calls `0x5331` (call site `0x2a99`), which builds calldata for the oracle selector `0xc0182669` (exchange-side helper `0x5838`, selector written at impl offset `0x585c`, `STATICCALL` at `0x5883` to `SLOAD(0x02)` = oracle proxy) — i.e. the same BBO-mid source used for open/close; liquidation condition math in helper `0x4efb` (margin×leverage, 1e18 scaler, docs say trigger includes a ~5bp buffer).

---

## Q4 — PriceOracle checks (live-verified)

- Impl `0x3997ffc8cbd281d4fc8d0548e505ae2fbbbd985a` (EIP-1967 verified live). Implemented selectors include `fb466481 getBBO(uint32)`, `c0182669` (BBO-mid view), `8da5cb5b owner()`, `c4d66de8 initialize(address)`, `f2fde38b transferOwnership`, plus setters.
- **`getBBO` (`0xfb466481`)** — confirmed live: `getBBO(0)`= `(822430, 822440)`, `getBBO(1)` = `(244640, 244650)`, `getBBO(2)` = `(17457, 17461)` — `(uint64 bid, uint64 ask)` (blk 48646665). Implementation: one `STATICCALL` to address **`0x…080e`** (the Hyperliquid BBO read precompile — `BBO_PRECOMPILE_ADDRESS` in `L1Read.sol`) at impl offsets `0x8f1–0x8f5`; requires call success and returndata length ≥ 0x40; on failure reverts with the string **"BBO read failed"**. Live: `getBBO(0xffffffff)` reverts `Error("BBO read failed")` (`0x08c379a0…`).
- **`0xc0182669`** (the mid price the Exchange actually trades/settles at): calls the same BBO read, then checks **bid ≠ 0** (`0x1d4`), **ask ≠ 0** (`0x1dc`), **not crossed i.e. `ask ≥ bid`** (`0x1e5–0x1e9`, `LT` → revert branch `0x0257`), and returns **`(bid+ask)>>1`** (`0x1f3–0x1f6`).
- Other helpers read the oracle-price precompile `0x…0807` and mark-price precompile `0x…0806` with zero checks — their revert strings are embedded in the bytecode and decode exactly to: **"Oracle price is zero"**, **"Oracle read failed"**, **"Mark price is zero"**, **"Mark price read failed"**, **"BBO read failed"** (strings recovered from shifted constants in my `child1/oracle_impl_disasm.txt`).
- **No max-deviation, TWAP, or lookback anywhere.** The impl has no price-history storage: the only `SLOAD`s are owner/config slots (`0xeb`, `0x136`, `0x168`, `0x441`, `0x5d5`) and two setters (`SSTORE` at `0x16f`, `0x17c`, `0x5f4`); there are no timestamps, no history buffers, no loops over observations. The only external calls are the three read precompiles. This matches the docs: "reverts if the precompile returns zero or a crossed book … no maximum-deviation, time-weighted-price, or lookback breaker."

---

## Q5 — What blocks a fresh unprivileged attacker today

Verified blockers (in order of enforcement):

1. **Relayer allowlist (hard).** Batches only accepted from `authorizedRelayers` (mapping base 4; `NotAuthorizedRelayer()` `0x17fb2066`). Registration is **owner-only** (`0x9011e5f9`, `NotOwner()`; owner = `0xb915fa41e824d6aa31bb833ee81220c0f2c8ea0f`). No self-serve path exists.
2. **Exchange caller gate (hard).** Open/close revert unless `msg.sender == BatchExecutor` (`0xda96f0b6`).
3. **User authorization (hard).** A valid nonce+deadline signature recovered to the user or their session key (`ExpiredDeadline()` observed on replay; nonce consumed by SessionKeyManager).
4. **Market-level controls:** market must be listed and unpaused — BTC/ETH both listed and unpaused live (mapping `0x07` ≠ 0, mapping `0x23` = 0).
5. **Trade minimums:** margin ≥ $10 (10e18); margin×leverage ≥ $1000 (1e21); leverage ≤ 1000× (per-market config).
6. **Per-side OI caps** (mapping `0x24`): live headroom at blk 48647203 — **BTC long 112.7 BTC ($9.26M), BTC short 72.1 BTC ($5.92M), ETH long 2,646 ETH ($6.46M), ETH short 2,606 ETH ($6.36M)**. So opens are *not* currently blocked by caps (recent activity is close-only, which shrank OI and trailed caps).
7. **Funding:** margin must come from the user's own balance/queued collateral; no path mints margin.
8. **No per-account count caps or cooldowns** were found; the de-facto per-account gate is the user's own signature + balance.

---

## Fresh-attacker verdict

**A brand-new EOA with no privileges cannot open a Papertrade position today on-chain by itself.** Every open must travel `user signature (wallet or registered session key) → Papertrade's registered relayer EOA (only `0xc916e55b1909be6582bf1b2f017aaf82ad8eb0b4` or `0xe726b15cfa8808b2b033dd324a61e754dc6c1686` are authorized) → BatchExecutor 0x233Ff29b… (entry `0x251fb27d`) → Exchange.openPositionBySig `0xec6783f0`**, with onchain checks for caller, signature/nonce/deadline, listing/pause, min margin/notional, max leverage and per-side OI caps. There is no self-registration path for relayers (owner-only setter) and no direct open entry on the Exchange. The only genuinely public trading-adjacent path is **liquidation** (`0x415f1240` / `0x599dc539`, no caller check), plus documented maintenance functions (queue harvest, sweep/finalize, staker-fee push). Practically, the only way a fresh attacker trades is to produce a validly signed intent and convince/route it through the official relayer (the docs confirm this is intentional: third-party frontends may generate compatible signatures but cannot bypass the relayer).

## What I could NOT determine (and caveats)

- Exact Solidity names for: caller-gate error `0xda96f0b6` (impl const `0x6d4b785b<<1`; not matched), min-notional error `0x9f65ae4c` (`0x27d96b39<<2`), OI-cap error `0x40f92143`, unlisted-market error `0x641f87fc` (`0x1907e1ff<<2`), SessionKeyManager selectors (`0xb002b9fa`, `0x7f608253`, `0xd45167d0`), the relayer-callable Exchange session-key entry `0x8d09f23f` (it STATICCALLs the SessionKeyManager with effective selector `0xd45167d0`), staking selectors on `0xaad6c7b0` (`0x83115825`, `0x9c96d4a1`, `0xfa2871b5`, `0xf0355460`) and the typehash preimages for `0xfce2fb41…` / `0x9cc23a52…`. (`setAuthorizedRelayer(address,bool)` and `AuthorizedRelayerUpdated(address,bool)` were successfully matched.)
- Full historical relayer-set enumeration: blocked by HyperEVM RPC (`eth_getLogs` ≤ 1,000 blocks, heavy rate limiting). Membership of the two relayers and non-membership of several operator addresses are directly verified; a complete event history was not.
- OI units: raw fields are almost certainly asset-quantity × 1e18 (cap − current × mid reproduces the keeper's dollar headroom, e.g. 112.7 BTC × $82,166 ≈ $9.26M); I did not see the exact scaling opcode chain end-to-end, so treat the $ figures as inferred from raw units × live mid.
- Per-account semantics of the open-path `w5` funding flag and mapping `0x13` (balance vs queued collateral) are inferred from structure + docs, not decoded symbolically.
- No signature was ever produced or sent; all "success" results come from `eth_call` simulations (e.g. owner `setRelayer`), which leave no state change.

## Artifacts (in `papertrade/analysis/child1/`)

- `probe1.py` / `probe1_out.txt` — EIP-1967 slots, getters, relayer mapping reads, oracle BBO, positions (blk 48646665/48646869).
- `gate_tests.txt` — eth_call access-control tests (relayer gate, caller gate, owner gate, init, liquidate) with revert selectors.
- `batch_decode.txt` — full decode of 68 BatchExecutor txs (outer structs + inner selectors/args).
- `selector_names.txt`, `selector_names2.txt` — keccak brute-force matches (NotAuthorizedRelayer, NotOwner, AlreadyInitialized, PositionNotOpen, LeverageTooHigh, MarketIsPaused, ExpiredDeadline, authorizedRelayers/paperStaking/exchange getters).
- `oracle_impl_disasm.txt` — my opcode-level disassembly of PriceOracle impl (precompile calls at `0x…0806/0807/080e`, revert strings, crossed-book check).
- `market_state.txt` — live mapping `0x07`/`0x23` for BTC/ETH, slot `0x1c`.
- `logs_batch.txt`, `logs_narrow.txt`, `logs_topicfiltered.txt`, `relayer_scan.out`, `init_window_scan.txt` — log-enumeration attempts and their RPC limits.
