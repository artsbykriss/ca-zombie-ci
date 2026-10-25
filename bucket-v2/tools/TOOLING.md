# Sui read-only tooling & primitive notes (ZH4 pass-7) — bucket-v2

All Sui JSON-RPC on public fullnodes is **deprecated (2026)**. Use the **GraphQL API**:
`https://graphql.mainnet.sui.io/graphql`. It exposes full **Move bytecode disassembly**, live object
state, events and `simulateTransaction`. No `sui` CLI is installed locally.

## Helper: `tools/sui.py` (read-only, public endpoint, no keys)
```
python3 tools/sui.py pkg  <packageAddr> [outdir]   # every module + full disassembly
python3 tools/sui.py ver  <packageAddr>            # version chain + linkage
python3 tools/sui.py obj  <objectAddr>             # object type + JSON contents (live state)
python3 tools/sui.py multiobj <a,b,c>              # batch reads
python3 tools/sui.py type <structType> [n]         # objects of a struct type
python3 tools/sui.py events <MoveEventType> [n]    # recent events
python3 tools/sui.py txfn <pkg>::<mod>::<fn> [n]   # recent txs that called a function
python3 tools/sui.py sim  <txjson>                 # simulateTransaction (no signing)
```

## Sui package model — version/package-import primitive
- Upgrades publish a new package object at a new address but keep the original "runtime" id.
  `package(address:X)` resolves original→latest; `ver` shows the whole chain.
- **Old versions remain callable and share the same shared objects** (Sui docs *Upgrading Packages*;
  Move Book *Package Upgrades*). Mitigation = an explicit **version check** object on the shared state.
- Test: does an older version expose an unprivileged value-moving function (collateral/debt/
  liquidation/redeem/price) that a later version gated? Does the protocol use a version gate?
- Also: `public(package) entry` functions are directly callable by anyone.

## Bucket Protocol V2 — known addresses (DefiLlama adapter `bucket-protocol-v2`)
- Vault (CDP) struct type: `0x9f835c21d21f8ce519fec17d679cd38243ef2643ad879e7048ba77374be4036e::vault::Vault`
  (latest package object `0xc1dd29778f3fccd19a4ac79d1c35a14bf9d65a0b48f1c5bba98a949cacc53e26`, 4 versions)
- PSM Pool struct type: `0xc2ae6693383e4a81285136effc8190c7baaf0e75aafa36d1c69cd2170cfc3803::pool::Pool`
  (latest `0x8a46afe6ab0b972e2ee3923f5669104ae9465c12b84cd5e78ea1ff6404e4bfaf`, 4 versions)
- Enumerate live vaults/pools with `type`; read collateral/debt/oracle fields with `obj`.
- Legacy Bucket CDP: protocol object `0x9e3dab13212b27f5434416939db5dec6a319d15b89a84fd074d03ece6350d3df`.

## Rules (hard)
- **Read-only.** Never sign/send/deploy. Only public reads + local sim.
- **No secrets** in any file here (no keyed RPC URLs/keys).
- Write **only inside this folder**. Heavy compute → CI: `bash /home/heisenberg/CA/ci/ci-run.sh bucket-v2`
  (layout `ci/run.sh` → `ci-out/`). The CI repo is **public**.
