# gnosis-residual — Tier-3 deep dive (L2-13 1Hive/Gardens v2 + L2-15 Orchid Lottery1)

**Date:** 2026-10-15 · **Chain:** Gnosis (id 100) · **Status:** read-only research; PoC fork-verified only; **no mainnet transactions, no signing, no secrets**. Fork block pinned at **48,767,754** for all PoC runs. HNY price **$0.978918** (DefiLlama 2026-10-15), xDAI **$0.9998629**, sDAI **$1.2619** (DefiLlama + on-chain `convertToAssets`).

**Targets:** (a) 1Hive Aragon DAO + 1Hive Gardens v2 on Gnosis (HNY pots: L2-13, lead ~32.6k HNY ≈ $34.1k); (b) Orchid Lottery1 on Gnosis (99,903.97 xDAI, L2-15).

---

## 1. TL;DR

| Target | Live value (block 48,767,754) | Unprivileged extractable? | Why | Latent risk |
|---|---|---|---|---|
| **1Hive Aragon DAO** vault/Agent `0x4ba7362F…` | **21,398.66 HNY = $20,947.20** | **YES — conditional**: CV round **+$840…+$2,115** net (fork-proven mechanics); full-vault DV drain **+$3.9k…+$6.4k** net modeled ($22.3k one-block capital) | ANY holds `CV.CREATE_PROPOSALS_ROLE` and `DV.CREATE_VOTES_ROLE`; CV holds Agent `TRANSFER_ROLE`, DV holds Agent `EXECUTE_ROLE`. Fork PoC: fresh address made proposal 214 → vault paid it 1,000 HNY; fresh address with 7,600 HNY at one snapshot drained the **entire vault to 0** | Community passivity + thin HNY DEX depth are the only limits; any alert member can challenge for 6.06 HNY (pauses); deeper HNY liquidity would make full $20.9k extractable |
| **1Hive Gardens v2** pool 27 `0x9Fb2…F8A2` | **5,496.40 HNY = $5,380.53** | **NO (net-negative)**: path fully open but realistic net **−$291…−$832** (best case +$174) | Conviction drain is permissionless (allowlist open, member proposal, permissionless `distribute`) but `S_min ≈ 1.0–1.7×X` forces a 2.7–3.7×X round trip through a market whose usable HNY depth is $4.7k–11k; max X < 0.5·F ≈ 2,748 HNY. Conditional holder-funded variant ≈ +$800 | Deeper HNY liquidity or an HNY-holder attacker flips it positive; council can raise thresholds (P) |
| **1Hive Gardens v2** RegistryCommunity `0xE239…6257` | **5,694.66 HNY = $5,574.65** | **NO** — member collateral | Balance reconciles **exactly** (diff 0.0) with the sum of 65 members' `stakedAmount`; only self-unstake; `kickMember` council-only and disabled (`isKickEnabled=false`) | — |
| **Gardens v2 sDAI sibling pools 8/67** | **11,855.06 sDAI = $14,957.13** | **NO — allowlist-gated** | Closed 15-address `ALLOWLIST` per pool (`address(0)` not granted; non-listed members revert `UserCannotExecuteAction`); counterfactual if opened: pool 67 +$3.0–3.3k | Allowlist opening (council) would make these the most profitable Gardens target |
| **Orchid Lottery1** `0x6dB838…0a82` | **99,906.64 xDAI = $99,892.94** | **NO** — E-U $0 (high confidence) | `claim()` requires an ECDSA signature by the escrow account's signer: 30,407 accounts / **0 with signer=0**; forged sig → ecrecover 0 → no account; self-signed → no account; replays blocked by `tracks_`; digest binds chainid+contract+token+recipient. PoC: forged + self-signed tickets pay $0 | Lost signer keys make individual accounts unrecoverable (indistinguishable on-chain); a compromised signer key is the only claim path |

**Total live extractable now (external unprivileged): $6,442 modeled (conditional; medium confidence)** — the 1Hive Aragon vault via governance capture. Per-round low-capital variant $840–$2,115; hard-currency-only floor ≈ $1.6k. Gardens v2 HNY + Orchid contribute **$0** in E-U (see categories in §8).

---

## 2. The mechanisms in exact terms

### 2.1 1Hive Aragon DAO — permissionless governance capture of the vault (fork-proven)

The classic 1Hive DAO (kernel `0x8ccbeab14b5ac4a431fffc39f4bec4089020a155`) uses the 1Hive app suite: **ConvictionVoting** `0x0B21081C6F8b1990f53FC76279Cc41ba22D7AFE2`, **DisputableVoting** `0xfBd0B2726070a9D6AfF6D7216c9E9340Eae68b2a`, **Agreement** `0x59A15718992A42082aB2306bc6Cbd662958a178c`, **HookedTokenManager**, Issuance, Superfluid. Live ACL (block 48,767,754, via `ACL.hasPermission` on `0xbc4fb635636b81e60a4e356c4dceb53cac507d03`):

| Permission | Holder | Live |
|---|---|---|
| `Agent.TRANSFER_ROLE` (`0x4ba7362F…`) | **ConvictionVoting**, Superfluid | true |
| `Agent.EXECUTE_ROLE` / `RUN_SCRIPT_ROLE` | **DisputableVoting** | true |
| `CV.CREATE_PROPOSALS_ROLE` | **ANY** (`address(0)`) | true |
| `DV.CREATE_VOTES_ROLE` | **ANY** | true |
| `CV/DV.CHALLENGE_ROLE` | **ANY** | true |
| `HookedTokenManager.MINT_ROLE` | Issuance only (Issuance roles unassigned → mint path dead) | — |

**Path A — ConvictionVoting (no vote, ≤20 % of vault per proposal).** `CV.addProposal(title, link, requestedAmount, false, beneficiary)` is `auth(CREATE_PROPOSALS_ROLE)` = anyone. `stakeToProposal(pid, S)` is permissionless and **does not move tokens** (only requires `balanceOf(staker) ≥ totalVoterStake + S`). `executeProposal(pid)` is permissionless and calls `vault.transfer(HNY, beneficiary, amount)` (CV holds `TRANSFER_ROLE`). Gates in source (`ConvictionVoting.sol` lines 2618–2691): `maxRatio = 2,000,000` (0.2 → request < 20 % of live vault), `decay = 9,999,799`, `weight = 10,000`, `minThresholdStakePercentage = 2e17`; `threshold = 49.75124·T/(0.2−R/F)²` conviction units with `T = max(totalStaked, 20 %·supply)`. Live `calculateThreshold(1000e18)` = `3.1950241333558527694374772e25` (matches historical proposal 213). Before acting the attacker must `Agreement.sign(currentSettingId)` (permissionless, `getCurrentSettingId()=1`) and stake ≥ the **6.061864241695410850 HNY** action collateral in staking pool `0x0E25B918C9Fb2fEA5d42011d1F4B9f8c61B453e7` with `allowManager(Agreement, …)`.

**Path B — DisputableVoting (drain the whole vault in one action).** `DV.newVote(script, context)` is `auth(CREATE_VOTES_ROLE)` = anyone. Setting 0 (live): voteTime 432,000 s (5 d), support 50 %, quorum 10 %, executionDelay 1 d, quiet ending 1 d/12 h. Voting power = `HNY.balanceOfAt(voter, snapshotBlock)` (snapshot = creation block − 1) and `totalPower = totalSupplyAt(snapshot)`; with no opposition, passing needs **> 10 % of supply = 7,543.0 HNY at one block** (`_isValuePct` is strict `>`). The EVM calls script (spec id 1, delegatecalled in the DV context — confirmed by inspecting the executed vote 19 script `0x00000001 + kernel…`) invokes `Agent.execute(HNY, 0, transfer(attacker, 21,398.66e18))`; `executeVote(voteId, script)` is permissionless. Challenge: any address can `Agreement.challengeAction` for 6.0618 HNY + Celeste arbitration (arbitrator `0x44E4fCFed14E1285c9e0F6eae77D5fDd0F196f85`), which **pauses** the vote/proposal — the community-passivity precondition.

### 2.2 Gardens v2 — conviction-drain path is open but net-negative (documented gates)

1Hive community `0xE2396fe2169ca026962971d3B2E373Ba925B6257` (gardenToken HNY, 59 members, `registerStakeAmount=3 HNY`, councilSafe `0xc6c2E9EFB898A42DB4137B07b727b45e0C353d81`), pool 27 strategy `0x9Fb2f1813228a97f559E29A6492EE27357FAF8A2` (5,496.40 HNY). Live cvParams: `maxRatio 8,160,578` (0.816), `weight 998,926`, `decay 9,999,958`, `minThresholdPoints 100e18`; `totalPointsActivated 5,069.63`. The full path is permissionless (verified by live `eth_call` probes): `stakeAndRegisterMember` (3 HNY, fee 0) → `activatePoints()` (allowlist for pool 27 is open to `address(0)`) → `increasePower` → `Allo.registerRecipient(27, CreateProposal{beneficiary, amountRequested X, HNY})` + 20 xDAI refundable collateral → `Allo.allocate` (support ≤ own power) → wait conviction → **permissionless `Allo.distribute`**. Conviction/threshold math was reproduced exactly against live `calculateThreshold`/`calculateProposalConviction` (9/9 integer matches). **The economic gate:** feasibility requires `X < (β−√ρ)·F ≈ 0.5·F ≈ 2,748 HNY` and `S_min ≈ 1.0–1.7×X`; the attacker's HNY round trip (buy S, sell S+X) runs through a market with $4.7k–11k usable HNY depth → realistic net −$291…−$832, optimistic +$174 (holder-funded variant ≈ +$800). **No reliable positive-EV extraction for a fresh market-funded attacker → E-U $0.** Sibling sDAI pools 8/67 (11,855.06 sDAI = $14,957) are **allowlist-gated** (closed 15-address list; `address(0)` not granted), so they stay outsider-closed; counterfactual if opened: +$3.0–3.3k (pool 67).

### 2.3 Orchid Lottery1 — no outsider claim path (fork-proven negative)

Deployed 2021-03-19 (block 15,089,781), verified source (Solidity 0.7.6). Accounts `accounts_[keccak256(token, funder, signer)]` hold `escrow<<128 | amount`. Value enters via `edit()` (native/ERC-20) and leaves via (a) the funder's own `edit(..., retrieve)` (self-service), or (b) `claim(token, recipient, Ticket[], refunds)` — which requires an **ECDSA signature by the account's signer** over a digest binding `chainid`, `address(this)`, `token`, `recipient`, `reveal`, `packed0`, `packed1>>1`, `data`; single-use enforced by `tracks_[keccak256(digest, signer)]`. The PoW field (`packed1` bits 161–224 ≥ hash) is grindable but irrelevant to the signature gate. Full event reconstruction: **30,407 Create events, 16,154 funders, 30,026 signers, 0 accounts with signer = address(0)** — so the classic "invalid signature → ecrecover(0)" drain has no target. Four sibling `OrchidLottery1` deployments (`0x1156ce59…`, `0x29e599B1…`, `0x733D9Ea7…`, `0xA01B3907…`) hold 0 xDAI / 0 tokens → $0.

---

## 3. Live-state assessment (all reads at block 48,767,754 unless noted)

**1Hive Aragon DAO**
- Vault/Agent `0x4ba7362F9189572CbB1216819a45aba0d0B2D1CB`: **21,398.659784944634936554 HNY**; 0 xDAI; no other meaningful tokens (HNYx = 0).
- Kernel `0x8ccbeab14b5ac4a431fffc39f4bec4089020a155`; 11 apps enumerated (SetApp history + live `kernel()`/`appId()`).
- CV `0x0B21081C…`: `contractPaused=false`, `decay=9,999,799`, `maxRatio=2,000,000`, `weight=10,000`, `minThresholdStakePercentage=2e17`, `requestToken=stakeToken=HNY`, `vault=Agent`, `totalStaked=8,298.27 HNY`, `proposalCounter=214`.
- DV `0xfBd0B272…`: `getSetting(0)` = (432000, 5e17, 1e17, 172800, 86400, 43200, 86400); last executed vote 19 (2023-11-22); last StartVote vote 20 (2024-03-14).
- Agreement `0x59A15718…`: `getCurrentSettingId()=1`; collateral requirement id 3 for both CV and DV = (HNY, 259,200 s challengeDuration, **6.061864241695410850 HNY** actionAmount, same challengeAmount); fees cashier = 0.
- Agreement staking pool `0x0E25B918C9Fb2fEA5d42011d1F4B9f8c61B453e7`: 243.0846 HNY (stakers' own → H-O).
- HNY `0x71850b7E9Ee3f13Ab46d67167341E4bDc905Eef9`: MiniMeToken, supply 75,429.94, controller = HookedTokenManager `0xEd062e26…` (mint = P).

**Gardens v2 (1Hive community)**
- RegistryCommunity `0xE2396fe2…` (ERC-1967 diamond, impl `0x7EFAb2C3…`): **5,694.657446335795 HNY** = Σ 65 members' `stakedAmount` (diff 0.0); `totalMembers=59`; `owner=0x00BcC26E792E393217bA895f5e85AE628FC994E9`; `proxyOwner=0x91ab7a20cc3aee799df908fa1b2571fe8e07394a` (upgrades active, latest 48,205,332 — P).
- Pool 27 `0x9Fb2f181…`: **5,496.398013724949977708 HNY**; funded by councilSafe 4,785.69 + `0x650e3062…` 1,696.06 + 11 small; one outflow: 1,000 HNY to councilSafe (proposal 4, block 39,070,697). No active proposals.
- sDAI pools 8/67: 1,309.88 + 10,545.18 sDAI; closed allowlists.
- 23 Gardens communities on Gnosis; total HNY ≈ 11,282.93 in Gardens contracts; all other pots dust.

**Orchid Lottery1**
- `0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82`: **99,906.63932355393 xDAI**. Account reconstruction from all 210,490 `Update` logs (last cache per key, 30,133 keys): **escrow 2,801.592591737934 + unescrowed 96,917.41293454739 = 99,719.005526285325808979 xDAI accounted**; **187.633797268604191021 xDAI unaccounted** (direct transfers; no sweep function → S). Token balances: only worthless airdrop spam (18 tokens, no value).

---

## 4. What an attacker can/cannot do (exact paths, preconditions, costs)

**CAN — 1Hive Aragon CV round (fork-proven):** buy `S` HNY on the open market → `Agreement.sign(1)` → stake ≥6.0618 HNY + `allowManager` → `CV.addProposal(…, R, false, attacker)` → `CV.stakeToProposal(pid, S)` → wait `t = ln(ρ/(ρ−1))/2.01e-5` blocks (ρ = S/S_min; ~6.9 d at 1.1×) → anyone calls `executeProposal` → vault pays `R` HNY. Preconditions: HNY to stake (market depth caps `S`), no challenge. Cost: DEX round trip on `S` (~0.4 % of notional; pools restore) + gas (cents) + 6.06 HNY collateral (returned). Net modeled: **+$840 (R=1,000, S≈695) … +$2,115 (R=3,000, S≈3,710)**, hard-currency-only floor +$1.6k.

**CAN — 1Hive Aragon DV full drain (fork-proven):** acquire 7,600 HNY **at one block** (snapshot N−1), `sign`, stake collateral, `DV.newVote(script)` with script `0x00000001 + Agent + len + Agent.execute(HNY,0,transfer(attacker,vault))`, `vote(vid,true)`, wait 5 d + 1 d delay, anyone `executeVote(vid,script)` → **entire vault to attacker**. Preconditions: one-block acquisition of 7,600 HNY (~$22.3k modeled, from 16 pools with 11,408 HNY inventory) + no challenge + no NO coalition >7,600 HNY. Net modeled **+$6,442** (realization-weighted) / +$3.9k hard-currency-only.

**CANNOT — Gardens v2 pool 27:** drain profitably. The path is open but `S_min ≈ 1.0–1.7×X` against $4.7k–11k usable HNY depth → net −$291…−$832 (optimistic +$174). Max one-proposal X ≈ 2,748 HNY.
**CANNOT — Gardens RC / sDAI pools 8/67:** RC funds are members' collateral (exact reconciliation); sDAI pools are allowlist-gated (non-listed members revert `UserCannotExecuteAction`).
**CANNOT — Orchid:** claim without the signer's ECDSA signature; no signer=0 accounts; replay/chain/contract binding; `mark`/`save` are self-scoped; unaccounted 187.63 xDAI has no account key and no sweep.

**Costs/capital summary:** CV path $0.7k–$5.4k capital for +$0.8k–$2.1k; DV path $22.3k for one block for +$3.9k–$6.4k; both pay out in HNY (exit is the binding constraint); no HNY lending market exists on Gnosis (Aave v3 checked) → flash loans cannot span the multi-day hold.

---

## 5. PoC / fork-verification (CI)

**Files:** `poc/test/GnosisResidual.t.sol` (Foundry, fork of Gnosis at block 48,767,754; `poc/foundry.toml`; vendored `poc/lib/forge-std`).

**Tests (all 5 PASS locally; CI run — see below):**

| Test | What it proves | Key numbers (fork) |
|---|---|---|
| `test_cv_outsider_extraction` | Fresh address creates proposal 214 → vault pays it 1,000 HNY; negative control (pre-conviction execute reverts `CV_INSUFFICIENT_CONVICION`); bystander executes | vault 21,398 → 20,398 HNY; attacker +1,000 HNY; threshold 3.1950241e25 = live `calculateThreshold`; gas 1,927,296 |
| `test_dv_full_vault_drain` | Fresh address with 7,600 HNY at one snapshot creates vote 21 → passes with its own YES → bystander executes → **entire vault drained** | vault 21,398 → **0 HNY**; attacker receives 21,398.66 HNY; gas 1,588,447 |
| `test_orchid_forged_ticket_no_payout` | Forged ticket against a real account (funder `0x8DF9Bd5b…`, signer `0xCF3ce759…`, 50 xDAI escrow): ecrecover→0 → no account → $0 | pot unchanged; attacker $0; victim escrow untouched |
| `test_orchid_selfsigned_ticket_no_payout` | Attacker self-signs a valid ticket naming the victim funder → no (0,funder,attacker) account → $0 | pot unchanged; attacker $0 |
| `test_orchid_funder_self_withdraw` | H-O control: funder deposits 1 xDAI and withdraws it via `edit()` | funder balance restored |

**CI:** GitHub Actions on `artsbykriss/ca-zombie-ci` (run URL in `ci-log.txt` / below) — `forge test -vvv`. **CI run:** `https://github.com/artsbykriss/ca-zombie-ci/actions/runs/<RUN_ID>` (fill on completion; see `ci-log.txt`).

**Fork technique note:** HNY is a MiniMeToken with checkpoint balances; `deal()` cannot write it. Acquisition is simulated with a `vm.store` checkpoint write (`balances` mapping = slot 8) at the fork block; the market buy leg itself is modeled off-chain (see `analysis/1hive-aragon.md` §2.3/§4 and `analysis/gardens-v2.md` §4).

---

## 6. Verdict and residual/latent risk

| Category | USD | Confidence | Basis |
|---|---|---|---|
| **E-U (external unprivileged)** | **$6,442 modeled full-vault extraction via governance capture (1Hive Aragon); per-round $840–$2,115; hard-currency floor ≈$1.6k; Gardens v2 $0; Orchid $0** | **medium** (mechanics fork-proven; market realization modeled; community-challenge/NO-vote gated) | ACL + live params + fork PoC + DEX depth model |
| H-O | $105,577.66 | high | Orchid funder escrow $99,705.33 + Gardens RC members' collateral $5,574.65 + Gardens small-community stakes $59.72 + 1Hive Agreement staking pool $237.96 |
| P | $20,517.30 | high (paper) | 1Hive vault remainder $14,505.20 (paper beyond modeled realization) + Gardens pool 27 $5,380.53 (governance-open but net-negative for a fresh attacker) + councilSafe 645.16 HNY $631.57 |
| S | $217.97 | high | Orchid unaccounted 187.63 xDAI $187.61 + Gardens stranded dust (30+1+0.01 HNY) $30.36 |

**Total live value analyzed: ≈ $132,755** (Orchid $99,892.94 + HNY pots $32,862.30). E-U is a subset of the vault's paper value, not additive with P.

**Residual/latent risk:**
- **1Hive vault:** the single largest live-capture risk found in this cluster. If HNY liquidity deepens (≥$100k HNY-side), the entire $20.9k becomes cleanly extractable and the DV path becomes strictly profitable. The community's only defenses are the 6.06 HNY Agreement challenge (pauses; needs Celeste liveness) and a >7,600 HNY NO coalition (turnout historically 4.8–6.8k).
- **Gardens v2:** flips positive if HNY depth grows or for an HNY-holding attacker (~+$800 one-shot, P-blockable via `setPoolParams`). The sDAI pools (8/67, $14,957) become the best Gardens target the moment their allowlists open.
- **Orchid:** no outsider path; the 2,801.59 xDAI of *escrowed* balances require funder warn+1 day to recover; accounts with lost signer keys are effectively stuck (indistinguishable on-chain). The 187.63 xDAI surplus is permanently stuck (S).
- **Cross-target note:** the same "dormant-DAO capture" pattern applies to any Aragon DAO whose `CREATE_PROPOSALS_ROLE`/`CREATE_VOTES_ROLE` is `ANY` and whose vault is funded.

---

## 7. Methodology & sources

- On-chain reads via public RPCs `https://rpc.gnosischain.com` (full-range `eth_getLogs`) and `https://gnosis-rpc.publicnode.com` (calls; 50k-block log cap), at pinned blocks (48,767,754 / 48,767,091 / 48,768,354–48,768,818).
- Verified sources: Blockscout `gnosis.blockscout.com/api/v2` for ConvictionVoting `0x4E189151…`, Agreement `0xE2B44F20…`, DisputableVoting `0x4fdC6f06…`, Agent, HNY, OrchidLottery1, Gardens facets (`analysis/src_live/`, `analysis/src_apps/`, `analysis/src/`); Gardens v0.0 sources fetched at deployment commit `c1350890…` (2024-10-08) — live code is the newer diamond version (facet sources in `analysis/src_live/`).
- Prices: DefiLlama (`coins.llama.fi`), on-chain reserves (`getReserves`), sDAI `convertToAssets`.
- PoC: Foundry 1.7.1, fork-only; CI on GitHub Actions (public repo).

**Caveats & limitations**
- The 1Hive net-dollar figures are **models** (constant-product routing with per-quote realization weights over live reserves), not fork-executed market trades; the governance *mechanics* are fork-proven end-to-end. Challenge/arbitration outcomes (Celeste liveness) and community mobilization are not modeled.
- HNY realization assumes patient liquidation; thin pools are racily arbed; quote-token USD values (FOX/AGVE/BREAD/WATER) are pool-implied.
- Gardens pool-27 verdicts rely on live `eth_call` probes + exact conviction math reproduction (no fork PoC; the negative result does not require one).
- Orchid H-O assumes funders retain their keys/signer addresses; on-chain we cannot distinguish lost-key accounts.
- No keyed RPC URLs or secrets are present in any file in this folder (verified by grep).

## 8. Files index

- `README.md` — this report · `summary.json` — machine-readable summary
- `poc/` — Foundry project (`test/GnosisResidual.t.sol`, 5 tests) · `ci-log.txt`, `ci-artifacts/` — CI evidence
- `analysis/1hive-aragon.md` + `1hive-*.json` — full Aragon audit (apps, ACL matrix, live state, economics, pools)
- `analysis/gardens-v2.md` + `gardens-*.json` + `analysis/src_live/` — Gardens v2 audit (diamond facets, live state, conviction sim, market model, sDAI extension)
- `analysis/orchid_*.json|py|sol` — Orchid reconstruction (210,490 Update logs → per-key final state; Create-event stats; verified source)
- `analysis/src_apps/` — verified ConvictionVoting/Agreement/DisputableVoting sources + ABIs used by the PoC
