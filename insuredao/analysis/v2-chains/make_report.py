#!/usr/bin/env python3
"""Generate REPORT.md from state.json + embedded evidence. Run after followup.py."""
import json

state = json.load(open("state.json"))

IMPL_NAMES = {
    "0x576e74c0e1adb96b58f2237510853bc7d2561ebe": "MarketTemplate (solc 0.8.12)",
    "0xcb146803913cbfaa66c04e7fefc288af95c05af1": "IndexTemplate (solc 0.8.12)",
    "0xf2f7e2b6334eec33409f00e1da35b303a6ac8970": "ReserveTemplate (solc 0.8.12, no clone deployed)",
    "0x4763f9720603342aad40056db65883bd55355945": "MarketTemplate (solc 0.8.12)",
    "0x016d4eb10fbce28010fde53c68c016b611b1aa0a": "IndexTemplate (solc 0.8.12)",
    "0x0074976043140a371aead31189c2be459950c816": "PoolTemplate (solc 0.8.10)",
    "0x734afd33dfb5100ee91efe690526dffdedbe0cf4": "IndexTemplate (solc 0.8.10)",
}

CHAIN_META = {
    "arbitrum": {
        "chain_id": 42161,
        "token": "USDC.e 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8 (6 dec)",
        "vault": "0x968C9718f420d5D4275C610C5c217598a6ade9f9",
        "registry": "0x0fa85C39c96A9172CcCa7F84CE68E08A2BB971C1",
        "ownership": "0x62B86b6274DFa4Cc16beD9995E302A56D18891E2",
        "factory": "0xeACe965860d5a33695a2d08f9fA8C4118A38712F",
        "params": "0x3956fEaEF1821bE55B66eBB707B4aBcefD84c0A2",
        "controller": "0xE5E32AD53c183e7eEd57b226a93769DBcC21705F (AaveV3Strategy)",
        "owner_nonce": 77,
    },
    "optimism": {
        "chain_id": 10,
        "token": "USDC 0x7F5c764cBc14f9669B88837ca1490cCa17c31607 (6 dec)",
        "vault": "0x54F23d2fdC1E17D349B1Eb14d869fa4deD6A6D2b",
        "registry": "0x636938b5fF717F525C696F8961B9A1AEC38749A1",
        "ownership": "0x7dF2501C62b56f8dd5F1644bfC4300A517CE22BC",
        "factory": "0x6a9A52C8e17AeAD4f11De66282Ba6440818cf33E",
        "params": "0x5e204BF6eF5CD2594DfEb131608a8770d6A1a907",
        "controller": "0xdb8502a16efc7074ed1dd1e087d6616851c3374e (AaveV3Strategy)",
        "owner_nonce": 666,
    },
    "astar": {
        "chain_id": 592,
        "token": "USDC 0x6a2d262D56735DbA19Dd70682B39F6bE9a931D98 (6 dec)",
        "vault": "0x190dA1B9fA124BD872e9166bA3c7Dd656A11E8F8",
        "registry": "0xd0Df5A352D74A746754C592a6277c9060A7c9c87",
        "ownership": "0x4810fa5942A322c7bD30519eD3Ebe732066c3db3",
        "factory": "0x7Fcd5370be47cEC0FC0a7Fe91230432dd34DdeA1",
        "params": "0xCa1FeE73b00c221966E5f25226402146BdffE259",
        "controller": "none (controller()==0, keeper()==0)",
        "owner_nonce": 70,
    },
}

OWNER = "0x2c9bC901f39F847C2fe5D2D7AC9c5888A2Ab8Fcf"
OWNER_ATTR = {  # raw 6-dec units, read at latest
    "arbitrum": 376475435,
    "optimism": 153800391,
    "astar": 18863572,
}
FORMER_ASTAR_OWNER = "0x878bfba05b1d7c8c10868cb51be0732ed8c81646"
FORMER_ASTAR_OWNER_ATTR = 75702994  # raw 6-dec; earned as fee recipient while interim owner (blocks 1,667,152 - 4,125,874)

EVIDENCE_GATES = """```
# All executed as eth_call at latest (keyless RPCs), caller = 0x2222...2222 (no role). No transactions were sent.
ARB vault.borrowValue(1,attacker)   -> revert "Caller is not allowed to operate"      (onlyMarket)
ARB vault.withdrawValue(1,attacker) -> revert "WITHDRAW-VALUE_BADCONDITIONS"         (no attribution of caller)
ARB vault.addValue(1,attacker,attacker) -> revert "Caller is not allowed to operate"  (onlyMarket)
ARB vault.offsetDebt(1,attacker)    -> revert "ERROR_REPAY_DEBT_BADCONDITIONS"       (no attribution of caller)
ARB vault.utilize(1)                -> revert "Caller is not allowed to operate"      (onlyController)
ARB vault.setController(attacker)   -> revert "Caller is not allowed to operate"      (onlyOwner)
ARB registry.addPool(attacker)      -> revert "ERROR: UNAUTHORIZED_CALLER"            (factory/owner only)
ARB market.applyBounty(...)         -> revert "Caller is not allowed to operate"      (parameters.getOwner() only)
ARB market.redeem(0,1,[])           -> revert "ERROR: NO_APPLICABLE_INCIDENT"         (marketStatus != Payingout)
ARB market.registerIndex()          -> revert "Not an Official Pool"                  (msg.sender not listed)
ARB index.setLeverage(2e6)          -> revert "Caller is not allowed to operate"      (parameters.getOwner() only)
ARB controller.emergencyExit(attacker) -> revert "OnlyOwner"                          (onlyOwner)
ARB ownership.commitTransferOwnership(attacker) -> revert "Caller is not allowed to operate"

OP  vault.borrowValue/withdrawValue/utilize/setController -> same reverts as ARB
OP  registry.addPool(attacker)      -> revert "ERROR: UNAUTHORIZED_CALLER"
OP  market.applyBounty / applyCover -> revert "Caller is not allowed to operate"
OP  market.redeem(0,1,[])           -> revert "ERROR: NO_APPLICABLE_INCIDENT"
OP  index.set(0,attacker,100)       -> revert "Caller is not allowed to operate"
OP  controller.emergencyExit(attacker) -> revert "OnlyOwner"

AST vault.borrowValue(1,attacker)   -> revert "ERROR_ONLY_MARKET"                     (onlyMarket)
AST vault.withdrawValue(1,attacker) -> revert "WITHDRAW-VALUE_BADCONDITIONS"
AST vault.utilize()                 -> revert (bare)                                   (controller==0)
AST vault.setController(attacker)   -> revert "Caller is not allowed to operate"
AST registry.supportMarket(attacker)-> revert "ERROR: UNAUTHORIZED_CALLER"
AST market.applyCover/applyBounty   -> revert "Caller is not allowed to operate"
AST market.redeem(0,1,[])           -> revert "ERROR: NO_APPLICABLE_INCIDENT"
AST market.resume()                 -> revert "ERROR: UNABLE_TO_RESUME"
AST market.registerIndex(0)         -> revert "ERROR: UNREGISTERED_INDEX"
AST index.compensate(1)             -> revert "COMPENSATE_UNAUTHORIZED_CALLER"
AST index.lock()                    -> revert (bare, allocPoints[msg.sender]==0)
AST index.resume()                  -> revert "ERROR: MARKET_IS_NOT_LOCKED"
AST ownership.commitTransferOwnership(attacker) -> revert "Caller is not allowed to operate"
```"""

EVIDENCE_FACTORY = """```
# Factory TemplateApproval events (complete history), verified per chain:
#  ARB: MarketTemplate 0x576e74.. (approval=true, isOpen=TRUE, dup=false); IndexTemplate 0xcb1468.. (false); ReserveTemplate 0xf2f7e2.. (false)
#  OP : MarketTemplate 0x4763f9.. (approval=true, isOpen=TRUE, dup=false); IndexTemplate 0x016d4e.. (false); ReserveTemplate 0x238963.. (false)
#  AST: PoolTemplate   0x007497.. (approval=true, isOpen=TRUE, dup=false); IndexTemplate 0x734afd.. (false)
# (events: 3 per chain; topics 0x647b650a..; corroborated by direct factory.templates(...) reads)

# Reference allowlist (reflist) per template, slots 1..3 (underlying/registry/parameters):
#   ARB: slot1 USDC.e=true, slot2 registry=true, slot3 params=true; wildcards 1..3 = false (slot0 wildcard=true)
#   OP : slot1 USDC=true,   slot2 registry=true, slot3 params=true; wildcards 1..3 = false (slot0 wildcard=true)
#   AST: slot1 USDC=true,   slot2 registry=true, slot3 params=true; wildcards 1..3 = false (slot0 wildcard=true)
#   Complete ReferenceApproval event history: 10 events on Arb, 10 on Op, 9 on Astar — only the values above.
# => a permissionless clone is FORCED to use the real USDC/registry/parameters.

# Permissionless creation simulation (eth_call, caller=0x2222...2222, zero balance, no approvals):
ARB factory.createPool(MarketTemplate,"attacker-poc",[0,0],[0x1111..,USDC.e,registry,params])
    -> SUCCESS, returns clone 0xfb57b8df7995b517c053b884188979642f5e18c1  (registered via registry.addPool)
OP  factory.createPool(MarketTemplate,"attacker-poc",[0,0],[0x1111..,USDC,registry,params])
    -> SUCCESS, returns clone 0xb679de5ecafbaf1eab1cdda96f548083454542a0  (registered via registry.addPool)
AST factory.createMarket(PoolTemplate,...) -> eth_call reverts data "0x" ON THE RPC because the Astar public node
    cannot execute CREATE inside eth_call (control test: a scratch contract doing CREATE returned address(0)).
    On-chain history: 15 successful createMarket txs (e.g. 0xfde93a25... block 963651) prove the path works.
    Replaying a historical createMarket tx at latest correctly reverts "ERROR: DUPLICATE_MARKET".

# Owner-only privileged simulations (eth_call --from 0x2c9bC901..., NO tx sent):
ARB vault.withdrawValue(1 USDC, owner) -> SUCCESS (burns 850745 attribution)  (owner holds fee attribution)
ARB controller.emergencyExit(owner)    -> SUCCESS (would transfer all aUSDC)
OP  controller.emergencyExit(owner)    -> SUCCESS
AST vault.setController(0x9999...)     -> SUCCESS (owner can then route vault.utilize())
```"""

FINDINGS = """## Audit findings (each with exact evidence)

**F1 — Permissionless market creation is LIVE on all three chains (owner-configured open factory).**
`factory.templates(MarketTemplate/PoolTemplate)` returns `(approval=true, isOpen=true)`. Simulated `createPool` from a zero-balance address succeeds on Arb and Op and returns a fresh clone; the factory atomically calls `registry.addPool(clone)`, so the clone is `isListed` and may call `vault.addValue/borrowValue/offsetDebt/transferDebt`. On Astar the same flow is proven by 15 historical `createMarket` txs.
*Why it is not directly extractable:* `createPool` requires every reference to pass `reflist[template][slot][ref] || reflist[template][slot][address(0)]`. For slots 1..3 (underlying token, registry, parameters) the wildcard is false and only the real USDC / real registry / real parameters contract are approved — verified by direct reflist reads at latest and by the **complete `ReferenceApproval` event history (10 events on Arb, 10 on Op, 9 on Astar; no other reference values)**. A fresh clone therefore inherits the honest parameters contract, and all value-moving owner functions (`applyCover`, `applyBounty`, `setPaused`, …) resolve to `parameters.getOwner() == 0x2c9bC901…` — not the attacker. IndexTemplate and ReserveTemplate are `isOpen=false` on every chain (ReserveTemplate is not even approved on Astar), so no attacker-controlled index or reserve can be created either.
*Latent risk (P):* if the owner ever calls `approveReference` to allow another parameters/registry address (or approves another template), any fresh market created with those references would be attacker-controlled and could `borrowValue` the vault contents. Today this requires the owner key.

**F2 — No public function moves vault value to a caller/attacker-supplied recipient.**
`MarketTemplate.withdraw` pays only `msg.sender` and only from the market's own attribution (`vault.withdrawValue(_retVal, msg.sender)`, capped by `_retVal <= _availableBalance()`). `redeem` pays `_insurance.insured` but is gated by `marketStatus == Payingout` (attacker-simulated call reverts `ERROR: NO_APPLICABLE_INCIDENT`), and `Payingout` can only be entered by `applyCover`, gated to `parameters.getOwner()` (reverts `Caller is not allowed to operate` for the attacker). `applyBounty` (the only other `borrowValue` caller) is the same owner gate. `IndexTemplate.withdraw` pays only the caller. `IndexTemplate.compensate` / `ReserveTemplate.compensate` are callable only by owner-registered markets / listed markets and only move attribution bookkeeping.
`ReserveTemplate.compensate` would let *any listed market* pull the reserve's value via `vault.transferValue(_compensated, msg.sender)` — a weak gate — but **no Reserve/CDS instance exists on any of the three chains** (`registry.getReserve(0)==0`, `registry.getCDS(0)==0`) and the template is `isOpen=false`, so the path is dead (S).

**F3 — Permissionless `registerIndex` gate cannot be reached by an unprivileged caller.**
`MarketTemplate.registerIndex()` requires `registry.isListed(msg.sender)` — i.e. the *index* must call the market. No public function of any listed template makes that call with an attacker-controlled target (IndexTemplate.set is owner-only; attacker cannot create an IndexTemplate clone, `isOpen=false`). Direct attacker call reverts `Not an Official Pool` (Arb/Op) / `ERROR: UNREGISTERED_INDEX` (Astar). Consequently no attacker can inject index credit (`totalCredit`), which is the only way to bend `_availableBalance`/`rewardPerCredit` accounting.

**F4 — Vault attribution accounting is self-consistent (no first-depositor/rounding extraction).**
`addValue` floors attribution, `withdrawValue`/`offsetDebt` round the burn up (`_divRoundUp`) — both round in favour of the remaining holders. Depositing X when `valueAll/T` is scaled returns exactly `underlyingValue(X,after) ≈ X`; the `worth()` edge case (`supply!=0 && originalLiquidity==0` → mint `= amount*supply`) yields a pro-rata claim no larger than the deposit (analysis in notes). `totalAttributions==0` while `valueAll>0` (the only inflation corner) is unreachable on these chains (516M attributions live on Arb, 205M on Op, 548M on Astar). Donation paths (`repayDebt`, `addBalance`) never favour the attacker.

**F5 — Controller (Arb/Op) has no unprivileged value-out.**
`AaveV3Strategy.returnFund`/`emigrate` are vault-gated, `emergencyExit`/setters are owner-gated (attacker sim reverts `OnlyOwner`). `adjustFund()` and `immigrate(_from)` are permissionless but only move funds *into* the Aave position from the vault or from an address that already approved the strategy — no path sends value to a caller-chosen address.

**F6 — Astar Vault variant (0.8.10) differences: none exploitable from outside.**
`borrowValue` has no `_unutilize` step (plain transfer; reverts on insufficient balance), `utilize()` is no-arg and, with `keeper==0`, would be permissionless **if a controller were set** — `controller()==0` today, and setting one is owner-only. `withdrawRedundant` only skips `balance<=tokenBalance` (no redundant balance today). All value-out paths still require the caller's own attribution or a role.

**F7 — Owners and privileged classification (P vs S).**
All three chains route ownership to a single EOA `0x2c9bC901f39F847C2fe5D2D7AC9c5888A2Ab8Fcf` (vault/registry/parameters/controller ownership; `futureOwner()==0` — no pending transfer). Nonces 77 (Arb) / 666 (Op) / 70 (Astar) show historical activity; key liveness cannot be proven on-chain. **Classified P (privileged, not E-U).** The same EOA directly holds fee attributions in each vault (376,475,435 / 153,800,391 / 18,863,572 raw) and can redeem them via the public `withdrawValue` at any time (owner-simulated withdrawal succeeds), in addition to `controller.emergencyExit` on Arb/Op and `vault.setController` + `utilize` on Astar.
**Astar former owner:** the shared Ownership contract had an interim owner `{FOP}` from block 1,667,152 to 4,125,874 (AcceptNewOwnership events). That EOA still holds **75,702,994 raw ≈ $75.70** of fee attributions in the Astar vault (redeemable only via `withdrawValue`; no admin powers remain). Classification: P-legacy (its own key only), not E-U.

**F8 — Dead / dust market observations (no extraction).**
A handful of Op markets have `supply==0` with small residual attributions (iBIFI 193, iUSD+ 4420, iIndex 61741 raw) — stuck value, unreachable (withdraw requires supply != 0 but minting new shares would dilute to fair value).
"""


def fmt(v):
    if v is None:
        return "—"
    if isinstance(v, int):
        return f"{v:,}"
    return str(v)


def market_table(v):
    rows = []
    rows.append("| market | symbol | impl | attributions | underlyingValue | totalSupply | status | paused | attrDebt | locked | totalCredit | origLiq | totalLiq | vault.debts |")
    rows.append("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    for m, i in v["markets_info"].items():
        d = i.get("detail", {})
        status = i.get("marketStatus_u")
        status = "Trading(0)" if status == 0 else ("—" if status is None else str(status))
        lines = [
            m, i.get("symbol") or "—", (i.get("impl") or "—")[:10] + "…",
            fmt(i.get("vault_attributions")), fmt(i.get("vault_underlyingValue")), fmt(i.get("totalSupply")),
            status, str(i.get("paused")), fmt(d.get("attributionDebt")), fmt(d.get("lockedAmount")),
            fmt(d.get("totalCredit")), fmt(d.get("originalLiquidity")), fmt(d.get("totalLiquidity")),
            fmt(d.get("vault_debts_live")),
        ]
        rows.append("| " + " | ".join(lines) + " |")
    return "\n".join(rows)


def chain_section(chain, v):
    meta = CHAIN_META[chain]
    vs = v["vault_state"]
    value = (vs.get("valueAll") or 0) / 1e6
    owner_attr = OWNER_ATTR[chain] / 1e6
    fub = v.get("followup_block")
    impls = {}
    for m, i in v["markets_info"].items():
        impls.setdefault(i.get("impl"), []).append(m)
    impl_lines = "\n".join(
        f"| {impl} | {IMPL_NAMES.get(impl, '?')} | {len(ms)} | {', '.join(x[:12]+'…' for x in ms[:4])}{' …' if len(ms)>4 else ''} |"
        for impl, ms in impls.items()
    )
    return f"""## {chain.capitalize()} (chain_id {meta['chain_id']})

**E-U verdict: $0.00** — every value-moving path requires a role or the caller's own attribution; permissionless market creation is forced onto the real parameters contract (findings F1–F6). Owner-privileged exposure is finding F7.

- **Block (vault/market reads):** {v.get('block'):,}{f" ; follow-up detail block: {fub:,}" if fub else ""}
- **Vault:** `{meta['vault']}` — token {meta['token']}
- **Vault value (valueAll):** {vs.get('valueAll')} raw ≈ **${value:,.2f}** ; balance()={vs.get('balance')} ; totalAttributions={vs.get('totalAttributions')} ; totalDebt={vs.get('totalDebt')}
- **Controller:** {meta['controller']}{f" ; managingFund={v.get('controller_managingFund')} (≈${(v.get('controller_managingFund') or 0)/1e6:,.2f})" if v.get('controller_managingFund') else ""}
- **Registry:** `{meta['registry']}` ; **Factory:** `{meta['factory']}` ; **Parameters:** `{meta['params']}`
- **Ownership:** `{meta['ownership']}` → owner **{OWNER}** (EOA, nonce {meta['owner_nonce']}, futureOwner=0). Owner's fee attribution in this vault: **{OWNER_ATTR[chain]:,} raw ≈ ${owner_attr:,.2f}** (redeemable by the owner via `withdrawValue`).
- **Markets:** {len(v['markets_info'])}

### Unique implementations
| impl | name | clones | examples |
|---|---|---|---|
{impl_lines}

### Market table (raw units, 6-dec USDC)
{market_table(v)}
"""


def main():
    arb = state["arbitrum"]
    op = state["optimism"]
    ast = state["astar"]
    FOP = FORMER_ASTAR_OWNER
    total = sum((state[c]["vault_state"].get("valueAll") or 0) for c in state) / 1e6
    owner_total = sum(OWNER_ATTR.values()) / 1e6
    out = f"""# InsureDAO v2 — L2 chains (Arbitrum, Optimism, Astar) — Phase-2 audit report

**Scope:** InsureDAO v2 deployments on Arbitrum, Optimism, Astar (vaults, registries, ownership, factories, parameters, controllers, and every registered market + its EIP-1167 implementation).
**Method:** fully read-only. Keyless public RPCs (`https://arb1.arbitrum.io/rpc`, `https://mainnet.optimism.io`, `https://evm.astar.network` + publicnode/onfinality fallbacks). Verified sources pulled from Etherscan V2 / Blockscout and saved under `analysis/v2-chains/sources/`. All gate checks performed with `cast call` (eth_call) at latest block; **no transaction was sent and no key was used**. Scripts: `enumerate.py`, `followup.py`, `make_report.py` (keyless).

**Total v2 L2 value in scope: ≈ ${total:,.2f}** (Arb ${(arb['vault_state']['valueAll'] or 0)/1e6:,.2f} + Op ${(op['vault_state']['valueAll'] or 0)/1e6:,.2f} + Astar ${(ast['vault_state']['valueAll'] or 0)/1e6:,.2f}).

## Bottom line (E-U = extractable by a fresh, unprivileged attacker)

| chain | E-U | confidence | reason (gate) |
|---|---|---|---|
| Arbitrum | **$0.00** | high | Every value-out is gated: `borrowValue` → onlyMarket; `withdrawValue` → caller's own attribution; owner functions → `parameters.getOwner()` (EOA). Permissionless market clones are forced (factory reflist) to the real parameters contract, so a clone cannot be turned into a payout tool. |
| Optimism | **$0.00** | high | Same code and same owner/reference configuration as Arbitrum; all gates verified by eth_call reverts. |
| Astar | **$0.00** | high (one RPC limitation, see F1) | Older 0.8.10 generation with identical auth structure; reference allowlist identical. `createMarket` could not be re-simulated in eth_call because the public node cannot CREATE inside eth_call, but the reference restriction is proven by storage reads + event history. |

**Privileged risk (P, not E-U):** the single EOA **{OWNER}** owns the vaults/registries/parameters/controllers on all three chains. It can take **${owner_total:,.2f}** of fee attributions directly (public `withdrawValue`), drain Arb/Op remainders via `controller.emergencyExit`, and re-wire Astar via `vault.setController` — i.e. **100% of the ${total:,.2f}** is owner-reachable. If this key is destroyed, all of it is permanently locked (S); it is not reachable by third parties either way.

---

{chain_section('arbitrum', arb)}

---

{chain_section('optimism', op)}

---

{chain_section('astar', ast)}

---

## Verification evidence

### 1. Gate checks (eth_call, caller 0x2222… — no transaction)
{EVIDENCE_GATES}

### 2. Factory open-creation and reflist evidence
{EVIDENCE_FACTORY}

---

{FINDINGS.replace('{FOP}', FORMER_ASTAR_OWNER)}

---

## Notes & limitations
- Arb/Op public RPCs are non-archive: per-market “detail” reads (`attributionDebt`, `lockedAmount`, `totalCredit`, …) were taken at the follow-up block shown per chain; the vault-level reads were taken at the enumeration block. The tiny drift does not change any verdict (values move only by Aave interest / rounding dust).
- `marketStatus` is an enum: `0 = Trading` for every PoolTemplate/MarketTemplate market on all chains; IndexTemplate has no `marketStatus()`.
- Astar MarketTable source: `PoolTemplate` (solc 0.8.10) + `IndexTemplate` (solc 0.8.10); Arbitrum and Optimism are byte-identical `MarketTemplate`/`IndexTemplate`/`Factory`/`AaveV3Strategy`/`Vault` sources (solc 0.8.12).
- The Astar remainder (75,702,994 raw ≈ $75.70) belongs to the interim owner EOA {FOP} (blocks 1,667,152–4,125,874); only that key can redeem it, so it is outside both E-U and the current-owner P path.
- Sources for every implementation and auxiliary contract are stored under `sources/`; raw reads are in `state.json`.

*Generated by make_report.py — all amounts raw 6-dec USDC unless marked $.*
"""
    open("REPORT.md", "w").write(out)
    print("REPORT.md written", len(out), "bytes")


if __name__ == "__main__":
    main()
