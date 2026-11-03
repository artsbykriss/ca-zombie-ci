# TAC JettonProxy — PoC note (non-EVM)

This target is on **TON**, so there is no Foundry fork project. The PoC is a
read-only TVM disassembly + live trace verification, reproduced by
`../analysis/live_checks.py` (TAC EVM) and `../analysis/ton_checks.py` (TON).

## The defect (proxy, live code cell)

Code hash `A808C9F031379C60BF9604376EC5C52609B08536B1F3A366EFAC86BE25594EDB`.
In `../analysis/proxy.fift`, the `0x7362d09c` (`transfer_notification`) branch
(lines 63–337) parses the body-supplied amount/sender/forward payload, builds a
`0x6c582059` message and `SENDRAWMSG`s it to `GETGLOB 1` (the CCL). There is
**no `SDEQ`** in that branch; every admin/release branch has one.

## Why the defect does not move the balance

Both jetton-release branches are CCL-gated:

```
0xae7df95b: ... GETGLOB 1; SDEQ; THROWIFNOT 70; ... PUSHINT 260734629 (0x0f8a7ea5) ...
0x7817b330: ... GETGLOB 1; SDEQ; THROWIFNOT 70; ... PUSHINT 260734629 (0x0f8a7ea5) ...
```

`../analysis/release_trace.json` (tonapi) is a live release:
`CCL 0:20a5698e → JettonProxy 0x7817b330 → proxy's jetton wallet 0x0f8a7ea5 →
recipient 0x178d4519`.

The CCL TON code (`../analysis/ccl.fift`) gates the release batch:
`0x497dae1d` handler → `DICTUGET; THROWIFNOT 201` (signed-message dictionary) and
`SDEQ; THROWIFNOT 71`; the signed external entry `0x4b19e42a` is
`CHKSIGNU`-gated by the 256-bit pubkey in `GETGLOB 4`
(`b76b6f562313156bb3b5c269da1f56baf03014a422ab033485416817081c3cd8`).

## EVM side

`../analysis/crosschainlayer_impl.sol` (`receiveMessage`) mints only after
`Consensus.checkMerkleRoot(root)`. Live `Consensus` is 1-of-1: one EOA voter
`0x8f1B53B1Bf9b24BAa2054Bd2d8C0b7923ABff9df`; a forged message reverts
`InvalidMerkleProof()` (`0xb05e92fa`).

Reproduce:

```bash
bash ../ci/run.sh
```

Expected: 9 PASS lines and `TAC gates OK`.
