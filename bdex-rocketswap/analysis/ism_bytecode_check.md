# ISM bytecode verification — Anubis/Ethereum/BSC/Polygon bridge gate

**Goal:** prove the deployed ISM (the only gate on minting/releasing ≈$354M/$423M) is the
unmodified canonical Hyperlane multisig, not a modified/buggy variant.

## Deployed artifacts

| Item | Address | Notes |
|---|---|---|
| Public ISM (MetaProxy) | `0x966b26267AADfC1be995803d09797E523352465D` | EIP-1167-style proxy, 54-byte runtime + immutable args |
| Private ISM (MetaProxy) | `0xEb5216540491A94a1f2e582Cf66800A6880dC75F` | same pattern |
| ISM implementation (both) | `0x6ce8c44716bd11ffbeacc23687b43b87495a479d` / `0x4e4d198ffccefd3d3173697a4a6bb89a9f58a31b` | byte-identical to each other; unverified on explorers |
| Mailbox impl | `0x5a197a5f488fc9ff4c5d4c2af7884e974b51256b` | verified source == canonical Hyperlane `Mailbox.sol` (comment-only diff) |

## Immutable args (MetaProxy metadata)

`validatorsAndThreshold(bytes)` on the proxies decodes to:

* public: `[0x0b709a7bDfb123Ebabd1F1E38a6b43468E5B0D4F, 0x4D27EfE49697b7648872F4e5AeA42B95Ba30BcE9, 0xD1C2E530023Ac78687404650CFF9f458500C3343]`, threshold **2**
* private: `[0x24e9121965A747Ed340e67DD70FE4b69f994450b, 0x601518ecd47D119c00372db0dcC09Bab6C3392e3, 0xac95089333d232976D0e9F6bDd45F1e79301a1A7]`, threshold **2**

Same validator sets were read on Ethereum (1), BSC (56), Polygon (137) and Anubis (6714).
All six validators are EOAs (code size 0).

## Bytecode match

1. The deployed implementation runtime code is 4,494 bytes; solc metadata CBOR says **solc 0.8.22**,
   IPFS metadata `QmTkggiwYEb3UcfR6ag81oyEsc5VwdveBjyA84628MHhAF` (gateway-blocked).
2. Selector scan of the impl finds `verify(bytes,bytes)=0xf7e83aee`, `moduleType()=0x6465e69f`,
   `validatorsAndThreshold(bytes)=0x2e0ed234`, `PACKAGE_VERSION()=0x93c44847` → Hyperlane
   `StaticMerkleRootMultisigIsm` (moduleType 4 = MERKLE_ROOT_MULTISIG).
3. The npm artifact `@hyperlane-xyz/core` `StaticMerkleRootMultisigIsm` (init code → runtime via
   the CODECOPY prologue) was compared with the deployed runtime **with the CBOR metadata stripped**:
   * v6.0.0 / 6.0.1 / 6.0.4 / 6.1.0 / 7.0.0 / 7.1.0 / 7.1.4 / 7.1.10 / 8.0.0 / 8.0.1 / 8.0.2 / 8.1.2 /
     9.0.0 / 9.0.5 / 9.0.10 / 9.0.17 / 10.0.0: **same length 4,441 bytes, only 2–7 differing bytes**
   * every differing byte is inside the embedded `PACKAGE_VERSION` string constant
     (e.g. v6.0.0 has "6.0.0", v10.0.0 has "10.0.0"); the deployed value is **"10.1.5"**
   → the deployed implementation is the canonical Hyperlane v10.1.5 code, functionally identical
   across all compared releases.

## What this means

`verify()` performs canonical ECDSA recovery over the (origin, merkle root) digest and requires
signatures from a strict subset of the 3 validators (two-pointer match, `!threshold` on failure).
No owner, no admin, no delegatecall, no upgrade path in the ISM itself (immutable MetaProxy).
The only ways to mint/release through the bridge are: (a) 2-of-3 validator signatures, or
(b) the owner EOA upgrading the bridge/mailbox (UUPS / Transparent proxy) — both **privileged**.

Fork test `test_forged_message_rejected_*` (poc/test/Anubis.t.sol) submits crafted Hyperlane
messages to the live mailbox from an unprivileged address; both revert (empty metadata and
fake-root+fake-signature variants).
