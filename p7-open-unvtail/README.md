# ZH4-PASS7 — OPEN O1+O2: **unverified-impl proxy tail** (deep-dive)

**Date:** 2026-10-26 · **Chains:** Optimism, Polygon, zkSync, BSC, Scroll (+ Ethereum for owner checks)
**Status:** read-only · fork-only PoC · no mainnet transaction signed/sent · no secrets in this folder.

**Scope:** pass7-recon rows **O1** (unverified-impl proxy tail, `unverified-impl.md` rows 13–22, ≈$1.7M live) and **O2** (4 Scroll unverified-impl proxies, unvalued). The pass7 lane had only **selector-scanned** these impls; the mandate here is: decompile the impls, map the money-path selectors + auth, then **fork / `eth_call`-probe from a fresh EOA** (impersonate a random address, call `transfer`/`withdraw`/`redeem`/`initialize`/`upgradeTo`) and see whether value moves.

---

## 1. TL;DR — every target, live extractable, why closed

| # | Proxy (chain) | Live value (this run) | Impl | Identity (decompiled) | Fresh-EOA money path | Verdict |
|---|---|---|---|---|---|---|
| O1-row22 | `0xc4d45003…c7EF` (OP) | **279.557 WETH ≈ $651,167** | `0x833Be3F1…` | **Exactly Protocol `exaWETH`** — full ERC-4626 vault (`asset()`=WETH, `totalAssets`, `redeem`, `withdraw`, AccessControl+Pausable, 31,882 holders) | `redeem/withdraw/transfer` → revert `Panic(0x11)` (no shares) | **CLOSED · H-O** (share-gated) |
| O1-row18 | `0xA4B6D09c…54b5` (OP) | **140.994 WETH + 0.273 ETH ≈ $329,051** | `0x62C9E5e5…` | **Upshift Finance** vault subaccount (owner `0xc428439f…` = the Upshift "Sylva CL USDC" vault, $2.98M AUM on ETH; recall is operator-only) | `transfer`→ok, **Δ=0**; `withdraw`→revert `0x1e092104`; `withdrawFromSubaccount`→ok, **Δ=0**; `transferOwnership`→revert | **CLOSED · P** (operator/owner) |
| O1-row14 | `0x5520385b…69FA4` (Polygon) | WPOL 489,715 + WETH 24.18 + USDC 70,219 + USDT 67,453 ≈ **$237,820** | `0xcFe82450…` | **WOOFi CrosswapRouter v5** (TransparentProxy; owner = 6-owner Gnosis Safe `0x682f6763…`) | `withdraw(token,bal)`→revert `0x7bfa4b9f`; `transferOwnership`→revert `OwnableUnauthorizedAccount` | **CLOSED · P** (multisig) |
| O1-row16 | `0x3cDbbC3e…2deCef0` (OP) | **78.716 WETH + 90,571 USDC ≈ $273,917** | `0x028361fD…` | **Concentrated-liquidity strategy vault** (`regCenter/positionManager/virtualPool/priceShift/getNetValue/depositBaseToken/withdrawToken/sweepToken`; holds a VELO-CL-POS NFT) | `withdraw/transfer/deposit` → revert **`Auth`** | **CLOSED · P** (auth-registry) |
| O1-row13 | `0x5520385b…69FA4` (OP) | WETH 56.70 + USDT 105,803 + USDC 127,599 + OP 450,082 ≈ **$415,429** | `0x7b5fDb8C…` | **WOOFi CrosswapRouter v5** (same protocol, OP deployment) | `withdraw(token,bal)`→revert `0x7bfa4b9f`; `transferOwnership`→revert | **CLOSED · P** (multisig) |
| O1-row17 | `0xC6Ae1Db6…f9dbf` (OP) | USDT 107,057 + USDC 101,137 + 6.248 ETH ≈ **$222,748** | `0xeE91925A…` | **Wanchain asset lock / CrossDelegate V5–V7 bridge** ("CrossDelegateV7: caller is not a…", "Smart contract is halted") | `transfer`/`transferOwnership` → revert | **CLOSED · P** (bridge signer) |
| O1-row19 | `0x6726CA16…27eC` (OP) | WETH 21.031 + USDC 7.27 + OP 95.46 ≈ **$59,594** | `0x1616156771…` | **Compound-fork lending market** (mint/redeem/borrow, Unitroller/ChainlinkOracle dependency; `Ownable`) | `redeem/mint/transfer`→revert; `withdraw`→revert `!W`; `transferOwnership`→revert `Ownable` | **CLOSED · H-O** (cToken-gated) |
| O1-row21 | `0xB07FfFf3…3050D` (Polygon) | WETH 26.758 + USDC 449,875 + USDT 184,024 ≈ **$696,229** | `0x15F069F9…` | fee/withdraw vault ("Withdraw already processed", "Insufficient collected fees"; UUPS `owner()` = EOA `0x58c5927b…`) | `transfer`→revert; `upgradeToAndCall`/`transferOwnership`→revert `OwnableUnauthorizedAccount`; `initialize`→revert `InvalidInitialization` | **CLOSED · P** (owner EOA) |
| O1-row20 | `0x7d5b0215…55a1E` (zkSync) | USDC 13,696 + WETH 15.596 ≈ **$50,026** | `0x442DbDE5…` (135 KB) | **Fulcrom Finance Vault** (zkSync perp-DEX LP vault; UUPS, `_vault`/`_priceFeed`) | `transfer`/`transferOwnership`/`withdrawFees`→revert; `initialize`→"already initialized" | **CLOSED · H-O** (LP vault) |
| O1-row15 | `0x4CA08cD9…1589` (BSC) | USDT 25,137 (+dust WBNB) ≈ **$25,138** | `0x5abfa214…` | **DCA Vault** ("Vault: dcaRate too high", "Vault: batch count too high"; UUPS) | `withdraw`/`transfer`→revert; `initialize`→`InvalidInitialization`; `upgradeToAndCall`→revert `0x068ca9d8` | **CLOSED · H-O** (depositor-gated) |
| O2-scr1 | `0x25aB3Efd…948D3` (Scroll) | 0.13 ETH + 1,840 USDC + 798 USDT ≈ **$2,940** | `0xe9CDb9C2…` | **Meson bridge** ("Need an authorized address as the signer", "Caller is not the premium manager") | `upgradeTo`/`upgradeToAndCall`/`transferOwnership` → revert `Caller is not the owner` | **CLOSED · P** |
| O2-scr2 | `0x740a7C5E…b2cE7` (Scroll) | 0.998 WETH + 7 USDC + dust ETH ≈ **$2,327** | `0x26623DC7…` | UUPS pool/vault ("insufficient liquidity", "Unauthorized access") | `withdraw`/`transfer`/`upgradeToAndCall` → revert | **CLOSED · P** |
| O2-scr3 | `0x7BE980E3…AF8Ef4` (Scroll) | 2.511 ETH + 1,518 USDC + 44 USDT ≈ **$7,395** | `0x20F4E8cB…` | **Aster** contract (signed-claim: "only accept truthHolder signed msg", "already withdraw"; timelock upgrade) | `initialize`→`InvalidInitialization`; `upgradeToAndCall`→revert `only timelock` | **CLOSED · P** (timelock) |
| O2-scr4 | `0x7ba30C4c…742F2` (Scroll) | 0.495 WETH ≈ **$1,150** | `0x65515781…` | auto-**compounder** vault ("Not compounder"; owner = 2-owner multisig) | `transfer`/`deposit`→revert; `transferOwnership`→revert `Ownable` | **CLOSED · H-O** (depositor-gated) |

## 2. Total live extractable now

> ### **External-unprivileged extractable (E-U) = $0.00**
> Confidence: **HIGH**. 14/14 funded proxies probed from a fresh EOA on a live fork + by direct `eth_call`; **not one** money-path selector moved any value.

Total value **held** by the O1+O2 set ≈ **$2,974,931** (10 O1 + 4 O2), all behind owner / multisig / signer / role / timelock / share- or position-gating. Category split: **E-U $0 · H-O ≈ $787,075 · P ≈ $2,187,856 · S $0**.

---

## 3. Mechanism / why this was open, and why it is closed

The pass7 `unverified-impl` lane swept token-holder sets and flagged proxies whose **implementation had no verified source on Etherscan V2 + Sourcify + Blockscout**. Its tail (rows 13–22, plus 4 Scroll rows) was only **selector-scanned** — the impls were never decompiled and no fork probe was run. The Slice/Drift pre-condition ("unverified code holding funds") was therefore untested for ~$2.9M. This deep-dive closes that gap:

1. **Decompiled** every impl (raw `PUSH4` selector extraction + `heimdall` ABI + `panoramix` + on-chain string constants + 4byte/openchain resolution).
2. **Identified** each protocol (below).
3. **Probed** every money path from a fresh EOA, both in a **Foundry fork** (balance-delta measured) and by **direct `eth_call`** (revert-data captured).

**The decisive negative:** a fresh EOA cannot move a single wei. `transfer` / `withdraw` / `redeem` / `mint` / `deposit` / `sweepToken` / `withdrawToken` / `withdrawFees` / `upgradeTo` / `upgradeToAndCall` / `initialize` / `transferOwnership` **all revert** — with one exception (row18 `transfer` returns success but is a verified **no-op**: fork balance delta = 0).

### 3.1 Protocols identified (decompiled)

| Target | Protocol | Evidence |
|---|---|---|
| row22 | **Exactly Protocol** `exaWETH` | `name()="exactly WETH"`, `symbol()="exaWETH"`, `asset()`=OP-WETH, `totalAssets`, 31,882 holders; EIP-1967 admin `0xfba759bc…` (ProxyAdmin owner `0x92024c4b…`) |
| row18 | **Upshift Finance** "Sylva Concentrated Liquidity USDC" vault subaccount | `owner()`=`0xc428439f…` = Upshift vault (ETH, `totalAssets`=2,977,065 USDC, symbol `upsSYLVA`); `withdrawFromSubaccount(amount, subAccountAddr)` is an Upshift **operator** function |
| row14 / row13 | **WOOFi CrosswapRouter v5** | WOOFi dev-docs list `0x5520385b…`; owner = 6-owner Gnosis Safe |
| row16 | **CL strategy vault** | selectors `regCenter/positionManager/gauge/virtualPool/priceShift/getNetValue/depositBaseToken/withdrawToken/sweepToken`; holds a VELO-CL-POS NFT; every entrypoint reverts `Auth` |
| row17 | **Wanchain** asset-lock / `CrossDelegate` bridge | strings `CrossDelegateV5/V6/V7`, `Smart contract is halted`, `Signature verification failed` |
| row19 | **Compound-fork lending market** | `mint/redeem/borrow/redeemUnderlying`, `Unitroller`+`ChainlinkOracle` deps, `Ownable` |
| row21 | fee / withdraw vault (UUPS) | `Withdraw already processed`, `Insufficient collected fees`, `No token balance to refund`; `owner()`=EOA |
| row20 | **Fulcrom Finance Vault** (zkSync) | Fulcrom docs; zkSync explorer `_vault`/`_priceFeed`; UUPS |
| row15 | **DCA Vault** (BSC) | `Vault: dcaRate too high`, `Vault: batch count too high` |
| scr1 | **Meson bridge** | `Need an authorized address as the signer`, `Caller is not the premium manager` |
| scr2 | UUPS pool/vault | `insufficient liquidity`, `Unauthorized access` |
| scr3 | **Aster** (Scroll) | Aster docs list the address; `only accept truthHolder signed msg`, `only timelock` |
| scr4 | auto-**compounder** vault | `Not compounder`; owner = 2-owner multisig |

---

## 4. Live-state assessment (all reads at explicit blocks)

**Blocks read (2026-10-26):** OP **158,687,843** · Polygon **96,179,395** · zkSync **72,638,374** · BSC **129,801,534** · Scroll **35,498,208** · Ethereum **26,272,075**.

| Target | proxy code | impl code | token balances | owner / admin / roles |
|---|---|---|---|---|
| row22 | 1,648 B | 24,542 B | WETH 279.5566 | EIP-1967 impl slot set; admin `0xfba759bc…` (1529 B, owner `0x92024c4b…`); `paused()=false` |
| row18 | 2,001 B | 17,352 B | WETH 140.9939, native 0.2735 | `owner()=0xc428439f…` (Upshift vault, code 2001 B, owner `0x71ec910b…`) |
| row14 | 1,159 B | 22,841 B | WPOL 489,715, WETH 24.178, USDC 70,219, USDT 67,453 | `owner()=0x682f6763…` (171 B, `getOwners()`=6 → Safe); admin `0x4f0416bb…` |
| row16 | 289 B | 23,575 B | WETH 78.716, USDC 90,571 | custom minimal proxy: `implementation()`+`updateImplementation()` (owner slot, reverts `Atk`); impl gates everything `Auth` |
| row13 | 1,159 B | 23,218 B | WETH 56.70, USDT 105,803, USDC 127,599, OP 450,082 | `owner()=0x682f6763…` (Safe); admin `0x4f0416bb…` |
| row17 | 2,070 B | 22,730 B | USDT 107,057, USDC 101,137, native 6.248 | `owner()=0x329f1625…` (4482 B contract); `admin()=0xa35b3c55…` (EOA) |
| row19 | 2,769 B | 11,706 B | WETH 21.031, USDC 7.27, OP 95.46 | `owner()=0x2869b95d…` (EOA) |
| row21 | 163 B | 7,559 B | WETH 26.758, USDC 449,875, USDT 184,024 | `owner()=0x58c5927b…` (EOA) |
| row20 | 10,080 B | 135,648 B | USDC 13,696, WETH 15.596 | EIP-1967 impl slot; admin `0x268980de…` |
| row15 | 170 B | 18,124 B | USDT 25,137 (+dust WBNB) | EIP-1967 impl slot; `paused()=false` |
| scr1 | 168 B | 19,918 B | native 0.13, USDC 1,840, USDT 798 | UUPS; owner-gated |
| scr2 | 855 B | 22,488 B | WETH 0.998, native 0.0006, USDC 7 | ERC1967Proxy; UUPS owner-gated |
| scr3 | 855 B | 15,593 B | native 2.511, USDC 1,518, USDT 44 | timelock-gated (Aster) |
| scr4 | 2,227 B | 22,408 B | WETH 0.495 | TransparentUpgradeableProxy; `owner()`=2-owner Safe |

Raw JSON: `analysis/live_state_balances.json`, `analysis/live_state_owners_holdings.json`; selector dumps `analysis/impl_selectors_raw.txt`; impl bytecode `analysis/code/*.impl.hex`.

---

## 5. What an attacker can / cannot do

* **Cannot** call any value-moving function: every `transfer`/`withdraw`/`redeem`/`mint`/`deposit`/`sweep*`/`withdrawToken`/`upgrade*`/`initialize`/`transferOwnership` reverts from a fresh EOA (see §6 for the full revert table). Costs are irrelevant — no path exists to price.
* **Cannot** hijack an upgrade: every proxy's `upgradeTo`/`upgradeToAndCall` is `onlyOwner`/`onlyRole`/`onlyTimelock` (reverts `OwnableUnauthorizedAccount` `0x118cdaa7`, `Unauthorized access`, `only timelock`, `Caller is not the owner`, or a custom error).
* **Cannot** re-initialize: every `initialize` reverts `InvalidInitialization` (`0xf92ee8a9`) or "already initialized".
* **One benign success:** row18 `transfer(att,bal)` returns success with **empty** return data and **zero** balance delta — a no-op for a non-owner caller (same silent-no-op class as the Bitget signer-registry in the lane's §2).
* The value is **real and live** but belongs to depositors (H-O: `exaWETH` share holders, cToken lenders, Fulcrom LPs, DCA depositors, compounder depositors) or to protocol/operator control (P: WOOFi multisig, Upshift operator, Wanchain bridge, Meson, Aster timelock, owner EOAs).

---

## 6. PoC / fork-verification

**Files:** `poc/foundry.toml`, `poc/test/Probe.t.sol` (per-chain fork probes), `poc/test/ZkDiag.t.sol` (zkSync fork diagnostic).

**Fork suite — 5/5 PASS** (`forge test -vvv`): `test_OP`, `test_Polygon`, `test_BSC`, `test_Scroll`, `test_ZkSync`. Each test impersonates a fresh EOA (`0x…dEaD`), calls the money selectors, and asserts the proxy's token+native balance is unchanged. **No test observed any value movement.**

Key fork observations (tokenDelta / nativeDelta all **0**):

| Target | call | result |
|---|---|---|
| row22 | `transfer`, `redeem(shares)`, `withdraw(assets)`, `redeem(1e18)` | revert `0x4e487b71` (Panic 0x11, no shares) |
| row18 | `transfer` | **ok=true, Δ=0 (no-op)** |
| row18 | `withdraw(WETH,bal,att)` | revert `0x1e092104` |
| row18 | `withdrawFromSubaccount(bal,proxy/att)`, `withdrawFromSubaccount(address,uint256)` | ok=true, **Δ=0** |
| row14/13 | `withdraw(token,bal)` | revert `0x7bfa4b9f` |
| row14/13 | `transferOwnership` | revert `0x118cdaa7` (`OwnableUnauthorizedAccount`) |
| row16 | `withdraw`, `transfer`, `deposit` | revert `Auth` |
| row17 | `transfer`, `transferOwnership` | revert (no data) |
| row19 | `redeem`, `mint`, `transfer` | revert; `withdraw` → revert `!W`; `transferOwnership` → `Ownable: caller is not the owner` |
| row21 | `transfer` | revert; `upgradeToAndCall`/`transferOwnership` → `0x118cdaa7`; `initialize` → `0xf92ee8a9` |
| row21 | `withdrawFees(USDC,bal)`, `refundToken(USDC/USDT,bal,att)`, `addWhitelistedToken`, `setFeeRate`, `setFeeRecipient`, `removeWhitelistedToken`, `renounceOwnership` | **all revert `0x118cdaa7` (`OwnableUnauthorizedAccount`)** — see `analysis/row21_owner_gates.json` |
| row15 | `withdraw`, `initialize`, `upgradeToAndCall` | revert (`0xf92ee8a9`, `0x068ca9d8`) |
| scr1 | `upgradeTo`/`upgradeToAndCall`/`transferOwnership` | revert `Caller is not the owner` |
| scr2 | `withdraw`/`transfer`/`upgradeToAndCall` | revert `Unauthorized access` |
| scr3 | `initialize` → `0xf92ee8a9`; `upgradeToAndCall` → `only timelock` | revert |
| scr4 | `transfer`/`deposit` revert; `transferOwnership` → `Ownable: caller is not the owner` | revert |

**Direct `eth_call` probe (all 14 targets, fresh EOA):** `analysis/ethcall_probe.json` — every money selector reverts, except row18's no-op `transfer`.

**zkSync caveat + fix:** Foundry's zkSync-Era fork loads code but **not storage** (`balanceOf` returns 0 and calls falsely "succeed"), so the fork result for row20 is unreliable. row20 was therefore re-probed by **direct `eth_call`** against `https://mainnet.era.zksync.io`: `transfer`/`transferOwnership`/`withdrawFees` **revert**, `initialize()` reverts "already initialized". `poc/test/ZkDiag.t.sol` documents the fork limitation (code len 10080/8672, bal 0).

**CI:** GitHub Actions `artsbykriss/ca-zombie-ci`, workflow `poc.yml`, branch `p7-open-unvtail`:
- **Final run (success):** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40249453551 — `custom CI script` exit 0, `forge test` **5 passed / 0 failed**.
- Earlier run (failed): `…/runs/40248843770` (empty `OP_RPC_URL`/`POLYGON_RPC_URL`/`BSC_RPC_URL` in CI → fixed by treating empty as unset and using keyless public fallbacks).
- Artifacts: `ci-artifacts/result-p7-open-unvtail/ci-out/forge-test.txt`; full log `ci-log.txt`.

**Run split:** all compile + fork tests + `eth_call` probes ran in CI (GitHub Actions); local work was limited to light keyless RPC reads (`cast`/python) and decompiler runs.

---

## 7. Verdict & residual / latent risk

* **E-U = $0.00 (HIGH confidence).** The ~$2.97M held by the O1+O2 set is **not** externally extractable today. The Slice/Drift pre-condition (unverified code holding funds) was present but, as with the lane's $249M Bitget cluster, every money path that reaches the value is **owner / multisig / signer / role / timelock / share- or position-gated**, or a silent no-op.
* **Residual / latent (monitor-only):**
  1. **row22 exaWETH** — a live ERC-4626 vault ($651k) with an unverified impl; a share-accounting bug would be E-U, but `redeem`/`withdraw` correctly revert for a share-less caller. Watch for future `Upgraded` events.
  2. **row21** (Polygon, $696k) and **row19** (OP) and **row16** (OP) have **EOA `owner()`** or an auth registry — a compromised/leaked key would move funds, but that is **P**, not E-U.
  3. **scr2 / scr4 / row15 / row20** are UUPS/compounder/DCA/LP vaults — all gated; upgrade authority is the residual risk.
* **Blockers / caveats:**
  1. Impl sources are unverified on Etherscan V2/Sourcify/Blockscout (that is why they were OPEN); identification is by decompilation + on-chain string constants + explorer/token metadata, so protocol *names* carry MEDIUM confidence, but the **gating behaviour is proven by live revert/no-op probes (HIGH confidence)**.
  2. `heimdall 0.9.2` emitted only an ABI (unresolved selectors); identification used raw selector extraction + `panoramix` + `openchain`/4byte resolution + string constants.
  3. Foundry zkSync-Era fork state is unreliable (see §6); row20 closed via direct `eth_call`.
  4. Point-in-time **2026-10-26**; re-read live state before acting. Nothing here is an instruction to transact.

---

## 8. Methodology & sources; files index

**Method:** token-holder → proxy/impl enumeration (from the lane's scratch + re-resolved); `eth_getCode`/EIP-1967 slot/`eth_getBalance`/`balanceOf`/`owner()`/`admin()`/`getOwners()`/role reads at explicit blocks; raw `PUSH4` selector extraction; `heimdall`/`panoramix` decompile; on-chain string-constant extraction; `openchain`/4byte selector resolution; Foundry multi-fork balance-delta probes; direct `eth_call` revert probes; web/explorer identification (WOOFi docs, Upshift docs, Fulcrum docs, Aster docs, Wanchain docs, Etherscan/Blockscout/optimism explorers).

**Files:**
- `README.md` (this file) · `summary.json`
- `analysis/live_state_balances.json`, `analysis/live_state_owners_holdings.json` — live reads
- `analysis/ethcall_probe.json` — direct `eth_call` probe of all money selectors
- `analysis/row21_owner_gates.json` — row21 full selector resolution + owner-gate probes
- `analysis/impl_selectors_raw.txt` — per-impl `PUSH4` selector sets
- `analysis/code/*.impl.hex` — impl runtime bytecode
- `analysis/{read_live,read2,fetch_code,sels,owners,ethcall_probe}.py` — scripts (keyless public RPCs only)
- `poc/` (Foundry) · `ci/run.sh` · `ci-out/forge-test.txt` · `ci-log.txt` · `ci-artifacts/`

*Prepared 2026-10-26 · ZH4 pass-7 OPEN O1+O2 deep-dive · read-only · fork-only · no secrets.*
