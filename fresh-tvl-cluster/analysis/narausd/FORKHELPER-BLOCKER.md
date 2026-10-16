# BLOCKER for the parent: `poc/src/ForkHelper.sol` does not compile (cluster-wide)

**Symptom** (any test that imports `../src/ForkHelper.sol`, foundry.toml solc 0.8.26, forge-std 1.9.6):

```
Error (9097): Identifier already declared.
  --> src/ForkHelper.sol:10:5:  address internal constant VM_ADDRESS = ...;
Note: previous declaration: lib/forge-std/src/Base.sol:9:5
```

`ForkHelper` redeclares the `VM_ADDRESS` constant that forge-std 1.9.6 already provides via
`Test → Base → CommonBase`. Solidity forbids redeclaring an inherited constant, so **every** test
file that imports ForkHelper fails to compile with this vendored forge-std.

**Fix (parent, 1 line):** delete line 10 of `poc/src/ForkHelper.sol`:

```solidity
-    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
```

and change the two `VM_ADDRESS.call(...)` references to `vm.call`... actually simplest is to keep the
two call sites but use `vm` isn't callable as an address; use `address(vm).call(...)`? Cleanest:

```solidity
    function selectFirstWorkingFork(string[] memory urls) internal returns (string memory url) {
        for (uint256 i = 0; i < urls.length; i++) {
            if (bytes(urls[i]).length == 0) continue;
            (bool ok,) = address(vm).call(abi.encodeWithSignature("createSelectFork(string)", urls[i]));
            if (ok) return urls[i];
        }
        revert("ForkHelper: no reachable RPC");
    }
```

**Until fixed**, H17 children (NaraUSD/Subfrost tests and peers) carry the byte-identical
`forkChain` logic inline under a locally unique base contract (`h17Fork`), so the deliverables
compile and run. After the parent lands the 1-line fix, tests can be switched back to
`contract X is ForkHelper` with no other change.
