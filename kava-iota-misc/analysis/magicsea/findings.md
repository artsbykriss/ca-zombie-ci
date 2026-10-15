# MagicSea DEX (IOTA EVM, chain 8822) — zombie-hunt II, finding L2-25

**Verdict: $0 extractable by an unprivileged attacker (high confidence, with caveats).**
The LB money-path code is a *verbatim* deployment of upstream Trader Joe Liquidity Book **v2.2.0**; the only
known upstream semantic delta is an already-fixed-upstream composition-fee formula, which is **net-negative to
exploit** (measured on a fork). Everything custom (V2 fork, staking, hooks rewarder, OFT) is small-value and
was checked for unprivileged extraction paths; none found.

- **Read-only**, no keys, no transactions. All reads at pinned block **13020932** (2026-10-15T11:08:56Z, ts `1792062536`)
  via public RPC `https://json-rpc.evm.iotaledger.net`. Explorer: `https://explorer.evm.iota.org`.
- PoC: `kava-iota-misc/poc/test/MagicSea.t.sol` (6 tests, **all pass** locally at the pinned block; written for the parent's CI).

---

## 1. Headline numbers (block 13020932)

| Surface | Value (USD quote) | Notes |
|---|---|---|
| LB (Liquidity Book) pools | **$131,092** | 97 pairs registered, 34 with reserves; USDC.e/USDT pool alone $127,489 |
| Classic V2 (Uniswap-V2 fork) | **$15,166** | 315 pairs, 228 non-empty, priced with known tokens only |
| MasterChefV2 LUM balance | **$5,096** | 727,004 LUM (rewards reserve; `mintLum=false`) |
| LB-hooks LUM held (unclaimed) | **$1,648** | 199,581 LUM (WIOTA/USDC.e hook) + 35,351 LUM (WETH/wIOTA hook) |
| MlumStaking (staked MLUM) | **$1,051** | 210,121 MLUM staked (69.8% of MLUM supply) |
| MLUM circulating (other) | ~$0.5k | TokenVestingPlans 39,953 MLUM, LB pairs ~45k MLUM, etc. |
| **Total ≈ DefiLlama $155,117** | **~$154–156k** | matches DL snapshot `IOTA EVM: 155117` |

Prices used (quote, 2026-10-15): wIOTA $0.04498762, USDT $0.999102, USDC.e $0.999645, WETH $2365.62,
LUM $0.00701068 (explorer `exchange_rate`), MLUM **$0.005** (pool-implied 0.1114 wIOTA; the explorer's
0.56252 for MLUM is stale/implausible — 100× off the pool).

Notable per-pool details (full table in `lb_pairs_state.json`):

- **USDC.e/USDT** `0xE919092CC7CBD2097ae3158f72Da484ac813b74b`, binStep 1, activeId 8388608.
  Reserves 3,284.36 USDC.e + 124,317.59 USDT (~$127.5k). **Active bin** only: 2,528.07 USDC.e + 9,069.82 USDT,
  totalSupply 4.9079e24. Static fees: baseFactor 50000 → base fee **0.05%**, protocolShare **2500/1e4 = 25%**,
  variableFeeControl 2e6 (volatility accumulator currently 0 → variable fee 0). Hooked
  (`hooks = 0x7494a9f40438aec8e3164e03e81370e6860f18d6`, flags beforeSwap|beforeMint|beforeBurn|beforeTransfer).
- WIOTA/USDC.e `0xa86d3169…` (~$1.69k), WETH/wIOTA `0xbac6c780…` (~$896), LUM/USDC.e ~$399, MLUM/wIOTA ~$387.
- Uncollected protocol fees at the block: USDT/USDC.e `(2.391164e6, 2.267098e6)` raw = $2.39 + $2.27;
  WIOTA/USDC.e `9.123 wIOTA` + 0.436 USDC.e; WETH/wIOTA `8.498 wIOTA` + 0.000118 WETH; MLUM/wIOTA ~$1.6;
  LUM/wIOTA ~$1.1. The protocol fee recipient **actively collects** them (e.g. tx
  `0xbfa590252df1f64bf7…` `collectProtocolFees` on 2026-07-11, sent by `0xed2eb15A…`).

## 2. Code provenance — the decisive fact

All sources were pulled from the Blockscout verified-source API and diffed against upstream GitHub tags:

| Contract | Upstream | Diff result |
|---|---|---|
| `LBPair` impl `0xbc83aea9…` | `traderjoe-xyz/joe-v2` **tag v2.2.0** (`1297c3822f`, 2024-03-20) | **0 diff lines** across all `src/**` files (pair, LBToken, BinHelper, FeeHelper, Hooks, OracleHelper, PriceHelper, Clone, Constants, all math libs, interfaces) |
| `LBFactory` `0x8Cce20D1…` | same | **0 diff** |
| `LBRouter` `0x25d526bA…` | same (v2.2.0 router) | **0 diff** |
| `LBPair` vs upstream **main** (2024-07-08) | — | exactly **one** semantic delta: the composition-fee hunk (below) + cosmetic inlinings |
| `MagicSeaPair/Factory/Router` | Uniswap V2 0.6.12 / Joe V1 pattern | standard, configurable fee (0.01–3%, `feeToSetter`-gated), `feeTo` protocol-LP mint, `ownerFeeShare`=50% |
| `LBHooksMCRewarder` impl `0xd37084fe…` | Merchant-Moe `lb-rewarder` pattern | `claim()` is self-only (`_isAuthorizedCaller`: `user == msg.sender`); no extra rewarders configured; `sweep()` onlyOwner and reward-token-locked while linked; hook ERC20 minted only once under `initializer` |
| `MasterChefV2`/`Voter`/`MlumStaking`/`RewarderFactory` | `joe-staking`-style fork (Sherlock audit `2024-06-magicsea`, scope repo now deleted) | deployed **after** the audit (impls 2024-07-23 / 2024-12-08 / 2024-08-05); accounting logic read, self-only user entry points |

So the LB stack is not a bespoke fork at all — it is byte-for-byte Trader Joe v2.2.0 (a deployment from
2024-04-10, block 15850). Any LB exploit would have to be an unpatched *upstream v2.2.0* issue. Scanning all
commits to `src/LBPair.sol` after the v2.2.0 tag, exactly one security-relevant fix exists:

**Upstream commit `7e5b0b4944` "Fix the composition fee calculation" (2024-07-04)** — not applied here:

```solidity
// deployed (pre-fix), LBPair._updateBin, active bin, fees != 0:
uint256 userLiquidity = amountsIn.sub(fees).getLiquidity(price);
uint256 binLiquidity  = binReserves.getLiquidity(price);      // <-- pre-fix
shares = userLiquidity.mulDivRoundDown(supply, binLiquidity);
...
// upstream post-fix:
uint256 binLiquidity  = binReserves.add(fees.sub(protocolCFees)).getLiquidity(price);
shares = userLiquidity.mulDivRoundDown(supply, binLiquidity);
```

## 3. Composition-fee over-mint — analysis and empirical result (H-O-1, not E-U)

**Mechanics.** Minting into the *active* bin with a composition different from the bin's triggers an implicit
swap fee (`getCompositionFees`, charged on the imbalanced part, rate `k` = total fee). The deployed pre-fix
formula uses the bin's liquidity *before* the retained fee as the minting denominator → the minter receives
more shares than the (value-neutral) post-fix formula. Linear-liquidity algebra (`L = p·x + y·2^128`) gives,
for a mint of liquidity `a`, fee `φ` in liquidity units, protocol cut `π = q·φ`, bin liquidity `r`, supply `S`:

- minter shares: `s_bug = (a−φ)·S/r` (post-fix: `(a−φ)·S/(r+φ−π)`);
- minter's round-trip (mint→burn) PnL: **`−(φ·r + π·u)/(r+u) < 0` for every input** (u = a−φ), i.e.
  asymptotically the minter's loss is exactly the protocol cut `π = q·φ`;
- value transferred from existing LPs to the minter: `u·(φ−π)/(r+u) ≤ φ−π` — bounded by the LP portion of the
  composition fee.

**Empirically measured on the live pool** (PoC `test_compositionFee_mintBurnRoundTrip_isNeverProfitable`,
attacker = fresh address, `deal()` funded, x-axis deposit = USDC.e (tokenX) only, active bin 8388608):

| deposit | CompositionFee emitted | attacker PnL (raw = µ$) | PnL $ |
|---|---|---|---|
| 200,000 USDC.e | 4,288,491 (=$4.29) | −1,248,419 | **−$1.25** |
| 2,000,000 USDC.e | 247,258 | −62,885 | −$0.063 |
| 20,000,000 USDC.e | 1,433 | −360 | −$0.0004 |
| 50,000,000 USDT (Y-side) | — | −316,314 | −$0.32 |

The Y-side figure matches theory exactly: `0.25 × 5e-4 × 2,528,069,225` (active-bin USDC.e side) = 316,009 µ$
≈ observed 316,314. The X-side fee is capped by the bin's **counterpart** reserve
(`φ ≤ k × 9,069.82 USDT ≈ $4.53`), and after one round trip the bin's counterpart side is stripped
(Y drops 9.07k → 0.50k), so subsequent operations have a proportionally smaller cap (hence the shrinking fee).

**Conclusion.** The over-mint lets the minter claw back the LPs' share (75%) of the composition fee, but the
minter always pays at least the protocol's 25% cut → strictly negative PnL. Max value *transferred from LPs* per
operation = `(1−q)·k·(active-bin counterpart reserve)` ≈ **$3.40** on the deepest bin of the deepest pool, while
the attacker simultaneously loses ≈ $1.13. Monetizable only by combining with an external price deviation
> q·k = 0.0125% (below one bin-step's quantization for this pool), which is ordinary arbitrage with a small fee
discount — not an extraction path. **Classification: H-O (bounded LP fee-bypass/griefing; attacker net-negative),
confidence high.** No E-U.

## 4. Other paths examined → negative results

- **Unprivileged admin paths** (PoC): `collectProtocolFees()` reverts `LBPair__OnlyProtocolFeeRecipient`;
  `setStaticFeeParameters` and `setHooksParameters` revert `LBPair__OnlyFactory`. Factory owner and fee
  recipient are EOAs (`0x0cF8C428…`, `0xed2eb15A…`); the fee recipient actively collects fees.
- **LB router / factory / pair math**: identical to upstream v2.2.0 (audited upstream, live on major chains);
  no bespoke modifications to exploit. Flash loans in the pair are the standard `flashLoan` with
  `ILBFlashLoanCallback` + nonReentrant.
- **V2 (classic)**: Uniswap V2 fork, standard `swap` k-check with fee-adjusted balances, `mint`/`burn`/`skim`
  standard; adjustable fee bounded [0.01%, 3%] behind `feeToSetter`; `feeTo` mints protocol LP via `_mintFee`
  (d = 50% of √k growth). No permissionless drains found.
- **LB hooks rewarder** (Merchant-Moe pattern, clones of `0xd37084fe…`): `claim(user, ids)` is self-only,
  `getPendingRewards` view-only, `sweep` onlyOwner (and blocked for the reward token while linked), no extra
  rewarders configured, no mint path for the hook ERC20 after the one-shot `initializer`. The hooks hold
  199,581 + 35,351 LUM of *unclaimed LP rewards*; no unprivileged path to redirect them found. JIT reward
  capture is economically irrelevant anyway: `lumPerSecond` = 2.4375e15 (0.0024 LUM/s ≈ 210 LUM/day
  ≈ **$1.48/day across all 28 farms**).
- **Voter / bribe system** (period 28 at the pinned block): 65 voted pools; only **one** bribe rewarder exists
  in recent periods (period 27, LUM/wIOTA pool, `0xcd49d92FeECF6C5065F8E0d7Ed05dD83ca01f4B0`) and it is a
  native-IOTA rewarder holding **0 wei**. The bribe subsystem currently has **zero live value**; nothing to
  steal and no reason to invest further there.
- **MasterChefV2 / MlumStaking / Voter / RewarderFactory** (joe-staking fork, deployed post-audit; proxied):
  deposit/withdraw/claim/emergencyWithdraw read; user entry points self-only; `mintLum=false` (rewards paid from
  the 727k LUM balance); owner EOA `0x7F76D5b3…` can upgrade (proxy) — privileged, not attacker-reachable.
- **MLUM/LUM LayerZero OFT bridge** ("Magic LUM Bridge"): endpoint `0x1a44076050125825900e736c501f859c50fE728c`
  (LZ v2), owner EOA `0xE9b1d16d…`. No `send`/`lzReceive` traffic (only `approve` since 2026-08); `peers(eid)`
  is zero for all commonly used EIDs probed; bridge is effectively dormant. Not reachable unprivileged.
- **Token quirks**: MLUM = `MagicLumOFT` (custom OFTVotesPermit on OZ Votes/Permit, no custom mint exposed);
  LUM = `LumOFT` (owner-gated); 59% of LUM supply burned to `0xdEaD`.
- **History / incidents**: no MagicSea exploit/hack/incident found in web search; no anomalous large
  interactions found on the factory/pair surfaces checked.

## 5. Privileged surfaces (for completeness — H-O-2)

If any of these keys (EOAs `0x0cF8C42871d994C80B74564E3094CDCCF80CbE6A`, `0x7F76D5b3a33A87061b5184Ae9BD301d6b7333185`,
`0xE9b1d16dAEe0B4f1bb0a27136e000FEaC4c8638b`) is compromised, all live value is at risk:
LB factory (fee params, hooks, implementation for new pairs, fee recipient) · proxy upgrades of
MasterChefV2/Voter/MlumStaking/RewarderFactory · `MlumStaking.setEmergencyUnlock` (destroys lock multipliers) ·
V2 `feeToSetter`/`setFeeAmount` · OFT owner (peers/delegate).

## 6. PoC

`kava-iota-misc/poc/test/MagicSea.t.sol` — forks IOTA EVM at block 13020932 via the public RPC
(`vm.createSelectFork("https://json-rpc.evm.iotaledger.net", 13_020_932)`; no keys, no env deps) and:
1. `test_compositionFee_mintBurnRoundTrip_isNeverProfitable` — decodes the real `CompositionFees` event,
   asserts PnL ≤ 0 and loss ≤ composition fee for 3 sizes;
2. `test_compositionFee_ySideDeposit_isNeverProfitable` — asserts the Y-side case;
3. `test_collectProtocolFees_isGated` / `test_adminFeesAndHooks_areGated` — access-control evidence;
4. `test_compositionFee_path_isReachable` — proves the tested path executes (not a revert);
5. `test_livePoolState_snapshot` — records the live pool state used.

Local run (1 of ≤2 allowed): **6 passed, 0 failed**, 1.6 s (fork RPC aside). CI should re-run `forge test -vvv`.

## 7. Caveats / residual risk

- No exhaustive line-by-line review of the joe-staking fork (audited by Sherlock 06/2024, deployed after) or of
  the Merchant-Moe derived rewarder against its upstream repo (upstream not diffed). Value at stake there is
  ~$6–8k combined; an unnoticed claim-accounting bug would be bounded by that.
- The composition-fee delta is analysed as net-negative *at current pool state*; a much deeper active bin or a
  protocolShare of 0 on a future pool would change the magnitude (still ≤ fee-bypass, not a drain).
- Prices are point-in-time quotes; MLUM has no reliable oracle (pool-implied $0.005 used).
- Public-RPC archive depth: if `json-rpc.evm.iotaledger.net` prunes block 13020932 before CI runs, repin the
  fork block in the PoC (state reads are otherwise reproducible via `analysis/magicsea/state.json`).

## 8. Files

- `analysis/magicsea/findings.md` (this file)
- `analysis/magicsea/state.json` — raw reads, roles, provenance, PoC results, classification
- `analysis/magicsea/lb_pairs_state.json` — all 97 LB pairs at block 13020932 (reserves, tokens, quote USD)
- `analysis/magicsea/contracts/` — verified sources + ABIs used for the provenance diffs
- `poc/test/MagicSea.t.sol` — Foundry PoC (for CI)
