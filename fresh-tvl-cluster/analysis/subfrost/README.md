# Z3-H17 · SUBFROST (Ethereum side) — frUSD custody vault + Curve 3pool strategy

**Date:** 2026-10-16 · **Chain:** Ethereum (1) (protocol is multi-chain: Bitcoin Alkanes/BRC2.0 + Ethereum; **BTC side out of scope — P/S trust model**) · **Status:** read-only; PoC fork-verified only; no mainnet transactions
**Scope:** frUSD VaultImpl proxy `0x95779E7E1C943042255B8a78273fe6DE4823CF06` → impl `0x5376BeeDBa9Ba7F5b0396d28bd75473027B8Bd55` (verified `exact_match`, solc 0.8.24) ·
Curve3PoolStrategy `0x5c5D66C82e2C634074661C3E7427668737C70100` (verified `exact_match`) · 3CRV `0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490` · Curve 3pool `0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7`
**Method:** full verified-source review (the screening's "impl unverified" note was WRONG — both contracts are Sourcify `exact_match`), live-state reads at blocks 26,202,548 / 26,202,587 (public RPC), full event-history scan (public `eth_getLogs`), and an adversarial Foundry fork suite (`poc/test/Subfrost.t.sol`, **5/5 PASS**), including a fork-only simulation of the FROST-key path (§4/T5) to quantify the trust model.

---

## 1. TL;DR

| target | live extractable (unprivileged) | why closed / open | latent risk |
|---|---|---|---|
| `authenticatedCall` / `authenticatedMulticall` (the ONLY path to any vault action) | **$0** | BIP340 (Schnorr) FROST-group signature required over `keccak(abi.encode(data, nonce, chainid, address(this)))`; verifier is the inlined audited `bip340-solidity` primitive (`Bip340NaiveLib`) with full-coordinate x(R) comparison, range checks (rx<P, s<n), on-curve + non-residue `liftX`, even-y(R), R≠∞. Fork-proven: empty/zero/bit-flipped signatures revert `InvalidSignature` even from a live relayer (T3); a **correctly-formed test-key signature is ACCEPTED** by the deployed contract, proving the accept-path (T5) | forging requires solving discrete log; total custody rides on ONE group key (no second gate) |
| `withdrawFromBridge(nonce, assetId, amount, target, script)` | **$0** | `onlyAuth` = `msg.sender == address(this)`: reachable ONLY via a FROST-signed `authenticatedCall` (fork-proven `NotSelf` direct and via relayer, T3). At-most-once `usedBridgeNonce` + `authNonce` replay guards (fork-proven both, T5) | if the FROST key signs, funds move — see P |
| `depositAndBridge(assetId, amount, bridgeData)` — **permissionless** | **$0** | Takes only the caller's own USDC/USDT, charges `flatFee = 1.99 USDC/USDT` + 10 bps, queues a `PaymentQueued` for the Bitcoin-side mint. Fork-proven: 100 USDC in → net credit 97,911,990 (6dp) and NO EVM-side exit without the FROST key (T2) | one-way door by design: EVM custody exit depends entirely on the Bitcoin-side coordinator + FROST group (S/P trust) |
| Curve3PoolStrategy `deposit`/`withdraw`/`withdrawAll` | **$0** | `onlyVault` on an **immutable** vault address (fork-proven `NotVault` for attacker and relayer, T4) | — |
| Curve3PoolStrategy `emergencyWithdraw` | **$0** | `onlyOwner` (EOA `0x896F346b…`); pays the immutable `vault` (fork-proven: 52,493.56 3CRV exited; proceeds to the vault, owner receives $0, T4) | owner can force-custody a dislocated pool (griefing only; cannot take custody) |
| UUPS upgrade (`upgradeToAndCall`) | **$0** | `_authorizeUpgrade` is `onlyAuth` — the SAME FROST gate as withdrawals; EIP-1967 admin slot = 0; no beacon (fork-proven revert, T3) | upgrade authority = withdrawal authority (single key, no second gate) |
| BTC side (frBTC/frUSD Alkane + BRC2.0 mint authority) | n/a (out of scope) | signing-group trust model (coordinator + FROST); DL $8.94M − ETH ~$58.4K ≈ **$8.88M** | P/S: the same trust family as the ETH gate |

**Total live extractable now: $0.00 — confidence high.** ETH-side value under FROST custody: **$58,387.84**
(vault USDC 530.84 + vault USDT 3,272.96 + strategy 3CRV 52,493.56 valued at 3pool `get_virtual_price` 1.03982 —
`totalAssets(0) = 617.29 USDC`, `totalAssets(1) = 57,770.55 USDT`). If the FROST group key signs, **all of it is
withdrawable** — fork-demonstrated in T5. P-class = $58,387.84 (ETH) + ~$8.88M (BTC-side, trust) ≈ $8.94M DL TVL.

## 2. Mechanism (exact terms)

**frUSD is NOT an ERC20 on Ethereum.** It is a Bitcoin alkane; the Ethereum contract is a multi-asset custody vault for the
bridge directions:

- **IN (`depositAndBridge`, public, `nonReentrant`)**: pulls `amount` of `assets[assetId]` (0 = USDC, 1 = USDT; the full
  registry, fixed at `initialize`), credits the amount that ACTUALLY arrived, charges `flatFee` then `protocolFeeBps`
  (10 bps) into `feesCollected[assetId]`, appends a `Payment` record (with opaque `bridgeData` for the coordinator), and
  auto-sweeps idle balance above `minSweep[assetId]` (1000 units) into the strategy. Bitcoin-side coordinator mints the
  alkane; there is **no EVM token mint and no EVM-facing redemption** other than the FROST-signed bridge-out.
- **OUT (`withdrawFromBridge`, `onlyAuth`)**: releases `amount` of the burn-named asset to `target` (optionally executing a
  signed `script` call against a contract target with an exact-`amount` approval that is retracted), sources liquidity from
  idle balance first then `strategy.withdraw` (round-up to `withdrawChunk`), and is at-most-once per `bridgeNonce`
  (`usedBridgeNonce` + monotonic `nextBurnNonce`).
- **Authority**: `authenticatedCall(data, nonce, signature)` / `authenticatedMulticall([...], nonce, signature)` execute
  `address(this).call(data)` only after `Bip340NaiveLib.verify(defaultPublicKey, rx, s, keccak(abi.encode(data, nonce,
  chainid, this)))`. `authNonce` is strictly monotonic; batches are single-nonce and reject nested auth selectors.
  `onlyRelayer` gates *submission* (anti-mempool-griefing; fails OPEN if `relayerAdmin == 0` or `relayerCount == 0` — live
  state is configured: admin `0x94321001…`, 2 relayers).
- **Strategy (`Curve3PoolStrategy`)**: one shared 3pool LP position backs both ids; `shares[id]` are denominated in LP;
  `totalAssets(id)` = LP balance × `get_virtual_price` pro-rata (monotone; cannot be pushed down in-tx); deposits/withdrawals
  `onlyVault`; `emergencyWithdraw` (owner) exits balanced `remove_liquidity` → coins to the **immutable** vault.

## 3. Live-state assessment (blocks 26,202,548 / 26,202,587)

- **Proxy**: impl slot = `0x5376BeeDBa9Ba7F5b0396d28bd75473027B8Bd55`; admin slot = 0; beacon slot = 0 (UUPS, single authority).
  `proxiableUUID()` reverts `UUPSUnauthorizedCallContext` via the proxy (expected OZ5 `notDelegated`).
- **Vault config**: `assetCount = 2`; `assets(0) = USDC`, `assets(1) = USDT`; `defaultPublicKey = 0xb6a6cf5121ae3aca…`;
  `authNonce = 35`; `relayerAdmin = 0x943210016467e6e93B579Eb22C55f8ad795bf9A8` (EOA); `relayerCount = 2`
  (relayers `0x50746642693e05Cc…` — live `isRelayer = true` — and `0x896F346bC711a8fd…`, also the strategy owner);
  `flatFee = 1,990,000` (=$1.99); `protocolFeeBps = 10`; `feeRecipient = vault` (so `withdrawFees` reverts `InvalidTarget`
  until governance sets one); `strategy = 0x5c5D66C8…`; `nextBurnNonce = 34`; `getPaymentsLength = 72`.
- **Accounting**: `totalAssets(0) = 617,294,561` (USDC idle 530,838,469 + strategy 86,456,092); `totalAssets(1) =
  57,770,549,243` (USDT idle 3,272,955,599 + strategy 54,497,593,644); `pending(0) = 272,048,448`, `pending(1) =
  1,371,713,528,564` (monotonic gross bridge-ins; never decremented); `feesCollected(0) = 32,785,402`,
  `feesCollected(1) = 2,867,824,356` (accrued, held in vault).
- **Strategy**: `vault()` = the frUSD vault (immutable); `pool()` = 3pool; `lpToken()` = 3CRV; `isActive = true`;
  `slippageBps = 50`; `owner = 0x896F346b…` (EOA); `shares(0) = 84.676e18`, `shares(1) = 53,375.455e18`,
  `totalShares = 53,460.131e18`; `lpBalance = 52,493.561e18 3CRV` (LP < shares only because cross-asset exits burn LP that no
  share backed — per design); 3CRV in vault = 0; 3pool `get_virtual_price = 1.039823717424521011`; 3pool balances
  DAI 23,642,308.79 / USDC 23,667,585.02 / USDT 112,657,050.17.
- **History**: 72 `PaymentQueued` (blocks 25,677,906 → 26,187,979); 34 `BridgeWithdrawalProcessed` (last 26,183,216);
  2 `RelayerSet` grants (deploy block 25,671,088 + `0x896F…` later); one `RelayerAdminTransferred` (deployer → `0x94321001…`).
- **DL cross-check**: adapter counts vault USDC + vault USDT + strategy 3CRV = ~$58.4K on Ethereum; the rest of DL's
  $8,939,908 is BTC-side (`__btcBook`). ETH-side value ≈ $56–58K depending on 3CRV mark/read time.

## 4. What an attacker can / cannot do

Can (all verified, none profitable):
- Call `depositAndBridge` freely (T2: net credit 97,911,990 for 100 USDC; payment queued; funds locked on the EVM side —
  exiting requires the FROST key + Bitcoin-side burn).
- Submit `authenticatedCall` IF whitelisted as a relayer (relayers are EOAs; the gate is liveness-only) — but any payload
  without a valid FROST signature reverts `InvalidSignature` (T3, three distinct garbage-sig trials).
- Cause the owner-key forced exit? No — not unprivileged. (T4 proves attacker cannot; owner can only send coins to the vault.)

Cannot:
- Move any custody asset: `withdrawFromBridge` is `onlyAuth` (T3), strategy movements are `onlyVault`/owner→vault only (T4),
  upgrades are `onlyAuth` (T3), `initialize` is spent (T3).
- Forge BIP340: the verifier rejects out-of-range rx/s, off-curve/non-residue keys, infinity R, odd-y R, and compares the
  full x(R); the challenge is the standard tagged BIP340 `sha256(tag‖tag‖rx‖px‖m)` (tag `0x7bb52d7a…`, verified byte-exact
  in source). A signature is only accepted if it satisfies the Schnorr equation — equivalently, solving DL. One benign
  quirk: `EllipticCurve.jacMul(0,…)` returns the input point instead of infinity, so `s = 0` is evaluated as `s = 1`
  (also noted in the source's audit trail); it does NOT enable forgery (the fixed-point problem remains 2⁻²⁵⁶).
- Replay: `authNonce` consumption + `usedBridgeNonce` per Bitcoin burn (fork-proven both, T5).

**P-class simulation (T5, fork only):** with a throwaway TEST key `vm.store`-ed into the `defaultPublicKey` slot and a
deterministic `authNonce`, the DEPLOYED verifier accepted correctly-signed payloads submitted by the live relayer and paid
out exactly `97,911,990` (USDC) and `897,111,990` (USDT) net of fees to the target; replays reverted. Conclusion: the
trust model is exact — whoever controls the FROST group (or its signing quorum) can drain `totalAssets`, and NO other party
can. This is a P (trust) risk, not E-U.

## 5. PoC / fork verification

- Project `poc/` (parent-pinned foundry.toml, solc 0.8.26, cancun; forge-std 1.9.6). Fork via keyless public RPCs
  (`FORK_RPC` override, else publicnode/drpc/1rpc). File `poc/test/Subfrost.t.sol` — contract `SubfrostH17Test`.
- **Local run: 5/5 PASS** at fork block 26,202,587. CI run URL: parent's run (this suite is in the cluster CI path).
- Precomputed BIP340 test vectors + signer: `analysis/subfrost/bip340_sign2.py` → `bip340_sigs2_out.txt` /
  `bip340_testvectors.json` (signatures self-verified off-chain against the exact BIP340 challenge before embedding).
- Key results: T1 structural (impl slot, no admin, registry); T2 public deposit is one-way + fee math; T3 authority gates
  (direct withdraw, non-relayer submit, three garbage signatures, upgrade, re-init); T4 strategy gates + owner exit goes
  to the vault; **T5 FROST-key accept-path + exact payouts + replay rejections**.

## 6. Verdict and residual risk

- **E-U: $0.00 — high confidence.** Every fund-moving selector is at least one of: `onlyAuth` (FROST BIP340), `onlyVault`
  (immutable), `onlyOwner` (pays the vault), or spent. The only permissionless selector, `depositAndBridge`, takes the
  caller's own funds and yields no EVM-side claim.
- **P (trust): $58,387.84 ETH-side + ~$8.88M BTC-side.** The FROST group key *is* the protocol: it gates withdrawals AND
  upgrades AND every parameter. On-chain there is exactly one pubkey (`0xb6a6cf5121ae3aca…`), no threshold visible, no
  timelock, no separate admin. Live relayer set: 2 EOAs (one = strategy owner EOA `0x896F346b…`), relayer admin EOA
  `0x94321001…`. A quorum/ops compromise drains both sides.
- **H-O: $0** in the strict sense (no self-service exit on the EVM side; exits require FROST + a Bitcoin burn).
- **S:** none identified today; if both relayers and the FROST group were lost simultaneously, custodial funds would become
  unreachable (`onlyRelayer` fail-open does not help without signatures).
- **Latent**: `feeRecipient == vault` blocks `withdrawFees` (fee accrual $32.79 USDC + $2,867.82 USDT currently
  un-withdrawable until governance acts); owner-key force-custody during a 3pool dislocation; `pending[]` is monotonic and
  not a solvency invariant (audit F3 noted in-code).
- **Monitors:** `defaultPublicKey` changes; `authNonce`/`nextBurnNonce` jumps without matching `PaymentQueued`/Bitcoin
  burns; `RelayerSet`/`RelayerAdminTransferred`; strategy `isActive`/`slippageBps`/`owner`; vault idle vs `totalAssets`
  per id; large `depositAndBridge` bursts followed by bridge-outs.

## 7. Methodology & sources; files

Read-only; keyless endpoints only. Sources: Sourcify v2 `exact_match` for `VaultImpl`, `Curve3PoolStrategy`, `3CRV`, plus
the proxy (all saved under `sources/…_src`). Live state via public RPC `eth_call`/`eth_getStorageAt`; history via public
`eth_getLogs` (Tenderly/mevblocker) and Blockscout-free paths (Blockscout API was rate-limited). The screening's
"impl unverified" flag is corrected here (Sourcify has exact matches; solc 0.8.24). DefiLlama adapter `sumTokens-data2.js`
§subfrost cross-checked (vault USDC+USDT + strategy 3CRV).

**Files:** `README.md` · `summary.json` · `live_state_2026-10-16.json` · `state_reads.sh` + `state_reads_out.txt` ·
`relayer_scan_out.txt` · `bip340_sign2.py` + `bip340_sigs2_out.txt` + `bip340_testvectors.json` ·
`sources/**` (verified sources incl. bip340-solidity lib) · `poc/test/Subfrost.t.sol`.
