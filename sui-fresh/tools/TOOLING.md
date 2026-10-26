# Sui read-only tooling & primitive notes (ZH4 pass-7)

All Sui JSON-RPC on public fullnodes is **deprecated (2026)** — `sui_getObject` etc. return
`Method not found`. Use the **GraphQL API**: `https://graphql.mainnet.sui.io/graphql`.
It exposes full **Move bytecode disassembly**, live object state, events and
`simulateTransaction`. No `sui` CLI is installed locally.

## Helper: `tools/sui.py` (read-only, public endpoint, no keys)
```
python3 tools/sui.py pkg  <packageAddr> [outdir]   # every module + full disassembly + bytecode self-addr
python3 tools/sui.py ver  <packageAddr>            # version chain (original->latest) + linkage
python3 tools/sui.py obj  <objectAddr>             # object type + JSON contents (live state)
python3 tools/sui.py multiobj <a,b,c>              # batch object reads
python3 tools/sui.py type <structType> [n]         # objects of a struct type
python3 tools/sui.py events <MoveEventType> [n]    # recent events of a type
python3 tools/sui.py txfn <pkg>::<mod>::<fn> [n]   # recent txs that called a function
python3 tools/sui.py sim  <txjson>                 # simulateTransaction (no signing)
```
Raw GraphQL one-liner:
```
curl -s -X POST https://graphql.mainnet.sui.io/graphql -H 'Content-Type: application/json' \
  --data-binary "$(jq -nc --arg q '{query:$q}')"
```

## Sui package model — the **version/package-import primitive** (our hypothesis)
- A published package has an **original id** (`published-at`/`original-id`). Upgrades publish a
  **new package object at a new address** but keep the original id as the "runtime id".
- `package(address:X)` in GraphQL resolves the original id to the **latest** version and returns
  `address` = latest package object; the **module bytecode self-address** stays the *original* id.
  `packageVersionsBefore`/`linkage` give the full version chain.
- **Old versions remain callable and share the same shared objects.** Official sources:
  - Sui docs (*Upgrading Packages*): *"You cannot delete old packages... any transaction or package
    that references an old version's package ID can still call it."* and *"Without a version check,
    callers can keep calling the old version of a function... A useful pattern is to introduce
    versioning to the shared object and use a version check to guard access to functions."*
  - Move Book (*Package Upgrades*): *"old versions of a package remain callable... If version 2
    fixes a bug in a function that mutates a shared object, an attacker can simply keep calling the
    version 1 function — on the very same shared object."*
- **So the test is:** for each protocol, enumerate every package version, and check whether an
  **older version exposes an unprivileged (`entry`/`public`) value-moving function** that a later
  version gated (added an admin/role check) or whose guard object the old code ignores. Then check
  whether the current shared objects still satisfy the old code's preconditions (typeOrigins makes
  types identical, so they usually do), and whether the protocol added a **version gate** object.
- Also test the related hazard: `public(package) entry` functions are **directly callable by anyone**
  (the `entry` modifier ignores package-visibility) — a classic Sui drain pattern.

## Live state
- Object JSON: `obj <addr>` → `.data.object.asMoveObject.contents.json`.
- Find objects by type: `type <pkg>::<mod>::<Struct>` (e.g. a `Vault`, `Pool`, `Bank`, `Registry`).
- Events: `events <pkg>::<mod>::<EventName>`.
- **Package object** vs **shared object** are different: value lives in shared objects whose
  `type.repr` names the defining package (which may be a specific upgrade version, e.g. a module
  added in v2 has the v2 address in its type tag — that is expected, not a bug).

## Simulation (read-only)
`simulateTransaction(transaction: JSON!, checksEnabled, doGasSelection)` — pass the Sui JSON tx
(`{"kind":"ProgrammableTransaction","inputs":[...],"transactions":[{"kind":"MoveCall",...}]}`).
No signature needed. If the JSON shape is rejected, note it as a tooling limit and rely on the
disassembly (which is full bytecode, so gating logic is directly readable).

## Rules (hard)
- **Read-only.** Never sign/send/deploy on any real chain. Only public RPC/GraphQL reads + local sim.
- **No secrets** in any file in this folder (no keyed RPC URLs, no keys). Use the public endpoint.
- Write **only inside this finding's folder**.
- Heavy compute (large enumerations, big loops) → CI via `bash /home/heisenberg/CA/ci/ci-run.sh <folder>`.
  Folder layout: `ci/run.sh` (heavy job) → `ci-out/` (results → artifacts). CI repo is **public**.
- Re-verify everything on-chain; the corpus is a lead source, not ground truth.
