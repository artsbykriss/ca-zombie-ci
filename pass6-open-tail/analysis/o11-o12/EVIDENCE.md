# O11 (Ink ChimeraQuoteHook404) + O12 (Ronin BondingCurveManager) — evidence

Read-only. No transaction signed/broadcast on any chain. All reads via keyless public RPCs
(Ink `https://rpc-gel.inkonchain.com`, Ronin `https://ronin.drpc.org` / `https://api.roninchain.com/rpc`).
Fork proofs ran in CI (see `ci-log.txt`, run URL in README).

## O11 — Ink, ChimeraQuoteHook404 family

### Live state (Ink block 59,385,227; ETH $2,342.89, DefiLlama)

| Contract | Address | Live state |
|---|---|---|
| ChimeraQuoteHook404 | `0xD723B53D1A651D8BfD6b4C8876D51b68E26128CC` | 1 tx ever (`configureInfrastructure`); **2 logs total, both `QuoteAllowed`**; 0 native, 0 tokens |
| ChimeraQuoteHook404 (2nd) | `0x0be6EC0e9822d8669616431594215d1Bf768e8cC` | 1 tx (`configureInfrastructure`); 0 logs; 0 native |
| ChimeraQuoteRouter404 | `0x8706Daf2A2F26c43fc0e09097A228351473333A2` | 1 tx (deploy); 0 native |
| ChimeraQuoteLaunchLiquidity404 | `0x1168B6Ea1E6B22FA130aA49919D21e8735a24729` | 0 txs; 0 native |
| launchLiquidity (lane's addr) | `0xE37BAe58E353e36B2Bfcb27a4f2eE848D06043E1` | 0 txs; 0 native |
| ChimeraFeeVault404 (only verified one) | `0x8BAf0ba2659d18a9B093d1435fc32fF23b2Cd16a` | 1 tx (deploy by installer); 0 tokens |

**No pool has ever been registered on the quote hook** — `quoteOf(id) == address(0)` for all ids,
and the hook's entire log history is two `QuoteAllowed` events. Therefore no per-pool
`ChimeraFeeVault404` clones exist for the quote hook and there are **no fees to extract: E-U $0**.

### Sibling family (non-quote `ChimeraHook404 0x2EebD90Bf253A27961624762f73EEE1409C52DCC`)
The factory (`0xa66c05f14e79f40952531c20de0b60282e3800be`, TransparentUpgradeableProxy) emitted 5
`CampaignCreated` events; 4 of them have funded vaults (`hook() == 0x2EebD90B…`, `supportQuotrons == true`):

| Vault | WETH (wei) | USD @ $2,342.89 |
|---|---|---|
| `0xEf4b9d776617CAffAD540C4E140cFd4634E1643f` | 31,179,381,589,265,151 | $73.05 |
| `0x51fa459195bdfF8022A687a210F2b2Fb6047915B` | 44,929,928,838,514,544 | $105.26 |
| `0x2D5fa91cB5786Aa7f7c9F8664DEC168B3d4b286f` | 27,359,943,376,107,085 | $64.10 |
| `0xaf02BF66f013c6eb1F32e0fE70Fc12AFF6EA81B9` | 30,330,592,506,249,709 | $71.07 |
| **total** | **0.133799846310136489 WETH** | **≈ $313.5** |

That WETH is **credit-accounted** (`ChimeraFeeVault404.credit[recipient]`) to the vault's fixed
destinations (creator / platform / terminal pot / growth sink / NFT rewards). The only exits are
`claim()` → pays `credit[msg.sender]` to `msg.sender`, and `claimFor(r)` / `distributeQuotrons()`
→ pay `credit[r]` to `r`. An unprivileged caller can *push* a recipient their own credit but can
never redirect it to themselves. ⇒ **H-O/P**, not E-U.

### Code review (verified source, `ChimeraQuoteHook404` + `ChimeraAccounting.sol` + router)
- Creator fee-exemption is reached only when `sender == router` **and** `router.actor() == creator`;
  the router's `actor` is set from `msg.sender` in a reentrancy-free `context` modifier and cleared
  after. A direct `poolManager.swap` caller has `sender != router` ⇒ `_exempt` returns false.
- The non-creator eligibility exemption requires a creator-configured `eligibilityMinimum[id][asset]`
  **and** the caller holding ≥ that balance of that asset — a deliberate allowlist, not a bypass.
- `_charge` uses floor `mulDiv`; `account()` conserves value (`credit[platform] += received - used`,
  `used ≤ received`); no underflow, no drain.
- `distributeQuotrons(id)` is permissionless but a no-op for unregistered ids and only ever pays the
  vault's fixed destinations.

**Verdict O11: E-U $0 (high confidence).** Latent: if pools are ever launched, the surfaces above are
the ones to re-check; today there is nothing live to extract.

## O12 — Ronin, BondingCurveManager

### Live state (Ronin block 62,707,425; RONKE $0.00101019, DefiLlama)

| Contract | Address | Live value |
|---|---|---|
| BondingCurveManager | `0xCF6Aa3d88431D73C76b9650e64a995a5edDb5f54` | **9,926,811.26 RONKE ≈ $10,028** + 190 launch ERC-20s (unsold curve inventory, ~$0 each) |
| FeeVault | `0x648796b45d4cdd2e56f1d5804cf7713add09b776` | 24,449.01 RONKE ≈ $24.70 |
| GraduationManager | `0x4f36816a9b5bffeeec5348f8152373de195d6ea6` | 0 RONKE |
| RONKE | `0xf988f63bf26c3ed3fbf39922149e3e7b1e5c27cb` | — |
| factory / owner | `0x719921f396a87e5505aff65d2ed6dc73caf633c9` / `0x4b694024f6282420820258b7e7ad9f6fc77dd257` | wired=true, autoGraduate=true |

The RONKE in the curve is buyers' money held until graduation (or until a seller sells back).

### Code review (verified source)
- `sell` is the only path that pays RONKE out, and it requires `tokensIn <= boughtFromCurve[token][msg.sender]`
  **and** `tokensIn <= markets[token].tokensSold`. Provenance does not follow a transfer (a mule wallet
  that receives bought tokens cannot sell them).
- `buy`/`buyGated` credit `boughtFromCurve` only after `ronke.safeTransferFrom(payer, …)`, so provenance
  cannot be forged without paying.
- `_quoteBuy` partial-fill branch uses stacked `Ceil`s then a floor fallback capped at `remaining`; the
  invariant `virtualToken × virtualRonke` is non-decreasing and a buy→sell round trip is value-negative.
- `buyFor`/`registerLaunch` are `factory`-only; `closeCurve` is `graduationManager`-only; `setWiring`
  (once) / `setAutoGraduate` are `Ownable2Step`. Graduation is permissionless but the LP is minted into
  the immutable LiquidityLocker — no RONKE or LP reaches the caller.

### Fork + fuzz proof (CI, run 40141624590)
- `test/O12_RoninBondingCurve.t.sol` (real deployed contract, Ronin fork): 7/7 PASS — round trips at six
  sizes never profit; partial-fill branch no profit; attacker `sell` without a buy reverts; `buyFor`
  from a stranger reverts; admin paths revert; provenance not transferable.
- `test/O12_MathReplica.t.sol` (fork-free transcription): 2 × 5,000 fuzz runs PASS — round trip never
  profitable, `k` never decreases, no underflow, partial-fill never undercharges.

**Verdict O12: E-U $0 (medium-high confidence).** The ~$10.0k RONKE is **H-O** (sellers can exit via
`sell`) / **S** (unsold curves never graduated). No unprivileged extraction path found.
