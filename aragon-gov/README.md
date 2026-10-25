# Aragon-legacy governance — ACL permission-manager escalation (ZH4-PASS7 P7-01)

**Date:** 2026-10-25 · **Chain:** Ethereum mainnet (1) · **Status:** READ-ONLY; PoC **fork-verified only**; no mainnet transaction signed or sent.
**Role:** independent Tier-2 HIGH deep-dive of `zombie-hunt-iv/pass7/gov-capture.md` §2.1 / `pass7/README.md` §P7-01, **and a reconciliation of our own prior "$0" verdict** (`ci/ZH4P2-RESULTS-TRACKER.md`, `ci/qc/exotic-legacy-QC-VERIFY.md` §2).

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why closed/open | Latent risk |
|---|---|---|---|
| Aragon-legacy funded DAOs where **Voting = ACL manager of the holding app's `TRANSFER_ROLE`** | **$0 today** | vote-creation is TokenManager/EOA-gated and the governance tokens have no acquirable market; snapshot is `block-1` (non-atomic) | **227.30 ETH (~$534k)** across **2,002** DAOs re-arms the moment a token gets a real AMM listing |
| Aragon "closest" cases (minAQ = 0 + TokenManager) | **$0 today** | need only a *dust* amount of the token, but the token has no pool | e.g. **1.71 ETH** at DAO `0xf6b32eee…` (token `BBIZ`, supply = 2) |
| ANT DAO `0x2de83b50…` (2.20 ETH, liquid ANT, minAQ = 0) | **$0 today** | **no TokenManager** and `CREATE_VOTES_ROLE` is held by a **2-of-3 Gnosis MultiSigWallet `0xcafE1A77…`** ⇒ an outsider cannot create a vote | one listing away, but creation is the blocker here |
| Stuck DAOs — **46** holding apps whose governance token `totalSupply == 0` | **$0 — stuck (S)** | no vote can ever be created (`_newVote` reverts `ERROR_NO_VOTING_POWER`); includes the 100-ETH DAP `0xb61beac3…` vault `0xf527f6ff…` | none |

**Total live unprivileged extractable now: $0** (confidence **high**).
**E-U-conditional (latent): 227.30 ETH ≈ $534,466** at ETH = $2,351.36 (DefiLlama, 2026-10-25) — the exact figure is the sum of ETH held by the 2,002 manager-funded holding apps. Of this, **100.104 ETH (≈ $235,380) is stuck (S)** (46 DAOs, token supply 0) and **127.197 ETH (≈ $299,086) is governance-movable (P)** by the DAOs' own token holders.

**Headline:** our prior **$0 number is correct and confirmed**, but our prior **mechanism and re-arm trigger were wrong**. The Aragon-legacy class is *not* closed because "governance cannot move vault funds" — the Voting app **is** the ACL permission-manager for the holding app's `TRANSFER_ROLE` on **2,002 of 2,202** funded DAOs and an executed proposal **can** `grantPermission` → `transfer` (fork-proven here, 2 ETH moved). It is closed only because the governance tokens cannot be acquired (illiquid) and vote creation is gated. The correct trigger is **an AMM listing of any of these DAO tokens**, not a missing vault permission.

---

## 2. The mechanism, in exact terms

Aragon DAOs (`aragonOS` 4.x) install a `Kernel` + `ACL` + apps. The relevant deployed code:

- **`Voting`** (`aragon_voting_impl` — appId `0x9fa3927f…`): `newVote(bytes,string)` is `auth(CREATE_VOTES_ROLE)`. A decided vote runs `runScript(vote_.executionScript, …)`.
- **`EVMScriptRunner.runScript`** `delegatecall`s the registered executor (`CallsScript`, spec id `1`). Because it is a **delegatecall**, every call the script makes is executed **with `msg.sender == the Voting app`** (verified in source, line 907 of `analysis/acl_impl.sol` bundle / the Voting source).
- **`ACL`** (`analysis/acl_impl.sol`): `grantPermissionP(entity, app, role, params)` is gated by `onlyPermissionManager(app, role)` → `require(msg.sender == getPermissionManager(app, role))`. And `evalParams()` returns **`true`** whenever the stored params hash is `EMPTY_PARAM_HASH` — so a plain `grantPermission` (empty params) satisfies even a parameterised `authP` check.
- **Holding app** (`Vault`/`Agent`): `transfer(address _token, address _to, uint256 _value)` is `auth`/`authP(TRANSFER_ROLE, …)`.

⇒ On any DAO where `getPermissionManager(holding, TRANSFER_ROLE) == voting`, a passed proposal can execute:

```
CallsScript([
  ACL.grantPermission(voting, holding, TRANSFER_ROLE),   // msg.sender == voting == manager  -> OK
  Holding.transfer(0x0, attacker, holding.balance)       // msg.sender == voting, now has role -> OK
])
```

This is exactly what pass 7 asserted; it is re-proven here from source **and** on a fork.

### 2.1 Vote creation (the gate)

- Direct `Voting.newVote` needs `CREATE_VOTES_ROLE`.
- **`TokenManager.forward(bytes)`** (source `analysis/tokenmanager_impl.sol`, line 2010) is `canForward = hasInitialized() && token.balanceOf(sender) > 0` — i.e. **any token holder** may make the TokenManager run an arbitrary script, and the TokenManager **holds `CREATE_VOTES_ROLE`** on the Voting app. So a token holder can always create a vote in a DAO that has a TokenManager (`tmCanCreate == true`).
- In a minority of DAOs `CREATE_VOTES_ROLE` is open to `ANY_ENTITY` (`anyCanCreate == true`) — then anyone can create a vote.
- If neither holds (no TokenManager **and** no `ANY`), creation is EOA/manager-gated.

### 2.2 Passing (the decisive gate)

Voting power is `token.balanceOfAt(voter, block.number - 1)` and total power is `token.totalSupplyAt(block.number - 1)` (1-block snapshot). A vote passes when `yea / totalSupply > minAcceptQuorumPct` **and** `yea / (yea+nay) > supportRequiredPct`. To pass, the attacker must **hold `minAQ · totalSupply` of the governance token at the block-1 snapshot**. Because the snapshot is one block deep, a same-transaction flash loan does **not** work; a one-block hold (or a real purchase) is required. With `minAQ == 0` a *dust* amount suffices.

⇒ The only genuine gate left is **acquiring the governance token**. Today none of the funded DAO tokens is acquirable.

---

## 3. Live-state assessment (all reads 2026-10-25, Ethereum mainnet)

| DAO | holding app | ETH | token | `getPermissionManager(holding, TRANSFER_ROLE)` | `anyCanCreate` | `tmCanCreate` | creation gate |
|---|---|---|---|---|---|---|---|
| `0x23b5db33…` | Agent `0xbcd768c5…` | 2.9006 | FAST | **= Voting `0x9970cc7e…`** | false | **true** | TokenManager (holder) |
| `0x3173b169…` | Vault `0x86c5b626…` | 0.7000 | VT | **= Voting `0x328b0b8c…`** | **true** | true | open |
| `0x2de83b50…` | Vault `0xaacccafc…` | 2.2012 | ANT | **= Voting `0xcfee4d30…`** | false | *no TokenManager* | **2-of-3 MultiSig `0xcafE1A77…`** |
| `0xf6b32eee…` | Agent `0x7ea598f2…` | 1.7100 | BBIZ | **= Voting `0x01be3102…`** | false | **true** | TokenManager (holder) |
| `0x001cd74c…` | Vault `0x51faf92e…` | 14.0243 | SHILL | **= Voting `0xbdcc7647…`** | false | **true** | TokenManager (holder) |
| `0xb61beac3…` (DAP) | Vault `0xf527f6ff…` | 100.0000 | `0xff3ad523…` | = Voting | false | false | token `totalSupply == 0` ⇒ **stuck** |

ACL source used: implementation `0x81f7564e413586f1f99fde55740ac52b43ca99c9` (`analysis/acl_impl.sol`), Voting implementation `analysis/aragon_voting_impl.sol`, TokenManager implementation `0xde3a93028f2283cc28756b3674bd657eafb992f4` (`analysis/tokenmanager_impl.sol`), Agent implementation `0x3a93c17fc82cc33420d1809dda9fb715cc89dd37` (`analysis/agent_impl.sol`).

### 3.1 Enumeration (independent)

- **Funded set:** 2,202 holding apps with a non-zero ETH balance (from the pass-7 `NewAppProxy` census; re-used as the input list, re-read on-chain).
- **Permission-manager re-read:** `analysis/verify_manager_sample.py` re-read 116 funded DAOs from chain → **107 (92.2 %)**; the **full CI re-read** (`analysis/full_scan.py`, run `40228662961`) read all 2,202 and found **2,001** manager-funded (one row missed to a transient RPC error; the true count is **2,002 / 2,202 = 90.9 %**, matching pass 7 exactly).
- **ETH total (manager-funded):** **227.3013 ETH**.
- **Vote-creation surface:** TokenManager present on **1,940 / 2,001** manager-funded DAOs; `ANY`-open `newVote` on **308**.
- **Token liquidity (independent, broader than pass 7):** pass 7 only scanned `minAQ ≤ 20 %` (1,368 DAOs) and found 38 with any Uniswap V2/V3/Sushi pool. The CI scan of **all 2,001** manager-funded tokens found **54** with any pool, and measured **pool depth vs the minAQ quorum** (`analysis/full_scan.py`). Only **9** of those 54 can actually supply `minAQ · totalSupply` — and **all 9 hold 0.00 ETH**. No token's existing pool enables a funded drain (see §5).
- **Stuck classification:** `analysis/supply_scan.py` read `totalSupply()` for all 2,002 manager-funded tokens → **46** with supply 0 (**100.104 ETH** stuck). A cross-check with DexScreener found **no pairs** for the top `minAQ == 0` candidate tokens.

---

## 4. What an attacker can / cannot do

**Can (fork-proven, §6):**
- From a passed proposal (i.e. from the Voting app): `grantPermission` itself `TRANSFER_ROLE` on the holding app, then `transfer` the holding app's ETH out. Moved **2 ETH** out of Agent `0xbcd768c5…`.
- Full end-to-end, once the attacker holds `minAQ · totalSupply` at block-1: `newVote` (or `TokenManager.forward`) → `vote` → `executeVote` → drain. Drained the **0.70 ETH** vault `0x86c5b626…` (ANY-open) and the **1.71 ETH** agent `0x7ea598f2…` (minAQ = 0, one token).

**Cannot (today):**
- Acquire any funded DAO's governance token — no pool holds the required amount, and the tokens are otherwise untradeable.
- Create a vote on the DAOs where creation is EOA-gated **and** there is no TokenManager (e.g. the ANT DAO).
- Flash-loan the quorum in one transaction — the snapshot is `block.number - 1`.

**Preconditions / costs for the conditional path:** buy `minAQ · totalSupply` of the token (net of the round-trip), hold 1 block, create the vote, wait `voteTime` (1–3 days), `executeVote` (permissionless), drain. No capital beyond the token purchase; no protocol privilege.

---

## 5. At-risk set, exact trigger, closest DAOs

- **At-risk set (E-U-conditional):** the **2,002** funded DAOs where Voting is the holding app's `TRANSFER_ROLE` manager — **227.301 ETH ≈ $534,468**. Re-read confirmation and the full per-DAO table are produced by the CI job (`ci-out/aragon_at_risk.json`).
- **Exact trigger:** the first real AMM listing (Uniswap/Sushi/etc.) with enough depth to buy `minAQ · totalSupply` for **any** of these DAO tokens. At that moment the ACL escalation becomes buyable and the DAO's ETH is drainable in `voteTime` (1–3 days) + 1 block.
- **Closest DAOs (smallest acquisition hurdle):** the `minAQ == 0` + TokenManager cases need only a **dust** amount of the token:
  - `0xf6b32eee…` — 1.7100 ETH, token `BBIZ` (`totalSupply == 2`), minAQ = 0, support 50 %, TokenManager present.
  - `0xa323b631…` — 0.3000 ETH, token `MTX`, minAQ = 0, TokenManager present.
  - `0x04cd638d…`, `0x1b7610d9…` — 0.11 ETH each, minAQ = 0, TokenManager present.
- **Largest funded with an existing (but empty) pool:** `0x001cd74c…` — **14.024 ETH**, token `SHILL`, minAQ = 30 %. Its only Uni V2 WETH pool `0x83db7504…` holds **0.0856 SHILL** of the **75,674 SHILL** needed (acquirable fraction 1e-6) — unusable.
- **The single most-reachable DAO:** `0x2de83b50…` — **2.2012 ETH**, token `ANT` (real Uni V2/USDC/Sushi/DAI markets; acquirable fraction ≈1.8e14), minAQ = 0, **but no TokenManager** and `CREATE_VOTES_ROLE` held by a **2-of-3 Gnosis MultiSigWallet `0xcafE1A77…`** (owners `0xE8068556…`, `0x946138B0…`, `0xDafBD7d6…`) ⇒ creation is privileged. This is the *only* funded DAO where the token is acquirable; it is blocked by exactly one gate.
- **Acquirable but empty:** the CI scan flags **9** DAOs whose pool can supply the minAQ quorum — **all 9 hold 0.00 ETH** (`ci-out/aragon_at_risk.json`).
- **Stuck (S):** **46** manager-funded holding apps whose governance token `totalSupply() == 0` — **100.104 ETH ≈ $235,380**. Largest: DAP `0xb61beac3…` vault `0xf527f6ff…` **100.000000 ETH** (token `0xff3ad523…` supply 0). A zero-supply token can never create a vote, so nobody — not even governance — can move these funds. (`analysis/supply_scan.py`, `analysis/token_supply.json`.)

---

## 6. PoC / fork verification

`poc/` (Foundry 0.8.24, `lib/forge-std` vendored). **Read-only mainnet; fork-only.**

| Test | What it proves | Result |
|---|---|---|
| `test_live_permission_manager_relationship` | live `getPermissionManager(holding, TRANSFER_ROLE) == voting` on 4 funded DAOs; role not held pre-escalation | PASS |
| `test_acl_escalation_impersonated_proposal` | Voting (as an executed proposal) `grantPermission` → `transfer` drains **2 ETH** from Agent `0xbcd768c5…` | PASS |
| `test_full_proposal_path_any_open_vault` | full `newVote`→`vote`→`executeVote` drains the **0.70 ETH** vault (token acquisition simulated) | PASS |
| `test_closest_conditional_minAQ0_tokenmanager` | minAQ = 0 + TokenManager: **one** token → drains the **1.71 ETH** agent; asserts no Uni V2 pool today | PASS |
| `test_negative_direct_transfer_reverts` | outsider `Holding.transfer` → `APP_AUTH_FAILED` | PASS |
| `test_negative_newVote_gated_ant_dao` | outsider `newVote` on the ANT DAO → `APP_AUTH_FAILED` (EOA-gated creation) | PASS |

Local run: **6/6 PASS**, fork block **26,271,647** (`https://eth.drpc.org`). Official CI run (GitHub Actions `artsbykriss/ca-zombie-ci`): see §9.

The two "full path" tests **simulate the trigger** by minting the governance token to the attacker from the token's own controller (a MiniMeToken whose controller is the DAO's TokenManager) at block N-1, then rolling to block N so the vote snapshot sees the balance. This is exactly the state an AMM listing would create; it is **not** a claim that the tokens are acquirable today.

---

## 7. Verdict

**E-U live: $0 (high confidence).** **E-U-conditional: 227.30 ETH ≈ $534,466**, re-armed by any AMM listing of the affected governance tokens. Of this, **S (stuck) = 100.104 ETH ≈ $235,380** (46 DAOs, token supply 0) and **P (governance-movable) = 127.197 ETH ≈ $299,086**. The prior corpus's "$0" is confirmed; its *mechanism/trigger* is corrected (see §8).

---

## 8. Reconciliation with our prior $0 verdict (mandate #2)

**Our prior row** (`ci/ZH4P2-RESULTS-TRACKER.md`; cluster report + `ci/qc/exotic-legacy-QC-VERIFY.md` §2): Aragon-legacy **E-U $0**, P ≈ $278.6k, **S $240k**; decisive evidence: *2,306 standard Voting apps, **0 with `voteTime=0`**; `newVote` from `0x…dEaD` → `APP_AUTH_FAILED`; tokens illiquid; DAP token supply 0*.

**What pass 7 got right, and what we missed:**

1. **We tested the wrong decisive gate.** We probed `Holding.transfer` *directly* from an outsider and saw `APP_AUTH_FAILED`, then concluded "governance cannot move vault funds". That is the **pre-escalation** state. The real path is an executed proposal that first calls `acl.grantPermission(voting, holding, TRANSFER_ROLE)` — and the Voting app **is the permission-manager**, so that call succeeds — and *then* `transfer`. We never traced the proposal-execution path (`runScript` delegatecalls `CallsScript`, so the script's calls run as the Voting app). The QC even recorded "TRANSFER_ROLE manager is Voting" for the DAP, but we never connected that fact to an escalation primitive; we treated the missing `CREATE_VOTES_ROLE` as the whole story.
2. **"0 `voteTime=0`" was a true statement but a non-decisive check — not a hidden instant path.** There genuinely is no `voteTime=0` in the census. So it is **not** a "false negative" in the sense that an instant same-transaction path existed. It **was** the wrong lens for this class: the Aragon path is deliberately *slow* (`voteTime` 6 h – 48 h), yet it is still a genuine E-U path once the token is acquirable. The check gave false confidence that the class was closed, and it steered the recorded re-arm trigger to "the vault permission is missing" instead of the correct "token liquidity / vote-creation".
3. **We understated the creation surface.** We only probed direct `newVote` from `0x…dEaD`. We missed `TokenManager.forward(bytes)` — any token holder can make the TokenManager (which holds `CREATE_VOTES_ROLE` on ~1,941/2,002 funded DAOs) create a vote.
4. **Our enumeration had a hole.** pass 7's liquidity scan covered only `minAQ ≤ 20 %` (1,368 DAOs). We extended it to all 2,002 manager-funded DAOs and added pool-depth-vs-quorum. The extra coverage surfaced the largest candidate, `0x001cd74c…` (**14.02 ETH**, token `SHILL`, minAQ = 30 %) — which *does* have a Uni V2 WETH pool — but the pool holds only 0.0856 SHILL of the 75,674 needed, so it remains unreachable. Net verdict unchanged.

5. **Correction *to* pass 7 (independent).** pass 7 states the ANT DAO's creation gate is "a plain EOA `0xcafe1a77…` (code size 0)". On-chain, `0xcafE1A77e84698c83CA8931F54A755176eF75f2C` is **not** an EOA — it is an **8,110-byte `MultiSigWallet`** (solc 0.4.8), **2-of-3** (owners `0xE8068556…`, `0x946138B0…`, `0xDafBD7d6…`, 366 transactions), and it *holds* `CREATE_VOTES_ROLE` (`hasPermission(multisig, voting, CREATE_VOTES_ROLE) == true`). The verdict is unchanged (the gate is still privileged, not E-U), but the *nature* of the gate is an M-of-N multisig, not a keyless EOA.

**Bottom line:** the number ($0 today) was right; the reasoning and the trigger were wrong. The class was closed for the wrong reason, which is exactly why the re-arm trigger must be rewritten to **"any affected DAO token gets an AMM listing"**.

---

## 9. Methodology, sources, CI

- **On-chain:** keyless public RPCs (`ethereum-rpc.publicnode.com`, `eth.drpc.org`, `1rpc.io/eth`) + Etherscan V2 for verified source. No secret RPC URLs or keys are stored in this folder.
- **Sources:** `analysis/acl_impl.sol` (ACL impl `0x81f7564e…`), `analysis/aragon_voting_impl.sol` (Voting app), `analysis/tokenmanager_impl.sol` (TokenManager impl `0xde3a9302…`), `analysis/agent_impl.sol` (Agent impl `0x3a93c17f…`).
- **Enumeration inputs:** `analysis/aragon_join.json` (2,202 funded holding apps), `analysis/aragon_apps.json` (installed apps), `analysis/aragon_instant_params.json` (voting params) — from the pass-7 census, re-read independently here.
- **Scripts:** `analysis/verify_manager_sample.py` (sample re-read), `analysis/at_risk.py`, `analysis/probe_candidates.py`, `analysis/full_scan.py` (full enumeration; runs in CI).
- **CI:** `ci/run.sh` runs the full enumeration (`full_scan.py`), then `forge test -vvv` runs the fork PoC. GitHub Actions run URL and `ci-out/*.json` are recorded in `ci-log.txt` / `ci-artifacts/`.

### Caveats & limitations
- Point-in-time (2026-10-25). All balances/roles move; re-read before acting.
- The PoC's "full path" tests simulate token acquisition; they prove the *mechanism* end-to-end, not that the tokens are buyable today.
- The `voteTime`/snapshot semantics mean a real attack spans multiple blocks and 1–3 days; it is a **buyable-if-listed** path, not an atomic one.
- 46 Aragon apps with custom appIds (Lido, API3) are outside the standard-`voting` census (prior QC); none is a funded holding app with the escalation relationship, so they do not change the verdict.
- No transactions were signed or sent; no secrets in this folder.

### Files index
`README.md` · `summary.json` · `analysis/` (sources, scripts, scan JSONs) · `poc/` (Foundry project) · `ci/run.sh` · `ci-out/` · `ci-log.txt` · `ci-artifacts/`
