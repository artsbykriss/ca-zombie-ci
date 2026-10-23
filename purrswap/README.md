# A2 — PurrSwap (Abracadabra) on HyperEVM: factory oracle validation / stale-`_I_`

**Date:** 2026-10-23 · **Chain:** HyperEVM (chainid 999) · **Status:** read-only research;
PoC **fork-verified only**; **no mainnet transactions sent**.

Guardian findings covered: **C-06** *No Validation For Oracles Used In Pools* (CRITICAL, ACKNOWLEDGED),
**C-07** *Wrong initial target updates* (CRITICAL, ACKNOWLEDGED), **H-02** *PurrLP Cannot Be Used
Without An Oracle* (HIGH, ACKNOWLEDGED), **M-06** *Absence of Oracle Will Lead To Stale `_I_`*
(MEDIUM, ACKNOWLEDGED). Source: `github.com/GuardianAudits/Audits` →
`AbracadabraMoney/2025-03-29_AbracadabraMoney_PurrSwap_Balancer_Aggregator.pdf`.

---

## 1. TL;DR

| target | live extractable (unprivileged) | why closed / open | latent risk |
|---|---|---|---|
| `Factory.create()` with arbitrary oracle (C-06) | **$0** | permissionless by design (M-03 ack.); a malicious pool only harms whoever voluntarily LPs into it — no shared/protocol liquidity to drain | **open mechanism**, no live victim |
| 2 live PurrLP pools, frozen `_I_` (H-02 / M-06) | **$0** | both pools hold dust (≈$0 and ≈$0.078); no capital to arbitrage | ~2.64% permanent mispricing on pool 2, irrelevant at dust size |
| `buyShares` wrong initial targets (C-07) | **$0** | requires an LP to seed a pool with a non-1:1 ratio; only dust ever seeded | open mechanism, no live victim |
| dust in the 2 live pools | **H-O ≈ $0.078** | recoverable only by the LP who deposited it (self-service `sellShares`) | — |
| Factory `implementation` / `_I_` / `_ORACLE_` | **P** (owner only) | `setLpImplementation` is `onlyOwner` (Abracadabra safe); no per-pool setters exist | owner can point factory at a new impl |

**Total live extractable now: $0.00 (E-U) — confidence HIGH.**

---

## 2. Total live extractable now

**$0.00 external-unprivileged**, at HyperEVM block **49,292,001** (2026-10-23).

Breakdown by category (see §8):

| category | USD | note |
|---|---|---|
| **E-U** (external unprivileged) | **0.00** | nothing to extract from the two dust pools; no shared liquidity |
| **H-O** (holder-only) | **0.078** | the single LP of pool 2 can withdraw its own dust |
| **P** (privileged) | 0.00 | owner can swap the factory implementation (no funds involved) |
| **S** (stuck) | 0.00 | pool 1's 639 wei WHYPE + 20535 wei KEI are unredeemable but worth ≈$0 |

The mechanism behind C-06/H-02/M-06 is **live** (proven below) but has **no live victim funds**,
so the extractable headline is $0.

---

## 3. The bug / mechanism, in exact terms

PurrSwap is an Abracadabra fork of DODO's PMM (`MagicLP` → `PurrLP`). A pool's target price `i` is
either read from an external oracle or, if none is set, from a value frozen at initialization.
The deployed code has three properties that, together, produce the audited findings:

**(a) `Factory.create()` accepts any oracle — no validation (C-06).** Deployed
`Factory.sol` (verified, block 49,292,001):

```solidity
function create(
    address baseToken_,
    address quoteToken_,
    uint256 lpFeeRate_,
    uint256 i_,
    uint256 k_,
    address oracle_
) external returns (address clone) {
    address creator = msg.sender;

    bytes32 salt = _computeSalt(creator, baseToken_, quoteToken_, lpFeeRate_, i_, k_, oracle_);
    clone = LibClone.cloneDeterministic(address(implementation), salt);
    IPurrLP(clone).init(address(baseToken_), address(quoteToken_), lpFeeRate_, i_, k_, oracle_);

    emit LogCreated(clone, baseToken_, quoteToken_, creator, lpFeeRate_, i_, k_);
    _addPool(creator, baseToken_, quoteToken_, clone);
}
```

There is **no `onlyOwner`, no whitelist, no `require` on `oracle_`**. Guardian C-06, verbatim:

> External oracles were introduced to the PMM as a way to obtain the i value … When creating a pool,
> the deployer provides an oracle address. However, there is no validation for the oracle address
> provided, representing a significant security risk, as a malicious oracle can manipulate the i value
> and control pricing. … **RESOLUTION** Status: Acknowledged.

**(b) `getEffectiveI()` returns the frozen `_I_` when `oracle == address(0)` (H-02 / M-06).**
Deployed `PurrLP.sol`:

```solidity
function getEffectiveI() public view returns (uint256) {
    if (_ORACLE_ != address(0)) {
        uint256 i = IPurrLPOracle(_ORACLE_).price(address(_BASE_TOKEN_));
        if (i == 0 || i > MAX_I) {
            revert ErrInvalidI();
        }
        return i;
    } else {
        return _I_;                    // <-- frozen forever; no setter exists
    }
}
```

`_I_` and `_ORACLE_` are written **only** in `init()` and there is no `setParameters`/oracle setter
on the pool, so once `init` runs with `oracle = 0` the pool price is **permanently** the
initialization ratio. Guardian M-06, verbatim:

> If a new PurrLP pool is deployed without specifying an oracle, the _I_ value remains the static
> ratio defined at initialization. Because asset prices typically evolve in real time, that constant
> _I_ quickly becomes inaccurate relative to the market. This inaccuracy leads to large arbitrage
> opportunities or perpetual mispricing in the pool. … **RESOLUTION** Status: Acknowledged.

**(c) `buyShares()` initial target update uses a 1:1 assumption (C-07).** Deployed `PurrLP.sol`:

```solidity
function buyShares(address to) external nonReentrant onlyClones returns (uint256 shares, uint256 baseInput, uint256 quoteInput) {
    ...
    uint256 _i = getEffectiveI();
    if (totalSupply() == 0) {
        // case 1. initial supply
        if (quoteBalance == 0) { revert ErrZeroQuoteAmount(); }
        shares = quoteBalance < DecimalMath.mulFloor(baseBalance, _i)
            ? DecimalMath.divFloor(quoteBalance, _i) : baseBalance;
        _BASE_TARGET_ = shares.toUint112();
        _QUOTE_TARGET_ = DecimalMath.mulFloor(shares, _i).toUint112();
        ...
    }
    ...
    _setReserve(baseBalance, quoteBalance);   // reserves := raw balances
    _adjustTarget(_i);
}
```

```solidity
function _adjustTarget(uint256 _i) internal {
    if (PMMPricing.RState(_RState_) == PMMPricing.RState.BELOW_ONE) {
        _QUOTE_TARGET_ = Math._SolveQuadraticFunctionForTarget(_QUOTE_RESERVE_, _BASE_RESERVE_ - _BASE_TARGET_, _i, _K_).toUint112();
    } else if (PMMPricing.RState(_RState_) == PMMPricing.RState.ABOVE_ONE) {
        _BASE_TARGET_ = Math._SolveQuadraticFunctionForTarget(_BASE_RESERVE_, _QUOTE_RESERVE_ - _QUOTE_TARGET_, DecimalMath.reciprocalFloor(_i), _K_).toUint112();
    }
}
```

Guardian C-07, verbatim:

> if the ratio used in buyShares is not 1:1, then R_STATE will be set to ONE. During the initial mint,
> _setReserves() will also set the base and quote reserve to the raw contract balance of these tokens,
> resulting in a R = 1 state even though the targets don't match the reserves. This leads to wrong
> target updates used for swap calculations and users receiving more or less from the token they are
> swapping … **RESOLUTION** Status: Acknowledged.

---

## 4. Live-state assessment

All reads at **HyperEVM block 49,292,001** via the keyless public RPC `https://rpc.hyperliquid.xyz/evm`.

### 4.1 Factory — `0x802762e604CE08a79DA2BA809281D727A690Fa0d` (verified "Factory")

| call | result |
|---|---|
| `implementation()` | `0x76DA31D7C9CbEAE102aff34D3398bC450c8374c1` |
| `owner()` | `0xfB3485c2e209A5cfBDC1447674256578f1A80eE3` (Abracadabra safe) |
| `LogCreated` events (topic0 `0x2a0061…`, full range) | **2** |

The two `LogCreated` events are the complete pool set (all factory events = 6 total: 2 `LogCreated`,
2 `LogPoolAdded`, 2 `OwnershipTransferred`). So exactly **2 PurrSwap pools exist**:

### 4.2 Pool 1 — `0x4E90767E92E58170F6732a7Fa652e03B82e5bb44` "PurrLP WHYPE/KEI"

| call | result |
|---|---|
| `version()` | `PurrLp 1.0.0` |
| `_BASE_TOKEN_` / `_QUOTE_TOKEN_` | `0x5555…5555` (WHYPE) / `0xB5fE77…620C` (KEI) |
| `_ORACLE_` | `0x0000000000000000000000000000000000000000` |
| `_I_` / `getEffectiveI()` | `15000000000000000000` (`15e18`) — frozen |
| `_K_` | `100000000000000` |
| `getReserves()` | `639` WHYPE wei / `20535` KEI wei |
| `totalSupply()` / `balanceOf(0x0)` | `1001` / `1001` → **only dead shares, never seeded** |
| USD | ≈ **$0** (639 wei WHYPE ≈ $5e-14; KEI unpriced) |

### 4.3 Pool 2 — `0x7B3959da5d74648Af48B8D69e19ea6a9812cdFDB` "PurrLP wstHYPE/WHYPE"

| call | result |
|---|---|
| `version()` | `PurrLp 1.0.0` |
| `_BASE_TOKEN_` / `_QUOTE_TOKEN_` | `0x94e8396e0869c9F2200760aF0621aFd240E1CF38` (wstHYPE) / `0x5555…5555` (WHYPE) |
| `_ORACLE_` | `0x0000000000000000000000000000000000000000` |
| `_I_` / `getEffectiveI()` | `1000000000000000000` (`1e18`) — frozen |
| `_K_` | `100000000000000` |
| `getReserves()` | `205894732490150` wstHYPE wei / `784470920903961` WHYPE wei |
| `totalSupply()` | `495147544163278` (`1001` dead + `495147544162277` to the LP) |
| LP holder | `0x1453Acb73B4c13BCE00496Ae00DdC7E4cF484C6c` (EOA, all real shares) |
| USD (DefiLlama 2026-10-23) | ≈ **$0.0782** (0.00020589 wstHYPE @ $80.5857 + 0.00078447 WHYPE @ $78.5165) |

Both pools: `_ORACLE_ == address(0)` ⇒ `getEffectiveI() == _I_` (stale). Confirmed there is no
`setParameters`/oracle setter: calls to `setParameters(...)` and `setOracle(...)` revert (see PoC).

### 4.4 Frozen vs market price (stale-price magnitude)

For pool 2, the frozen `i = 1.0`; the market ratio wstHYPE/WHYPE from DefiLlama is
`80.5857 / 78.5165 = 1.02635` → a **~2.64% permanent mispricing** (proven in the PoC via
`querySellBase`). At the pool's dust size this is worth ≈$0.002 even if fully arbitraged.

### 4.5 Negative / distinct (not counted)

A **separate** Abracadabra **MIMSwap / MagicLP** factory exists on HyperEVM at
`0xc8f5eb8a632f9600d1c7bc91e97dad5f8b1e3748` (impl `0xD6b8bd85A9593cb47c8C15C95bbF3e593c5Dc591`,
owner = the same safe). Its pools report `MagicLP 1.0.0` and are empty. **Different product — not
conflated with PurrSwap and not counted here.**

---

## 5. What an attacker can / cannot do

**Can (fork-proven, no privileges):**

1. **Create a pool with an arbitrary oracle** — `Factory.create(base, quote, lpFeeRate, i, k, oracle)`
   from any EOA. In the PoC an attacker deployed a mock oracle and created a pool with
   `getEffectiveI()` freely settable to `1e18 → 5e18 → 0.01e18`; a second pool was created with a bare
   EOA oracle (`0xdead`). Cost: gas only.
2. **Read a permanently stale price** on both live pools (`_ORACLE_ == 0` ⇒ `getEffectiveI() == _I_`).

**Cannot (why E-U = $0):**

- **Extract anything from the two live pools.** They hold ≈$0 and ≈$0.078 respectively; pool 1 has
  only dead shares. There is no profitable arbitrage at dust liquidity.
- **Force a victim into a malicious pool.** `Factory.create` is permissionless by design (M-03 ack.);
  the pool's liquidity and pricing only affect parties who **voluntarily** LP into or trade that pool.
  There is no protocol-owned liquidity, no router that routes users into attacker-created pools, and
  no shared vault. The C-06/C-07 harm is opt-in.
- **Change `_I_`/`_ORACLE_` on an existing pool** — no setters exist; they are written only in `init`.
- **Drain pool 1's stuck reserves** — no redeemable LP shares exist (`totalSupply == 1001`, all `0x0`).

**Preconditions / costs:** none beyond gas; the fork PoC shows the create path succeeds with no
capital. A malicious pool is a *setup* an attacker can always do, but it yields no third-party funds.

---

## 6. PoC / fork verification

**Files:** `poc/foundry.toml`, `poc/test/PurrSwap.t.sol` (single self-contained suite; HyperEVM fork
at block `49,292,001` via `vm.createSelectFork(vm.envOr("HYPER_RPC_URL", "https://rpc.hyperliquid.xyz/evm"))`).
**Read-only:** no broadcasts, no signatures, no state written to mainnet.

**Tests: 5 / 5 PASS** (see CI run URL below).

| test | proves |
|---|---|
| `test_C06_factoryCreate_noOracleValidation` | permissionless `create()` with a mock oracle; attacker sets `i` freely; second arbitrary oracle (`0xdead`) also accepted; both registered |
| `test_H02_M06_livePools_haveFrozenI` | both live pools `_ORACLE_ == 0`, `getEffectiveI() == _I_`; no `setParameters`/`setOracle` |
| `test_stalePrice_frozenIVsMarketI` | `querySellBase(1e12)` @ frozen `i` = `1000375559624` vs @ market `i` = `1026738686015` (≈2.64% higher) |
| `test_livePools_holdDustOnly` | pool1 < $1 (in fact ≈$5e-14), pool2 ≈$0.078; pool1 `totalSupply == 1001` dead shares |
| `test_HO_lpCanSelfWithdrawDust` | the single LP of pool 2 self-withdraws its dust (H-O) |

Key logged numbers: pool2 USD `78186098225524250` (1e18 fp = $0.0782); LP withdrew
`205894732489733` wstHYPE + `784470920902375` WHYPE.

**CI:** see `ci-log.txt` and `ci-artifacts/`; the custom job `ci/run.sh` also writes
`ci-out/live-state-ci.json`. Run URL:

- **CI run:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39923651312 (5/5 PASS)

---

## 7. Verdict and residual / latent risk

**Verdict: no live external-unprivileged extraction. E-U = $0.00, confidence HIGH.**

- The audited mechanisms (C-06 no oracle validation; C-07 wrong initial targets; H-02/M-06 stale `_I_`)
  are **confirmed live** in deployed code and reproducible on a fork — but they have **no live victim
  funds**. Harm is opt-in to a maliciously/naively created pool.
- **Residual / latent risk:** if the Abracadabra team or any third party were to seed a PurrSwap pool
  (via `Factory.create` with `oracle = 0`) with real liquidity, that pool would be permanently priced
  at its initialization ratio and **arbitrageable at ~the full market/frozen deviation**. Any LP
  joining such a pool also eats the C-07 target-update error. This is a design-level exposure, not a
  present fund loss.
- **Privileged:** the factory owner (Abracadabra safe) can change `implementation` (`setLpImplementation`,
  `onlyOwner`). No funds are exposed by this.
- **Blockers for an attacker:** none needed — there is simply nothing to take.

---

## 8. Categories

| category | USD | detail |
|---|---|---|
| **E-U** | **0.00** | no live victim funds; permissionless creation is by design (M-03 ack.) |
| **H-O** | **0.078** | pool 2's sole LP can `sellShares` its own dust |
| **P** | 0.00 | owner can swap factory implementation (no funds) |
| **S** | 0.00 | pool 1's stuck reserves are worth ≈$0 |

---

## 9. Methodology, caveats, files

**Method.** Event-based enumeration (global `LogCreated` scan → exactly 2 pools), Etherscan-V2
verified-source review, `eth_call`/`cast` reads at a pinned block, DefiLlama pricing, and a
fork-only Foundry PoC. No mainnet writes.

**Caveats.**
- `KEI` is unpriced; pool 1 uses a deliberately generous $1/KEI upper bound and is still < $1e-12.
- Figures are a snapshot of block 49,292,001; USD moves only with HYPE price.
- Fork tests run against the keyless public RPC; the CI job uses the same public endpoint.
- The distinct MIMSwap/MagicLP factory (§4.5) is explicitly excluded.

**Files.**
```
purrswap/
├── README.md                     # this file
├── summary.json                  # machine-readable summary
├── analysis/
│   ├── live-state.json           # full state dump (block 49,292,001)
│   ├── notes.md                  # method + negative results
│   ├── guardian-quotes.md        # verbatim C-06/C-07/H-02/M-03/M-06
│   └── src/                      # extracted verified sources (factory/, purrlp/)
├── poc/
│   ├── foundry.toml
│   ├── test/PurrSwap.t.sol       # 5/5 PASS
│   └── lib/forge-std/
├── ci/run.sh                     # custom CI job -> ci-out/live-state-ci.json
├── ci-out/
├── ci-log.txt
└── ci-artifacts/
```
