# EtherFi Borrowing Market (Optimism) — ZH4 pass3 OPEN #2

**Date:** 2026-10-23 · **Chain:** Optimism (chain 10) · **Block:** 158,572,136 (fork) / 158,569,891 (live reads)
**Status:** read-only; PoC fork-verified only; **no mainnet transaction signed or sent**. No secrets.

> Aave V4 whitelabel instance ("Cash Spoke") powering ether.fi Cash. The pass3 recon flagged the
> **public-borrow path as untested** and the **RWA/stock price feeds as unproven**. This deep-dive
> resolves the Spoke address, reads the deployed source, fork-tests the borrow path, and audits every
> price source. **Result: the public-borrow path is contract-level gated to ether.fi Cash Safes and the
> RWA feeds are relay/Chainlink sourced (not OP-DEX-spot manipulable). Live unprivileged extraction = $0.**

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed | Latent risk |
|---|---:|---|---|
| Cash Spoke `borrow` | **$0** | `EtherFiSpokeInstance.borrow` requires `isEtherFiSafe(onBehalfOf)`; only the factory admin can create a Safe | Gate lives in an *upgradeable* Spoke impl (24h timelock) |
| LendGateway (only position manager) | **$0** | `borrow/withdraw/…` are `onlyDriver` (CashModule + admin-timelock drivers) | A future TakerPositionManager would break the "funds stay in Cash rails" invariant |
| RWA feeds (QQQx/SPYx/PAXG/TBLLx) | **$0** | `OracleSinkPriceFeed` reads a LayerZero relayed price (peer-gated to the mainnet PriceRelay); `ChainlinkPriceFeed` reads a Chainlink aggregator; `ERC4626RatePriceFeed` reads the issuer vault rate | 7-day `rateMaxStaleness`; a stalled relay reverts the reserve and can brick liquidations/withdrawals for that collateral |
| Permissionless liquidations | **$0** | No RWA-collateralised position is below HF 1 (all HF ≫ 1); liquidation itself requires HF < 1 | If an RWA feed ever de-pegs *down* while the market rose, safes could be liquidated at a stale-low price |

## 2. Total live extractable now: **$0** (confidence: **high**)

- **E-U = $0.** An external unprivileged attacker cannot borrow (gate), cannot drive the gateway (driver-only),
  cannot manipulate the RWA feeds on Optimism (relay/Chainlink sourced), and has no liquidatable position to seize.
- Supply side is permissionless but **non-extractive** (self-supply / self-withdraw; share accounting is
  donation-resistant).
- **P (privileged):** the whole ≈$318M supply sits behind upgradeable proxies (Spoke/Hub/LendGateway/OracleSink)
  governed by an `AccessManager`/`RoleRegistry` owned by an ether.fi timelock (24h). That is standard admin
  risk and is **not** counted as extractable.

## 3. The mechanism, in exact terms

### 3.1 The borrow gate (the "public borrow path")

Deployed Spoke proxy `0xdffcC3536D932eb51Df51a7F5FA407c4270d5308` → impl `0xa1f75d801633a1941cae6670352d627884dc3b68`
= **`EtherFiSpokeInstance`** (verified source, solc 0.8.28). It is the canonical Aave V4 `SpokeInstance`
with **one override**:

```solidity
address public constant ETHERFI_DATA_PROVIDER = 0xDC515Cb479a64552c5A11a57109C314E40A1A778;
error OnlyEtherFiSafe(address account);

function borrow(uint256 reserveId, uint256 amount, address onBehalfOf)
    public override returns (uint256, uint256)
{
    require(IEtherFiDataProvider(ETHERFI_DATA_PROVIDER).isEtherFiSafe(onBehalfOf),
            OnlyEtherFiSafe(onBehalfOf));
    return super.borrow(reserveId, amount, onBehalfOf);
}
```

- `isEtherFiSafe` → `EtherFiDataProvider` (proxy `0xDC515Cb4…A778`, impl `0x7b0c84e0…`) →
  `EtherFiSafeFactory` (proxy `0xF4e147Db…d8CF`) `deployedAddresses.contains(addr)`.
- `deployEtherFiSafe(...)` requires `ETHERFI_SAFE_FACTORY_ADMIN_ROLE` (role registry). An unprivileged caller
  **cannot mint a Safe**, so `isEtherFiSafe(attacker) == false` forever.
- Fork-verified: `borrow(0,1e6,attacker)` reverts `OnlyEtherFiSafe(0x1111…1111)`.

All position-mutating Spoke functions also require `onlyPositionManager(onBehalfOf)`
(`_isPositionManager(user,manager)` is true only for `user==manager` or an *active* manager with a per-user
approval). The **only active position manager is the LendGateway** `0x01F8cDFb…8E03F4`
(one `UpdatePositionManager` event in the Spoke's whole history, block 155,129,845). The LendGateway's
`borrow(safe,asset,amount,to)` is `onlyDriver` (`msg.sender == CashModule || isDriver[msg.sender]`), and the
CashModule's own `borrow` requires an owner-quorum EIP-191 signature and pays the borrowed funds to **the Safe**
(`gateway.borrow(safe, token, amount, safe)`), never to the caller.

### 3.2 The RWA/stock price feeds

The Spoke's oracle `0xe8cbd372…86fA8` maps each `reserveId` to an ether.fi `IPriceFeed` (all 8-decimal).
The RWA-collateral reserves and their feeds:

| # | Collateral | Supply | Feed | Type | Source of truth |
|---|---|---|---:|---|---|
| 19 | iwSPYx | 615.2 | `0x8b44f7Ac…` | `OracleSinkPriceFeed` | LayerZero relay from mainnet PriceRelay |
| 20 | iPAXG | 159.3 | `0xaC28d7fe…` | `ChainlinkPriceFeed` | Chainlink PAXG/USD (`rateFeed 0x977cd3bc…`) |
| 21 | iwQQQx | 136.3 | `0x7106e8D7…` | `OracleSinkPriceFeed` | LayerZero relay |
| 22 | iwTBLLx | 209.4 | `0x81D0305B…` | `OracleSinkPriceFeed` | LayerZero relay |
| 24 | iPAXGy | 83.4 | `0x9B92A2D4…` | `ChainlinkPriceFeed` | Chainlink |
| 26/27/28 | wSPYx/wQQQx/wTBLLx | 0 | `0xCC69…/0xEE10…/0xB526…` | `ERC4626RatePriceFeed` | issuer vault `convertToAssets` × underlying USD |

- `OracleSinkPriceFeed.latestAnswer()` reads `sink.latestRoundData(token)`; the **OracleSink**
  `0x7cb68ddc…8d42` (impl `0x06a126e6…`) accepts writes only through
  `OAppReceiverUpgradeable.lzReceive` with the **OnlyPeer** check. Live: `peers(30101) =
  0x…c4d666b44daa8d6d12b84875384e08bae52afe19` (the mainnet PriceRelay, contract present on mainnet),
  `paused() == false`. **No OP-DEX spot source exists for these feeds** — the fork test asserts the feed has
  no `slot0()`.
- Staleness: `rateMaxStaleness = 604,800 s (7 days)` on the RWA feeds; the sink additionally enforces its own
  per-token `maxStaleness`. A stale/absent price **reverts** (`StalePrice`/`PriceNotSet`), so the reserve's
  operations revert rather than mis-price.
- `ERC4626RatePriceFeed` carries no timestamp and "trusts the vault's issuer, whose multiplier updates move
  it"; those three reserves currently hold **0 supply**.

### 3.3 Why a fresh unprivileged caller cannot extract

1. **Cannot borrow** — gate (above). Even after self-supplying real USDC and enabling it as collateral, the
   fork test still reverts `OnlyEtherFiSafe`.
2. **Cannot drive the gateway** — `onlyDriver`.
3. **Cannot manipulate the RWA feed** — no local spot surface; the sink is LayerZero peer-gated.
4. **Cannot seize anything via liquidation** — `liquidationCall` requires `healthFactor < 1e18`; all
   RWA-collateralised safes read HF ≫ 1 (e.g. RWA_USER HF = 1.6236e18 in the fork test) and the call reverts
   `HealthFactorNotBelowThreshold`.
5. **Supply is open but non-extractive** — `Spoke.supply(reserveId,amount,self)` works (self is always a
   position manager); the Hub credits shares against its stored `liquidity`/`addedShares` index and requires
   `balanceOf(hub) >= liquidity`, so donations cannot inflate the share price.

## 4. Live state (block 158,569,891)

- **Hub** `0x66753c4e3fC84f1eD0e3C267C927284E9d90C572` (impl `HubInstance 0x697af342…`), 29 assets, 2 spokes
  per asset: the **Cash Spoke** and a **`TreasurySpokeInstance`** `0x7EB4d25F…0768` (owner-only
  supply/withdraw/transfer — not a borrow path).
- **Cash Spoke reserves: 29.** Borrowable: USDC(0), WETH(1), USDT(2), EURC(3), USD₮0(23). Full table +
  USD values: `analysis/reserves.json`.
- **On-chain totals (read):** ≈ **$317.8M supply / $40.8M debt** (DefiLlama: $300.6M/$43.2M). USDC debt
  $35.82M, WETH $1.12M, USDT $3.66M, EURC $0.18M.
- **Borrow activity:** 76 `Borrow` events, all in blocks 155,132,710–155,499,634 (2026-07/08), 31 unique
  borrowers, all in reserves 0/1. No Spoke logs in the latest 10k blocks (interest accrues in the Hub).
- **Collateral usage:** 2,298 `SetUsingAsCollateral` events / 1,849 users, incl. RWA reserves 19(14),20(22),
  21(2),22(1),24(8). None liquidatable.
- **Roles:** Spoke authority (AccessManager) `0x188d7173772499FB6375F23FdFd130CE6107286b`; Spoke/Hub/Lens
  proxy admins are the ether.fi timelock family (`0x9106cD76…` minDelay 172,800 s per ether.fi docs).
  LendGateway `minHealthFactor() = 1.1e18`, `paused() = false`.

## 5. PoC / fork verification

Foundry suite `poc/test/EtherFiBorrowing.t.sol` (forks Optimism at latest). **8/8 PASS** (local + CI).

| Test | Proves |
|---|---|
| `test_gate_borrow_reverts_OnlyEtherFiSafe` | direct `borrow` from a random EOA reverts the gate |
| `test_gate_attacker_is_not_a_safe_but_real_safe_is` | `isEtherFiSafe` discriminates attacker vs real Safe |
| `test_gate_supply_is_open_but_borrow_is_blocked` | attacker supplies 1,000 USDC, enables collateral, **still** cannot borrow |
| `test_gate_only_position_manager_is_lendgateway` | only the LendGateway is an active PM; its `borrow` reverts `OnlyDriver` |
| `test_rwa_feed_iwspyx_is_relay_not_dex_spot` | iwSPYx feed reads the peer-gated OracleSink; no `slot0()` |
| `test_rwa_feed_ipaxg_is_chainlink` | iPAXG feed reads a Chainlink aggregator, 7-day staleness |
| `test_no_liquidatable_rwa_position` | a real RWA-collateral safe is healthy; liquidation reverts |
| `test_second_hub_spoke_is_owner_only_treasury` | the 2nd Hub spoke is an owner-only treasury |

Gas: gate tests 62k–583k; liquidation check 1.66M (all reads).

**CI runs (GitHub Actions, public repo):** `https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39956777484`
(final, success) and `.../39955795395` — **8/8 forge tests PASS** (job `foundry tests`, fork block ~158,580,633).
The `ci/run.sh` job re-captured the live state (`ci-out/etherfi-borrowing-live.json`): `borrow` →
`0xe883803e` = `OnlyEtherFiSafe(0x1111…1111)`, LendGateway `borrow` → `0xdf95dcac` = `OnlyDriver()`,
`isEtherFiSafe(attacker)=false`, `isEtherFiSafe(safe)=true`, `isPositionManagerActive(LendGateway)=true`,
OracleSink peer set, sink not paused.

## 6. Verdict & residual/latent risk

**E-U $0 (high).** The public-borrow path is closed at the contract level and the RWA feeds are not
attacker-manipulable on Optimism.

Residual / latent (not extractable today):
- **Relay liveness / staleness:** a stalled LayerZero relay (or a token whose price ages past `maxStaleness`)
  makes `latestAnswer()` revert → `borrow/withdraw/liquidate` for positions holding that collateral revert.
  This is a DoS / bad-debt risk for the protocol, not attacker profit. The 7-day `rateMaxStaleness` is long.
- **Stale-low mis-pricing:** if the relay serves a price within the 7-day window while the market has risen,
  safes could be liquidated at a below-market oracle price (liquidator profit). This requires the relay to be
  *stale* — not attacker-triggerable.
- **Issuer-controlled `ERC4626RatePriceFeed`:** the three `w*x` reserves trust the issuer's multiplier; they
  hold 0 supply today.
- **Upgrade / position-manager invariant:** Spoke, Hub, LendGateway, OracleSink and the DataProvider are all
  upgradeable behind the ether.fi timelock. The whole "funds stay in Cash rails" property depends on no other
  position manager ever being activated (`updatePositionManager` is role-gated) and on the Spoke override
  surviving upgrades. Privileged risk.

## 7. Methodology & sources

- On-chain reads at block 158,569,891 via public Optimism RPC (`cast`/`eth_call`/`eth_getLogs`); deployed
  sources via Etherscan V2 chainid=10 (Spoke, Hub, LendGateway, EtherFiDataProvider, EtherFiSafeFactory,
  OracleSink, AaveOracle, price feeds). Fork PoC via Foundry 1.8.5 on GitHub Actions.
- Cross-checked against: ether.fi GitBook (Lending Market Parameters / Technical Documentation), the Aave
  ARFC "Deploy a Dedicated Aave V4 Whitelabel Instance fully managed by EtherFi on OP Mainnet", the Optimism
  blog (2026-08-13), and `etherfi-protocol/cash-v3` (PRs #183/#184).
- **The ether.fi Liquid `AtomicQueue` (Ethereum, 2026-09-11) is a *different* component and is prior-covered
  (ZH1 C-07 / incidents #42) — not re-audited here.**

**Caveats.** (1) The on-chain USD totals use the protocol's own 8-decimal oracle prices; DefiLlama differs
slightly. (2) "E-U $0" is scoped to *this* finding's surfaces (public borrow + RWA feeds + liquidations); the
broader ether.fi Cash multi-sig/card surface was only spot-checked. (3) Fork block is a moving target; the
gate and feed structure are stable, the exact price/debt numbers are point-in-time.

**Files:** `README.md` · `summary.json` · `analysis/reserves.json` · `analysis/gate-and-feeds.md` ·
`analysis/src_*/` (deployed sources) · `poc/` · `ci/run.sh` · `ci-out/` · `ci-log.txt`.
