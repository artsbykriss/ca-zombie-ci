# HashMix FIL pool `0x587A7eaE9b461ad724391Aa7195210e0547eD11d` — on-chain discovery

**Chain:** Filecoin FEVM (chain id 314) · **Investigator:** read-only subagent · **Latest block used for value reads:** `6,457,049` (`0x6286d9`) unless stated otherwise · **Date:** 2026-10-14/15

---

## 0. Headline finding — the address does NOT hold "stFIL"

- `0x587A7eaE9b461ad724391Aa7195210e0547eD11d` **is** the HashMix FIL Liquid Staking pool / liquidity token itself. Its on-chain ERC-20 `name()` = `symbol()` = **"cWFIL"** (18 decimals), and it holds native FIL directly (`underlying()` = `address(0)`, i.e. native FIL, not WFIL and not stFIL).
- HashMix's **own** docs confirm the address: *"For every FIL you deposit into the HashMix FIL Liquid Staking pool, you'll receive ... We call it cWFIL. ... The cWFIL token address is 0x587A7eaE9b461ad724391Aa7195210e0547eD11d."* (https://hashmix.gitbook.io/hashmix-fil-liquid-staking/liquidity-token, saved `gitbook_liquidity-token.md`).
- DeFiLlama lists the protocol as **"HashMix FIL"**, symbol **`cWFIL`**, Filecoin, category Liquid Staking, listed 2023-05-31 (`llama_hashmix.json`, saved).
- **`stFIL` is a different protocol** (STFIL DAO, stfil.io — it suffered the April 2024 incident; unrelated to HashMix). There is no HashMix⇄stFIL on-chain linkage (see §2).
- HashMix launched a **successor V2 pool** `0x85e77391C3dDe4fee572A79CFef7f710c7476f82` (also named cWFIL, controller `0x10D81c7a…`) on 2023-09-01 — see §5b. The audited V1 pool studied here is the one at the target address.
- The contract is **unverified on Blockscout** (`is_verified:false`) **and not verified on Sourcify** (v2 `match:null`), but its code is an identifiable **Compound-v2 cToken fork** (strings: `CErc20::sweepToken: can not sweep underlying token`, `borrow rate is absurdly high`, `borrowBehalf`, `need some FIL`, `FIL is not allowed`, `TOKEN_TRANSFER_OUT_FAILED`, `ERC20Permit:`; solc 0.8.18; dispatcher selectors match Compound cToken ABI, see §7).
- CertiK audit of HashMix (Filecoin, Solidity), delivered **2023-06-07**, codebase `github.com/HashMixProject/hashmix-fevm` (now 404/private) — `hashmix_audit_2023.pdf`, `hashmix_audit_text.txt`. Deployment (2023-05-23) and DeFiLlama listing (2023-05-31) bracket this audit.

---

## 1. Core pool facts (all values at block 6,457,049 / hex `0x6286d9`)

| Item | Value | Source |
|---|---|---|
| Address | `0x587A7eaE9b461ad724391Aa7195210e0547eD11d` | — |
| Filecoin actors | `f02200067` (evm), robust `f410flb5h5lu3iynnojbzdktrsuqq4bkh5ui5druq3pq` | Blockscout v2 `/addresses/...` |
| ERC-20 name/symbol/decimals | `cWFIL` / `cWFIL` / 18 | `eth_call` |
| Runtime code size | **22,338 bytes** (44,676 hex chars) | `eth_getCode`, `pool_0x587A_code.hex` |
| Native FIL balance | **1,581.864473017953114284 FIL** (`0x55c0c78d21f59558ac`) | `eth_getBalance` |
| `getCash()` | 1,581.864473017953114284 FIL (identical) | `eth_call 0x3b1d21a2` |
| `totalSupply()` | **102,637.9610674784 cWFIL** (`0x15bc03d83fa5cec9f743`) | `eth_call 0x18160ddd` |
| `exchangeRateStored()` | **0.010709353782224222 FIL per cWFIL** (`0x260c19bbf6a55e`) | `eth_call 0x182df0f5` |
| `initialExchangeRateMantissa()` | 0.01 FIL (start value) | `eth_call 0x675d972c` |
| Appreciation since launch | **+7.09 %** (0.01 → 0.0107093) | derived |
| `totalReserves()` | **482.678236460185 FIL** (protocol-owned) | `eth_call 0x8f840ddd` |
| `totalBorrows()` | 0.000000014207457 FIL (≈dust) | `eth_call 0x47bd3718` |
| `borrowIndex()` | 1.204951118210162 | `eth_call 0xaa5af0fd` |
| `reserveFactorMantissa()` | 5 % | `eth_call 0x173b9904` |
| `protocolSeizeShareMantissa()` | 2.8 % | `eth_call 0x6752e702` |
| `accrualBlockNumber()` | **3,678,820** = 2024-02-23 (frozen since last tx) | `eth_call 0x6c540baf` |
| `underlying()` | `0x000…000` (= **native FIL**) | `eth_call 0x6f307dc3` |
| `controller()` | `0xFA33F3866e7eF32F79734BCC5e011d767F8E574b` | `eth_call 0xf77c4791` |
| `interestRateModel()` | `0xE1DACa5a43DADd1b4db972d5d3a66eCF9960Eb81` | `eth_call 0xf3fdb15a` |
| `feeCollector()` | `0xD59060790f28EcD10Be2d23cEc88a39461A8d0cd` (EOA) | `eth_call 0xc415b95c` |
| EIP-1967 impl slot `0x360894…2bbc` | `0x0` → **not a proxy** | `eth_getStorageAt` |
| EIP-1967 admin slot `0xb53127…6103` | `0x0` → not a proxy | `eth_getStorageAt` |

**Value reconciliation (exact):** holders' claim = 102,637.9610674784 × 0.010709353782224222 = **1,099.186236557782 FIL**; + reserves 482.678236460185 FIL = **1,581.864473017967 FIL**, matching `getCash` to 1.4e-11 FIL. The 1,581.86 FIL in the contract is therefore **not unowned**: 1,099.19 FIL backs outstanding cWFIL, 482.68 FIL is protocol reserves (withdrawable by the protocol via `_reduceReserves`). Implied lifetime interest earned by the pool ≈ 482.678/0.05 ≈ **9,654 FIL**.

---

## 2. `stFIL` tokens — and why they are NOT this pool

Searched Blockscout tokens (`q=stFIL`, `q=HashMix`): two `stFIL` tokens exist; neither is HashMix and the pool holds **0 stFIL** (`balanceOf(pool)=0` at block 6,457,049) and never interacted with them (all counterparties are EOAs, §4).

| Token | Address | Notes |
|---|---|---|
| "Staked FIL" (stFIL) | `0x3C3501E6c353DbaEDDFA90376975Ce7aCe4Ac7a8` | EIP-1967 proxy (2,096 B); impl slot = `0xF1eca87AC159a1132554124A89f4778100cc0ecc` (8,800 B); admin slot = `0xC55e40977a782a0ea221812b9f01203effac71a1`; `name()="Staked FIL"`, `symbol()="stFIL"`, supply **5,541,237.27**; 1,134 holders; created 2023-04-09 block **2,757,517** by EOA `0xFdD15B1A6ac02823b0A9c2d65D8f124Ff5A2bDaf` (`f02117105`, separate team/protocol — DeFiLlama lists "STFIL" as a *competing* protocol). |
| "Infinity Pool Staked FIL" (stFIL) | `0xd632a8ECe5a5ef690eDdd0847e70c39daF5FBa07` | 1 holder, supply 2.0 — test/imitation. |

---

## 3. Deployment info for the pool

| Field | Value |
|---|---|
| Creation tx | `0x83a8560405a85fb8dc394f3ec98dee391c25181ee2594f58cbe4d715b43dc676` |
| Block / time | **2,883,861** / 2023-05-23T06:10:30Z |
| Creator | `0x06A4c6527fD462c4fD55664861437bC6D417FFA3` (EOA `f02199056`, robust `f410fa2smmut72rrmj7kvmzegcq33y3kbp75dv5o4mai`), tx nonce **13**, gas used 172,360,357, status ok |
| Constructor args (decoded from creation bytecode tail) | `(address(0) /*underlying = native FIL*/, 0xFA33F3866e7eF32F79734BCC5e011d767F8E574b /*controller*/, 0xCF89b3A29499229E35d4fe71dFE54BEC2C1EbA48 /*EOA, privileged — called _reduceReserves*/, 0xE1DACa5a43DADd1b4db972d5d3a66eCF9960Eb81 /*interestRateModel*/, 10000000000000000 /*initialExchangeRateMantissa*/, "cWFIL", "cWFIL")` |
| Solidity | **0.8.18** (creation-code trailer `...64736f6c63 43 000812 0033`; EIP-712 domain version "1") |
| Verified? | Blockscout: no · Sourcify: no (`match:null`) · Filfox: unreachable |

Same deployer created the surrounding protocol suite (paginated in `deployer_txs.json`, `deployer_txs_p2.json`), incl. controller proxy `0xFA33…` (block 2,883,636), IRM `0xE1DA…` (block 2,883,638), proxy-admins `0x13ce…` / `0x45D000…`, and kept upgrading them (**last upgrade 2025-04-11, tx to `0x45D000319ac5BcBbf4C76799FbFd3045EBBE9b09` upgrading `0x10D81c7a…` to impl `0x8f468C3e8A124376272F4042858a302c1634D5bc`**).

---

## 4. Activity — complete pool history (282 transactions, none since 2024-02-23)

Full raw list: `raw_pool_txs_paged.json` (6 pages, 282 items, 2023-05-23 → 2024-02-23). Per-method stats:

| Method selector | Resolved name | Calls | First seen | Last seen | FIL paid in (msg.value) |
|---|---|---|---|---|---|
| `0xa0712d68` | `mint(uint256)` payable, native FIL deposit → cWFIL | 172 | 2023-05-23T08:33 (blk 2,884,146) | 2024-01-08T03:10:30 (blk 3,545,901) | **225,042.9545 FIL** |
| `0xdb006a75` | `redeem(uint256)` (cWFIL → FIL) | 56 | 2023-05-23T08:42:30 (blk 2,884,165) | **2024-02-23T06:50 (blk 3,678,820)** | 0 |
| `0x852a12e3` | `redeemUnderlying(uint256)` (exact FIL out) | 48 | 2023-05-23T08:35 (blk 2,884,150) | 2024-01-01T00:15 (blk 3,525,390) | 0 |
| `transfer` (plain native) | donation transfers into pool | 2 | 2023-06-30 (blk 2,994,282) | 2023-06-30 (blk 2,994,309) | — |
| `0xa9059cbb` | `transfer(address,uint256)` (cWFIL transfer) | 1 | 2023-06-09 (blk 2,932,957) | same | 0 |
| `0xa6afed95` | `accrueInterest()` (by deployer) | 1 | 2023-05-29 (blk 2,901,474) | same | 0 |
| `0x601a0bf1` | `_reduceReserves(uint256)` (by `0xCF89…`, 60.45 µFIL) | 1 | 2023-05-26 (blk 2,892,595) | same | 0 |
| — | contract creation | 1 | 2023-05-23 (blk 2,883,861) | same | 0 |

- **Last 12 months: zero function calls** (last activity 2024-02-23; `accrualBlockNumber` frozen at 3,678,820).
- Last tx = `0xead2eae4f186f2432c079279a2af078b6359e5a844285c89b2955eda2b971e5f`: `redeem(0x010e0228ba4714721c)` = 19.456158120715514 cWFIL by `0x0440fad163462641F61787BAA018f2336871f761`, receiving ~0.2084 FIL.
- Full cWFIL transfer log: 277 rows (171 mints / 103 burns / 3 transfers) in `raw_cwfil_transfers_paged.json`. Total minted 22,136,226.42 cWFIL / burned 22,033,588.49 cWFIL (net = 102,637.96 = totalSupply exactly). **Note:** Blockscout's transfer index contains **3 duplicated rows** (tx `0xd5840004…`, block 2,912,981, `0x15723119…` +100,641.56; tx `0xad84ea67…`, block 2,915,641, `0x4c2231B6…` +998.105; tx `0x624a4703…`, block 2,909,881, `0x189eAd67…` +399.531); deduplicated net reconciles perfectly.
- Native balance trajectory (`raw_pool_coin_balance_history.json`, 18 recorded changes): jumped to 78,311.19 FIL on 2023-12-27 (blk 3,512,116, large FIL inflow), peaked ~113,310.97 FIL on 2024-01-08, then large redemptions 2024-01-08 (−39,452), 2024-01-14 (−58,864), 2024-02-21 (−13,077) leaving 1,581.86 FIL.
- Counterparties: **51 unique addresses = the pool itself + 50 EOAs** (own batched `eth_getCode` at the latest block: every from/to counterparty of every pool tx has zero code). No contract-to-contract traffic into or out of the pool. Top users: `0x06801E1eE94564198F720910dE61ec304a03F7c3` (29 tx), `0xF55BbA49c2d33492Ff08Fbbaf2F08db38acB23F7` (24), `0xD59060790f28EcD10Be2d23cEc88a39461A8d0cd` (20, protocol ops wallet, minted ≈34,560 FIL), `0x92Fbb9Fc50074ACAb80554ccF4b19646bFDB8f00` (19), `0x21B659F156d26915849e5607F4262e6FbCe124E9` (17), `0x189eAd671C5C08000510b6B79e6e12F1413A320C` (14), `0x106a984153Ac6b5767B5A796C0BbEf9AB706022a` (14), `0x65c8d65F808D451b0d750C5EA7Ed6455b421a01e` (12) (`pool_counterparties.json`).

### Current cWFIL holders (complete set; verified by `balanceOf`, sums exactly to `totalSupply`)

| # | Address | cWFIL | FIL value @ 0.01070935 |
|---|---|---|---|
| 1 | `0x256fA19F49661d166D58d9CF8D23c60711535413` | 97,341.438245 (94.84 % supply) | 1,042.4639 |
| 2 | `0x106a984153Ac6b5767B5A796C0BbEf9AB706022a` | 3,296.447965 | 35.3028 |
| 3 | `0x7126063A90C3b1041c2D33C801459488da4A59B4` | 994.245321 | 10.6477 |
| 4 | `0x3D01FeB1ABEc6720fe2F2229C3c1f7A221D6df2D` | 499.246895 | 5.3466 |
| 5 | `0xE2c0D842047781f2cF05A7973dc8124A37544976` | 99.553267 | 1.0662 |
| 6 | `0xF487D7D6830c2580d78E703344f5FD271FD24F5A` | 99.549969 | 1.0661 |
| 7 | `0xA7a2646c0C76ffBDBDB1752D3878f84D7A5A561F` | 95.874535 | 1.0268 |
| 8 | `0xb34c72BD27D8c585E706071586FEC1F67321eE09` | 89.572179 | 0.9593 |
| 9 | `0x55080E4Be333b46433bA3250670f72C03e6570B9` | 65.888978 | 0.7056 |
| 10 | `0x22BFa0421CFc7607A8Ac4Eda7A8772CCe7e87b39` | 19.937063 | 0.2135 |
| 11 | `0x66A912d66d4f8D21c43a8488a185ADDa7586D6E5` | 19.257566 | 0.2062 |
| 12 | `0xb80eC63a60Cee2B8952d3df208F4e3a14b67BE5b` | 16.949084 | 0.1815 |
| | **Total** | **102,637.96** | **1,099.1862** |

Some historically active stakers (`0x15723119…` = 100,000 cWFIL minted-then-fully-redeemed; `0x92Fbb9Fc…`, `0xDC465DB8…`, `0xCD057a1c…`, `0x037BC5D2…`, `0x0440fad1…`, `0x06801E1e…`, `0xD590…`) now hold **0**. Blockscout's `/tokens/0x587A…/holders` (7 holders, millions of cWFIL) is **stale/incorrect** — do not use it.

---

## 5. Related contracts & addresses

| Address | Role | Code size (B) | Native FIL (blk 6,457,049) | Evidence / first seen |
|---|---|---|---|---|
| `0x587A7eaE9b461ad724391Aa7195210e0547eD11d` | **HashMix FIL pool + cWFIL ERC-20** (Compound-fork cToken, native FIL, borrowBehalf, EIP-712 permit) | **22,338** | **1,581.864473** | GitBook address; name/symbol; dispatcher |
| `0xFA33F3866e7eF32F79734BCC5e011d767F8E574b` | **controller** (EIP-1967 TransparentUpgradeableProxy; reported impl `0xD3A8DCba…`) | 2,112 | 0 | pool `controller()`; created blk 2,883,636 |
| `0xD3A8DCbada627FBE5E21eF224486Af4412c80aDF` | controller implementation | 19,482 | 0 | Blockscout `implementations[]`; created 2023-08-15 |
| `0xE1DACa5a43DADd1b4db972d5d3a66eCF9960Eb81` | **interest rate model** | 1,143 | 0 | pool `interestRateModel()`; created blk 2,883,638 |
| `0x13ce9eB145a40b14B721570F0A91fc97656807DC` | proxy admin (used for controller upgrades 2023; `upgrade(address,address)`) | 1,891 | 0 | deployer txs blk 2,889,900/2,890,022 |
| `0x45D000319ac5BcBbf4C76799FbFd3045EBBE9b09` | proxy admin (used for 2025-04-11 upgrade of `0x10D81c…`) | 1,891 | 0 | deployer tx blk 4,868,433 |
| `0x10D81c7a15da6218F475b82eBFD638CFC3Cf36a5` | protocol contract (proxy) called by ops functions `0x818e2645`, `0xfd40449d`, `0x1e65e713` | 2,112 | 0 | deployer txs 2024-01-04; upgraded 2025-04-11 → `0x8f468C3e…` (19,668 B) |
| `0x06A4c6527fD462c4fD55664861437bC6D417FFA3` | **deployer EOA** (`f02199056`) — created the whole suite (27+ contracts), still holds proxy-upgrade rights | EOA | **2.813557** | creation tx |
| `0xD59060790f28EcD10Be2d23cEc88a39461A8d0cd` | **feeCollector()** + protocol ops wallet (12 mints ≈34.5k FIL, 8 redeems) | EOA | **0.235016** | pool `feeCollector()`; counterparty |
| `0xcF89b3A29499229E35d4fe71dFE54BEC2C1EbA48` | constructor arg #3 EOA; **only address that called `_reduceReserves`** (2023-05-26) — privileged ops/reserve address | EOA | **0.039993** | tx `0x2d4eea02…`; funded by deployer |
| `0x60E1773636CF5E4A227d9AC24F20fEca034ee25A` | canonical **WFIL** (not this pool's underlying; float 14,069,499.40 FIL) | 4,703 | 14,069,499.397 | Blockscout `q=WFIL` |
| `0x3C3501E6c353DbaEDDFA90376975Ce7aCe4Ac7a8` | separate **STFIL** protocol token (see §2) | 2,096 | 0 (proxy) | Blockscout `q=stFIL` |

### 5b. HashMix suite extensions found (multi-sig / treasury / V2)

| Address | Role | Code (B) | FIL | Notes |
|---|---|---|---|---|
| `0x37878C623D87D5E99BEA602B9b72886676f3DEF0` | **multi-sig** — named in the CertiK audit remediation ("multisig address", commit `9fdfef48…`) | 9,622 | 0.010004 | created by deployer block 2,881,405 (2023-05-22) |
| `0x358Cc936fc3035A49E02d670Ec9b8E0061E97979` | **timelock + multi-sig** — named by HashMix's own Medium post (2023-07-03: "Timelock contract and multi-sig addresses") | 5,795 | 0 | created by deployer block 2,984,736 (2023-06-27) |
| `0x85e77391C3dDe4fee572A79CFef7f710c7476f82` | **HashMix FIL V2 pool** (`name/symbol = cWFIL`, 23,188 B, same Compound-fork design) | 23,188 | **241.096296** | controller `0x10D81c7a…`, feeCollector `0xD590…`, IRM `0xC1032473c82Aef6c67e22066ec884e7c43FAb071`; created 2023-09-01 block 3,175,476; `accrualBlockNumber` 4,868,638 (2025-04-11) |
| `0x10D81c7a15da6218F475b82eBFD638CFC3Cf36a5` | V2 controller proxy (upgraded 2025-04-11 → impl `0x8f468C3e…`) | 2,112 | 0 | live app config (per sibling web research) |
| 7× pool-sized contracts `0x0B645b11…`, `0x29bc3563…`, `0x34cb76A6…`, `0x3c825f9f…`, `0x79CFe35d…`, `0xdc680756…`, `0xEb656d2B…` | additional 22,190-byte Compound-fork pool instances (V2-generation) | 22,190 ea. | 0 | all created 2023-09-01 |
| Other suite contracts (controllers/impls/proxies/IRMs: `0x0D149B15…`, `0x93AE946f…`, `0x148ED815…`, `0x481be153…`, `0x2D8d8333…`, `0xdc3FB7bd…`, `0x3FebA3ce…`, `0x785e7F5E…`, `0x980Ce3B4…`, `0x19Db91C7…`, `0xC1032473…`, `0xB24C357D…`, `0xFf37EC4c…`, `0xc10b7DA1…` etc.) | infra | — | 0 | full list: `suite_balances.json`, `deployer_txs*.json` |

**Total native FIL across all HashMix-related addresses found: ≈ 1,826.06 FIL** = 1,581.864473 (V1 pool) + 241.096296 (V2 pool) + 0.235016 (feeCollector `0xD590…`) + 2.813557 (deployer) + 0.039993 (`0xCF89…`) + 0.010004 (multi-sig) — every other suite contract holds 0 FIL. Additionally the **V2 pool has 560.571822 FIL of outstanding loans** (`totalBorrows`, borrowIndex 1.2355719): V2 cash 241.096 + borrows 560.572 = 801.668 FIL = V2 holders' claim exactly (75,729.435777 cWFIL × 0.01058595).

Other suite contracts created by the same deployer (blocks): `0xe0Fd99db…` (2,901,513), `0x358Cc936…` (2,984,736), `0x148ED815…`/`0x481be153…`/`0xD3A8DCba…` (3,126,4xx–3,126,5xx), `0xB24C357D…`, `0xFf37EC4c…`, `0x980Ce3B4…`, `0xdc680756…`, `0xEb656d2B…`, `0x79CFe35d…`, `0x3c825f9f…`, `0x0B645b11…`, `0x29bc3563…`, `0x34cb76A6…`, `0xdc3FB7bd…`, `0x45D00031…`, `0x2D8d8333…`, `0x785e7F5E…`, `0x7E1cE9e8…`, `0x10D81c7a…`, `0x3bc02BCf…`, `0x85e77391…`, `0x3FebA3ce…` (all 2023-09-01, blocks 3,174,655–3,175,478), `0x19Db91C7…` (2023-12-08), `0xC1032473…` (2023-12-25), `0x8f468C3e…` (2025-04-11). Full list: `deployer_txs.json` / `deployer_txs_p2.json`.

**V1-pool-related value:** 1,581.864473 (pool) + 0.235016 (feeCollector) + 0.039993 (`0xCF89`) + 2.813557 (deployer) = **≈ 1,584.95 FIL** (controller/IRM/impl/proxy-admin contracts all hold 0). Of the pool's 1,581.86 FIL, **1,099.19 FIL belongs to cWFIL holders** and **482.68 FIL is protocol reserves**. Including the V2 pool and multi-sig, the whole suite totals **≈ 1,826.06 FIL on-chain** (§5b).

---

## 6. Proxy checks (EIP-1967)

- Pool `0x587A…`: impl slot `0x0`, admin slot `0x0` → **not a proxy** (plain contract). ✔ as expected.
- stFIL `0x3C35…`: impl slot = `0x…F1eca87AC159a1132554124A89f4778100cc0ecc`, admin slot = `0x…C55e40977a782a0ea221812b9f01203effac71a1`.
- Controller `0xFA33…`: EIP-1967 TransparentUpgradeableProxy (its constructor args in `fa33_creation_tx.json`: logic `0x0D149B1538a7203e9dcD5Fb107eAc6dD0b5C1a5e`, admin `0x13ce9eB1…`, init `initialize(0xCF89…, 0x93AE946f39F91e13A9dEA50674f16a320f343e20, 0x8EDD899796b514750d40faeCb82c5c0CE13Ee776)`).

---

## 7. Function selector table (pool dispatcher, 45 entries + extras)

Recovered from runtime code (`PUSH4;EQ;PUSH2;JUMPI` scan, `pool_0x587A_code.hex`), cross-checked with 4byte and the sibling decompiler log.

```
name() 06fdde03 | symbol() 95d89b41 | decimals() 313ce567 | totalSupply() 18160ddd | balanceOf(address) 70a08231
allowance  dd62ed3e | approve 095ea7b3 | transfer a9059cbb | transferFrom 23b872dd
increaseAllowance 39509351 | decreaseAllowance a457c2d7 | DOMAIN_SEPARATOR 3644e515 | nonces(address) 7ecebe00 | permit d505accf
mint(uint256) a0712d68 [payable/native FIL] | redeem(uint256) db006a75 | redeemUnderlying(uint256) 852a12e3
borrowBehalf(address,uint256) 856e5bb3 | repayBorrowBehalf(address,uint256) 2608f818 | borrowBalanceCurrent(address) 17bfdfbc
borrowBalanceStored(address) 95dd9193 | getCash() 3b1d21a2 | totalBorrows() 47bd3718 | totalReserves() 8f840ddd
borrowIndex() aa5af0fd | exchangeRateStored() 182df0f5 | exchangeRateCurrent() bd6d894d | balanceOfUnderlying(address) 3af9e669
underlying() 6f307dc3 | controller() f77c4791 | interestRateModel() f3fdb15a | feeCollector() c415b95c
reserveFactorMantissa() 173b9904 | _setReserveFactor(uint256) fca7820b | protocolSeizeShareMantissa() 6752e702
initialExchangeRateMantissa() 675d972c | accrualBlockNumber() 6c540baf | accrueInterest() a6afed95 | getAllRates() ff5a20bf
_addReserves(uint256) 3e941010 | _reduceReserves(uint256) 601a0bf1 | sweepToken(address,address) 258836fe
updateFeeCollector(address) d2c35ce8 | UNKNOWN 69ab3250 (never called) | UNKNOWN d0248fb4 (never called) | (sibling also saw 43600c54 — unresolved, never called)
```

Only **4 of these were ever called** by users (`mint`, `redeem`, `redeemUnderlying`, `transfer`); `accrueInterest` and `_reduceReserves` once each by protocol addresses. Raw selectors: `pool_selectors_resolved.json` (sibling), `4byte_selectors.json`, `pool_0x587A_logs.json` (event topics: `AccrueInterest 0x4dec04e7…`, `Transfer 0xddf252ad…`, `Redeem 0xe5b754fb…`, `RepayBorrow 0x1a2a22cb…`; all logs emitted by the pool itself).

---

## 8. Endpoint results / failures

- ✅ Blockscout v2 REST (`filecoin.blockscout.com/api/v2`) — main source (rate-limited at times, 429). ✅ Blockscout ETH-RPC proxy (`/api/eth-rpc`) — used initially, heavy 429 → switched to Glif/Ankr/chain.love.
- ✅ Glif `https://api.node.glif.io/rpc/v1`, ✅ Ankr `https://rpc.ankr.com/filecoin` (JSON-RPC batch works), ✅ `https://api.chain.love/rpc/v1` — used for all `eth_call`/`eth_getStorageAt`/`eth_getCode`.
- ❌ **`/addresses/0x587A…/internal-transactions` — HTTP 000 on every attempt** (also v1 `txlistinternal` = 429). Native FIL flow was reconstructed from `coin-balance-history` + tx `value` fields instead.
- ❌ **Filfox (API and web) unreachable** (HTTP 000). ❌ **api.beryx.io returns empty** (needs key). ❌ Sourcify v1 removed; v2 `match:null` (contract not verified). ❌ `github.com/HashMixProject/hashmix-fevm` = 404 (audited codebase private/removed).
- ⚠️ Blockscout data quirks: 3 duplicated cWFIL transfer rows; `/holders` stale (see §4).

---

## 9. Raw data files (all in `hashmix-fil/analysis/`)

`pool_creation_tx.json`, `pool_0x587A_code.hex`, `pool_0x587A_logs.json`, `raw_pool_txs_paged.json` (282 txs), `raw_cwfil_transfers_paged.json` (277 rows), `raw_pool_coin_balance_history.json`, `pool_counterparties.json`, `ground_truth_final.json` (views+balances+code+native @ blk 6,457,049), `ground_truth_batch.json`/`gt_raw_results.json`, `final_extras.json` (proxy slots, stFIL info, counterparty code checks), `suite_balances.json` + `v2_pool_views.json` (V2 pool / multi-sig / suite code+balances), `batch_calls_out.json`, `focused_calls.json`, `4byte_selectors.json`, `deployer_txs.json`, `deployer_txs_p2.json`, `fa33_creation_tx.json`, `stFIL_*` files, `tokens_q_stFIL.json`, `tokens_q_WFIL.json`, `llama_hashmix.json`, `gitbook_liquidity-token.md`, `hashmix_audit_2023.pdf` + `hashmix_audit_text.txt`, `strings_dump.json`, `sourcify_v2.json`, scripts (`rpc.py`, `ground_truth*.py`, `check_counterparties.py`, `slow_paginate.py`, `strings_dump.py`, `scan_related_code.py`, …). Companion sibling notes: `web-research.md` (protocol/web history, multi-sig addresses, V2 app config).

## 10. Uncertainties / open items

1. Roles of `0xCF89…` (EOA) vs `0xD590…` (feeCollector view) need decompilation of the fork's `updateFeeCollector`/`_reduceReserves` access control to be stated precisely; no `updateFeeCollector` call was ever made on the pool (so `feeCollector()` value comes from constructor-time wiring/controller).
2. Exact FIL inflows/outflows per event could not be obtained (internal-transactions endpoint down); totals above are balance-verified.
3. Unresolved selectors `0x69ab3250`, `0xd0248fb4`, `0x43600c54` (never called).
4. The pool's yield mechanics (staking to SPs) happen off this contract (or via the controller `0xFA33…`); the pool itself shows no borrow calls. V1's `totalBorrows` is ~0 while V2's is 560.57 FIL — monies lent via the V1 market appear to have been re-routed through the V2 pool / controller from Sep 2023 onward (V2 launch: 2023-09-01; V1's big balance drop 2024-01/02).
5. Source code of the pools is not public (Blockscout/Sourcify unverified; audited `hashmix-fevm` repo removed) — function names were recovered from selectors/decompiler output.
