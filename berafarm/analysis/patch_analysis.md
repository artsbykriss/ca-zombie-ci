# BeraFarm — patch / implementation diff analysis (ZH4-06)

Chain: Berachain (80094). Read-only. All code hashes/blocks from public keyless RPC
`https://rpc.berachain.com` and Etherscan V2 (chainid 80094).

## 1. Proxy → implementation chain

EIP-1967 slot `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`.

| Proxy | pre-incident (block 27,270,000) | 27,320,000 | current (27,634,505) |
|---|---|---|---|
| Kodiak strategy `0x1Ce23321A72F2dae96809cC6192f053A7aD5D8e4` | `0x36bfa55a5cbe2c382f02f551db1e8acbcc929137` (verified) | `0x807982bb966abfd4b9a6b1387811c13981e364ef` (unverified) | `0xc6865dc8549a986ef02b1b72e2507ec9b5f8180e` (unverified) |
| KodiakSwapController `0x1cAc0625ee3A4679dCE7f9dC921ECFDD5c378987` | `0x1d5642c11087522d41c1da96b2cd38e5916dbe15` (verified) | same | `0x2be0125f8bf3f6e55ea30a9fa3d336030c68b5f5` (unverified) |
| HubBend-1 `0xC8f67DD8C2909750705E0533f8CA71dCdf380CC9` | `0x6481216093a69f5701e42b7a8b4d1a5765489322` (verified) | `0xee965e0a41ad4fd1b18c54529dfcacd5565bf163` | same |
| HubBend-2 `0xa13e0a5fE378E89cC72730F8Df2e140Ebc6F1E84` | `0x648121609…` | `0xee965e0a…` | same |
| Dolomite `0x7F41C51A50AA3591f16fFDc37A5b8A79305f5DC7` | `0xaf4f95f0…` | same | same (no gauge; not affected) |
| Vault0 `0x4a3c8Fdd…` / Manager0 / Registry / Oracle / FeeModule | unchanged | unchanged | unchanged (`0x50d0d654…`, `0xd3ec0a3a…`, `0xc7698654…`, `0x94547301…`, `0x51fe7782…`) |

Bytecode sizes: Kodiak strategy 20,822 → 20,933 → 20,090 bytes; swap controller 6,943 → 7,277.
The pre-incident verified source compiles **byte-exactly** to `0x36bfa55a` with
solc 0.8.30, optimizer runs=1, `viaIR=true`, evmVersion=paris, `metadata.bytecodeHash=none`
(the only difference is the self-address placeholder, which the compiler leaves zeroed).
See `analysis/compile/in_ir_1_none.json` / `out_ir_1_none.json`.

All post-incident implementations are **unverified** on Etherscan/Sourcify (checked
2026-10-16 and 2026-10-18).

## 2. What the patch changed (decompilation / selector analysis)

`cast disassemble` + heimdall decompilation of both new implementations is in
`analysis/decomp/`. Two facts matter:

### 2.1 New Kodiak strategy: subtract delegated RewardVault stake from NAV

The old source (verified `0x36bfa55a`, `HubStrategyKodiakIsland.sol`) is:

```solidity
function getTokenBalance() public view returns (uint256) {
    return IBGTGauge(hubVault).balanceOf(address(this));      // <-- includes delegate-staked LP
}
function getUnderlyingBalance() public view returns (uint256) {
    uint256 balance = getTokenBalance();
    if (balance == 0) return 0;
    return _getUnderlyingBalance(balance);
}
```

`RewardVault` (Berachain, verified) allows **anyone** to stake on another account's behalf:

```solidity
function delegateStake(address account, uint256 amount) external nonReentrant whenNotPaused {
    if (msg.sender == account) revert NotDelegate();
    _stake(account, amount);                       // _accountInfo[account].balance += amount
    _delegateStake[account].delegateTotalStaked += amount;
    _delegateStake[account].stakedByDelegate[msg.sender] += amount;
}
function delegateWithdraw(address account, uint256 amount) external ... {
    // delegate can pull its own stake back at any time
    _withdraw(account, amount);
}
```

The new strategy implementation calls `RewardVault.getTotalDelegateStaked(strategy)` and
**subtracts** it from `balanceOf` in both `getTokenBalance()` and `getUnderlyingBalance()`.
Verified on a mainnet fork by writing the delegate mapping and reading the strategy:

| Strategy / impl | `getTokenBalance` baseline | after +100,000 delegated LP | effect |
|---|---|---|---|
| old Kodiak `0x36bfa55a` | 552,650.05 | 552,650.05 (delegate slot only; balance unchanged) | ignores delegate total |
| old Kodiak, simulated `delegateStake` (+10k to balance **and** delegate total) | 552,650.05 / NAV 76,542.18 | 562,650.05 / NAV 77,927.19 | **NAV inflated** |
| new Kodiak `0xc6865dc8` | 556,214.99 / NAV 77,010.17 | 456,214.99 / NAV 63,164.77 (delegate slot only) | **subtracts** |
| old Bend `0x64812160` (simulated +10k) | 76,175.04 / NAV 76,818.81 | 86,175.04 / NAV 86,903.33 | **NAV inflated** |
| new Bend `0xee965e0a` (real slot simulation +10k) | 76,632.83 / NAV 77,293.19 | 66,632.83 / NAV 67,207.02 | **subtracts** |

The new impl's `getTotalDelegateStaked` call explains the previously unexplained selector
`0x2936f68f` in wave-2. It is **not a selector**: the compiler materialised
`getTotalDelegateStaked(address)` = `0xa4dbda3c` as `PUSH4 0x2936f68f; PUSH1 0xe2; SHL`
(`0x2936f68f << 226` has `0xa4dbda3c` in its top 4 bytes). Naive `PUSH4` scans miss it.

The mid implementation `0x807982bb` was deployed 50 minutes after the BeraFarm pause; the
Oct-11 `0xc6865dc8` replacement is 843 bytes smaller. Both are unverified; the current
on-chain behaviour of `0xc6865dc8` was verified directly with a **real** `delegateStake`
call (NAV unchanged; full attack −264 HONEY).

### 2.2 New KodiakSwapController: balance-delta accounting

Both versions expose the same public, unpermissioned `swap(address,address,uint256,uint24,uint256)`
and `swapWithIntermediary(...)`. Both pull `_amountIn` from `msg.sender` via
`safeTransferFrom` and send the output back to `msg.sender`, so the controller holds no
third-party funds and has no standing allowance from the strategy (the strategy resets and
approves per call).

The new bytecode adds `IERC20.balanceOf(address(this))` reads (selector `0x70a08231`) around
the transfers (3 occurrences; absent from the old controller) and uses the **actual received
amount** rather than the router's return value. `exactInputSingle`/`exactInput` and the
oracle-based min-amount check are unchanged. This is defensive hardening (fee-on-transfer /
non-standard return values); no unprivileged extraction path was found in either version.

## 3. Verification summary

- The **only** material difference relevant to the Oct-9 incident is the delegated-stake
  subtraction in the three gauge-staking strategies (Kodiak + two Bend).
- The current on-chain code is **consistent with the source-level intent** of the patch:
  live `getTotalDelegateStaked(strategy) == 0`, and a real `delegateStake` of ~1.2m island LP
  leaves the strategy NAV and the vault's junior rate unchanged.
- Residual unknown: the new source is not published, so the audit is behavioural
  (fork + storage-level) rather than source-level. A future upgrade to an
  old-class implementation would re-arm the vector.
