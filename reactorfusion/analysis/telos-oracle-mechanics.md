# ReactorFusion on Telos EVM — Oracle Mechanics (verified)

Research date: **2026-10-14** (read-only; no transactions signed/sent). All on-chain values were read via
`eth_call`/`eth_getStorageAt` against the public Telos RPC; sources were fetched from the Teloscan explorer
API (`api.teloscan.io`) and saved under `telos-sources/`. No secrets are included in this file.

Reference block for the snapshot: **493,954,038 (oracle prices) – 493,957,742 (market params) –
493,963,354 (account snapshots)** (Telos EVM head at probe time; see `telos-probe*.json` and
`telos-positions.json` for exact per-call blocks).

---

## 1. Executive summary

- The Comptroller/Unitroller `0x19646a04BfDcf3553Adc8fAAf8B16D76EC41E494` **does not use the Redstone
  `push()` oracle anymore**. Its oracle (slot 4 of Unitroller storage, `oracle()`) is
  **`0x0fa9de8362e662d6659a05ad284a2f454f49a8e2`**, a `SimplePriceOracle` (by "OmniDex") that reads a
  **DIA `DIAOracleV2`** contract at `0x86c5997d10d1df6cbb15c01280e596ed5ac90a33`.
- Oracle history (from `NewPriceOracle` events on the Unitroller; only two ever emitted):
  | # | Block | UTC time | old oracle | new oracle |
  |---|-------|----------|-----------|------------|
  | 1 | 313,919,449 | 2023-12-07 04:46:42 | `0x0000…0000` | `0x3b7023f3c99eae2fa0aaeb9490a78d5d98a24148` (Redstone demo push oracle) |
  | 2 | 387,669,171 | 2025-02-06 03:49:24 | `0x3b70…4148` | `0x0fa9de8362e662d6659a05ad284a2f454f49a8e2` (DIA oracle — current) |
- Price formula (verified source + on-chain behaviour):
  `getUnderlyingPrice(cToken) = dia.getValue(assetsKeys[cToken]).price * 10**(28 - cToken.decimals())`
  - DIA `getValue` returns an **8-decimal** fixed-point price.
  - In this fork `cToken.decimals() == underlyingDecimals` (USDC 6, USDT 6, ETH 18, TLOS 18 — verified
    on-chain), so the final scale is the Compound-standard **1e(36 − underlyingDecimals)**:
    **1e30 for USDC/USDT, 1e18 for ETH/TLOS**.
  - Therefore the raw `getUnderlyingPrice(rfTLOS)` value `19310470000000000` is **0.01931047 USD at 1e18
    scale** — *not* $19.31. The $19.31 reading is an off-by-1000 scale error.
- Feed keys and values (all read at block ~493.96M):

  | Market | DIA key | DIA value (8 dec) | DIA value (USD) | feed timestamp | age vs 2026-10-14 19:45 UTC |
  |--------|---------|-------------------|-----------------|----------------|------------------------------|
  | rfUSDC | `USDC/USD` | 99,974,455 | 0.99974455 | 2026-10-06 13:22:10 | 8.27 days |
  | rfUSDT | `USDT/USD` | 99,969,496 | 0.99969496 | 2026-10-06 13:21:40 | 8.27 days |
  | rfETH  | `ETH/USD`  | 261,620,618,299 | 2,616.20618299 | 2026-10-07 02:03:41 | 7.74 days |
  | rfTLOS | `TLOS/USD` | 1,931,047 | 0.01931047 | 2026-10-07 07:05:39 | 7.53 days |

- **No staleness check anywhere.** `SimplePriceOracle.getUnderlyingPrice` ignores the timestamp returned by
  DIA; the Comptroller never checks freshness; `DIAOracleV2.setValue` does not validate timestamps. Stale
  values persist and are used indefinitely (currently ~7.5–8.3 days old).
- **Update path is permissioned, not permissionless**: `DIAOracleV2.setValue(key,value,ts)` requires
  `msg.sender == oracleUpdater` = **`0x4b4c4a6e760fdea078efc6bea046946b639bddea`** (an EOA — no code — that
  is DIA's updater for this oracle; its most recent `setValue` was block 492,669,690 / 2026-10-07
  07:05:40 UTC). Simulated `eth_call` with `from` = random address or the oracle owner **reverts**;
  only `from` = updater succeeds. `updateOracleUpdaterAddress` is also updater-only.
- The old Redstone oracle (`0x3b70…4148`) is still deployed but **disconnected** from the Comptroller. It had
  a **permissionless `push(bytes32[])`** and a **1-of-1 Redstone demo signer**; that path is historical only
  (last active 2025-02-06). If the admin ever re-points the Comptroller back to it, the permissionless path
  becomes live again.
- **Unprivileged attacker price manipulation today: none found on-chain.** The only price-write paths are
  (a) DIA's updater EOA (key compromise = trust failure, not an unprivileged on-chain path), and (b) the
  oracle owner / Unitroller admin EOA `0x99999a3c4cb8427c44294ad36895b6a3a047060d`, which can
  `setDIAOracle(...)` to an arbitrary contract (or replace the oracle entirely via `_setPriceOracle` /
  upgrade the implementation). Both are privileged.

---

## 2. Contracts and roles (Telos, chain id 40)

| Role | Address | Notes |
|------|---------|-------|
| Unitroller (Comptroller proxy) | `0x19646a04BfDcf3553Adc8fAAf8B16D76EC41E494` | storage slots verified: admin slot0, impl slot2, oracle slot4, closeFactor slot5=1e18, liqIncentive slot6=1.08e18, whitelistedLiquidator slot20=0 |
| Comptroller implementation | `0xd4b18a93019ba2dd9d1ad0e66302730648be2b40` | verified `Comptroller` (Compound fork); emits Borrow/Repay/Liquidate events itself |
| Unitroller admin | `0x99999a3c4cb8427c44294ad36895b6a3a047060d` | **plain EOA**, no timelock on Telos |
| Current oracle | `0x0fa9de8362e662d6659a05ad284a2f454f49a8e2` | `SimplePriceOracle` (OmniDex, DIA-based); owner = the admin EOA |
| DIA oracle | `0x86c5997d10d1df6cbb15c01280e596ed5ac90a33` | `DIAOracleV2` (compiled 0.7.4); updater = `0x4b4c…bdea` |
| Old Redstone oracle | `0x3b7023f3c99eae2fa0aaeb9490a78d5d98a24148` | `SimplePriceOracle` + `MainDemoConsumerBase`; not wired |
| cToken markets | rfUSDC `0xa6a5…7ac2`, rfUSDT `0x3d18…d2be`, rfETH `0xce08…b1cd`, rfTLOS `0x7d94…ac5f` | rfTLOS = `CEther` (native TLOS); admin of all = the same EOA |

Market parameters (Comptroller `markets()` / storage):

| Market | listed | collateralFactor | cash (underlying) | totalBorrows (stored) | totalSupply (cTokens) | exchangeRateStored |
|--------|--------|------------------|-------------------|------------------------|------------------------|--------------------|
| rfUSDC | yes | 0.80 | 7.056647 | 17.192779 | 15.131029 | 1.600968579202379428 |
| rfUSDT | yes | 0.80 | 104.375982 | 146.090348 | 141.987846 | 1.754205004279028220 |
| rfETH  | yes | 0.70 | 0.120545382167356918 | 0.000769380621914005 | 0.117480414252320323 | 1.032638193875579297 |
| rfTLOS | yes | 0.70 | 11042.734467413018479963 | 313.265056088605140953 | 11032.657357105280575837 | 1.029240177926839007 |

Other Comptroller config: `closeFactorMantissa = 1e18` (**full-debt liquidation allowed**),
`liquidationIncentiveMantissa = 1.08e18`, `whitelistedLiquidator = address(0)` (**no liquidator whitelist** —
anyone may liquidate), borrow caps 0 (unlimited), `maxAssets` unused.

---

## 3. Exact mechanism — the current DIA oracle

### 3.1 `SimplePriceOracle` `0x0fa9de83…` (verified source, saved at `telos-sources/oracle/Main.sol`)

```solidity
contract SimplePriceOracle is Ownable, PriceOracle {
    mapping(CToken => string) public assetsKeys;
    IDIA public dia;                                  // IDIA: getValue(string) -> (uint128 price, uint128 ts)

    function setAssetKey(CToken cToken, string calldata key) external onlyOwner { ... }
    function setDIAOracle(address diaOracleAddress) external onlyOwner { dia = IDIA(diaOracleAddress); ... }

    function getUnderlyingPrice(CToken cToken) public view override returns (uint256) {
        (uint128 price,) = dia.getValue(assetsKeys[cToken]);   // <-- timestamp DISCARDED
        return price * (10 ** (28 - cToken.decimals()));
    }
}
```

On-chain `assetsKeys`: `rfUSDC→"USDC/USD"`, `rfUSDT→"USDT/USD"`, `rfETH→"ETH/USD"`, `rfTLOS→"TLOS/USD"`.
No timestamp/freshness logic exists in this contract.

### 3.2 `DIAOracleV2` `0x86c5997d…` (verified source; compiled with solc 0.7.4)

```solidity
contract DIAOracleV2 {
    mapping (string => uint256) public values;   // packed: (value << 128) + timestamp
    address oracleUpdater;                       // storage slot 1 (verified on-chain)

    function setValue(string memory key, uint128 value, uint128 timestamp) public {
        require(msg.sender == oracleUpdater);
        uint256 cValue = (((uint256)(value)) << 128) + timestamp;
        values[key] = cValue;
        emit OracleUpdate(key, value, timestamp);
    }
    function getValue(string memory key) external view returns (uint128, uint128) {
        uint256 cValue = values[key];
        return ((uint128)(cValue >> 128), (uint128)(cValue % 2**128));
    }
    function updateOracleUpdaterAddress(address newOracleUpdaterAddress) public {
        require(msg.sender == oracleUpdater); ...
    }
}
```

Verified on-chain:
- storage slot 1 = `0x4b4c4a6e760fdea078efc6bea046946b639bddea` (the only updater; EOA, no code).
- `eth_call setValue("TLOS/USD", 1, …)` from `0xdEaD…` → `execution reverted`; from the oracle owner EOA →
  `execution reverted`; from `0x4b4c…bdea` → success (`0x`). **Permissioned update confirmed by simulation.**
- The contract ABI exposes only `getValue`, `setValue`, `updateOracleUpdaterAddress`, `values`.

### 3.3 Update cadence and staleness

DIA's updater EOA called `setValue` on this oracle at least into 2026-10-07 (block 492,669,690,
ts 1791356740 = 2026-10-07 07:05:40 UTC — that tx set `TLOS/USD`). Since then, **no updates for ~7.5 days**
(and the USDC/USDT keys are ~8.3 days old, ETH ~7.7 days). Because no code checks timestamps, the protocol
still prices all four markets at the 2026-10-06/07 values.

### 3.4 The old Redstone oracle (historical, 2023-12-07 → 2025-02-06)

Verified source (`telos-sources/` from `0x3b70…4148`):

```solidity
contract SimplePriceOracle is PriceOracle, MainDemoConsumerBase {
    mapping(bytes32 => uint256) rawPrices;
    function push(bytes32[] memory tokens) external {                 // NO access control
        for (uint256 i = 0; i < tokens.length; i++) {
            rawPrices[tokens[i]] = getOracleNumericValueFromTxMsg(tokens[i]);
        }
    }
    function getUnderlyingPrice(CToken cToken) public view override returns (uint256) {
        return rawPrices[cToken.redStoneFeedID()] * (10 ** (28 - cToken.decimals()));
    }
}
```

- `getDataServiceId() = "redstone-main-demo"`, `getUniqueSignersThreshold() = 1`, the only authorised signer
  `0x0C39486f770B26F5527BBBf942726537986Cd7eb` (Redstone demo provider; private key not public).
- `push()` is callable by anyone, but it only accepts prices carried in a Redstone-signed calldata package
  that validates against that single signer. So it was "permissionless to submit, permissioned to sign".
- Not the Comptroller's oracle since block 387,669,171 (2025-02-06). Deployed but inert for pricing.

---

## 4. Live market comparison (2026-10-14 ~18:15–19:45 UTC)

| Asset | Oracle (stale DIA) | Live (source) | Oracle vs live |
|-------|--------------------|---------------|----------------|
| USDC | 0.99974455 | 0.99974701 (DefiLlama) | −0.000% |
| USDT | 0.99969496 | 0.99930840 (DefiLlama) | +0.039% |
| ETH | 2,616.20618299 | 2,425.77 (CoinGecko) / 2,437.51 (DefiLlama) | **+7.85% / +7.33%** |
| TLOS | 0.01931047 | 0.01895246 (CoinGecko) / 0.01896034 | **+1.89% / +1.85%** |

- The ETH feed is materially high (+7.3–7.9%): ETH fell after the last DIA update. Collateral in rfETH and
  debt in rfETH are therefore both overstated; for borrowers with rfETH collateral and non-ETH debt the
  effective LTV is *understated* by the oracle, i.e. positions may be more underwater at live prices than
  the protocol's own `getAccountLiquidity` shows.
- TLOS is ~1.9% high — a smaller but same-direction distortion for rfTLOS collateral.

### Cash available to withdraw (market `getCash`, converted at live prices)

| Market | Cash (underlying) | USD at live price |
|--------|-------------------|-------------------|
| rfUSDC | 7.056647 USDC | $7.06 |
| rfUSDT | 104.375982 USDT | $104.32 |
| rfETH | 0.120545382167356918 ETH | $293.85 (ETH=$2,437.51) |
| rfTLOS | 11042.734467413018479963 TLOS | $209.29 (TLOS=$0.01895246) |
| **Total** | | **≈ $614.5** |

(At the stale oracle prices the same cash is worth ≈ $640.0 — the ~$25 difference is mostly the ETH feed.)

---

## 5. Permissionless vs privileged paths (answers "can an unprivileged attacker move prices?")

1. **Current DIA oracle — no unprivileged on-chain path.** `setValue`/`updateOracleUpdaterAddress` are
   restricted to the updater EOA; `setAssetKey`/`setDIAOracle`/`transferOwnership` are `onlyOwner`. All
   verified in source and by `eth_call` simulation.
2. **Trust assumption that replaces it**: the DIA updater is a single EOA key
   (`0x4b4c4a6e760fdea078efc6bea046946b639bddea`). Whoever controls that key (DIA's infrastructure) can set
   arbitrary prices, unbounded by any on-chain sanity checks or timestamps. This is a key-compromise risk,
   not an unprivileged exploit path.
3. **Privileged paths** (admin EOA `0x99999a3c…060d`, no timelock on Telos):
   - `SimplePriceOracle.setDIAOracle(attackerContract)` → arbitrary prices (owner).
   - `SimplePriceOracle.setAssetKey(...)` → remap keys (owner).
   - `Unitroller._setPriceOracle(...)` / implementation upgrade (`_upgradeTo`) → total control (admin).
   - cToken `admin` (same EOA) → interest model, reserve factor, etc. (not prices).
4. **Historical**: the Redstone `push()` oracle was permissionless but signed by a single demo signer; it has
   been disconnected since 2025-02-06. Reactivating it (admin action) would restore a permissionless
   *submission* path whose prices still require a valid Redstone-demo signature.

---

## 6. Files / evidence

- Verified sources (explorer `getsourcecode`, including AdditionalSources):
  `telos-sources/comptroller_impl/`, `telos-sources/oracle/` (DIA-based `Main.sol`),
  `telos-sources/rfTLOS_ctoken/`, `telos-sources/rfUSDC_ctoken/`, `telos-sources/rfETH_ctoken/`,
  `telos-sources/unitroller/`, plus `telos-sources/_manifest.json`.
- Raw probes: `telos-probe1.json` (oracle type/scale), `telos-probe2.json` (DIA values/timestamps,
  oracle-switch block times), `telos-probe3.json` (storage slots, setValue simulation, ABIs),
  `telos-probe4.json` (market params/totals), `telos-probe5.json` (updater, update history).
- Oracle-switch logs: `NewPriceOracle` (topic0 `0xd52b2b9b…22e22`), 2 events total.
