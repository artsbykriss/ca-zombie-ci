# Printr — extraction attempts and negative results (audit trail)

All checks below are read-only (`eth_call` with arbitrary `from`, `eth_getStorageAt`, `eth_getCode`) or
fork-only Foundry tests. None were ever sent to a real chain. Selectors were computed with `cast sig` and
verified against the deployed dispatchers (evmole).

## 1. Treasury drain attempts — CLOSED

| attempt | target | result |
|---|---|---|
| `withdraw(WETH, attacker, 1)` from attacker | treasury `0x8c843012…3fee` | revert `WrongAccess()` (0x6c5ffd54) |
| `withdraw(WETH, attacker, 1)` from core `0xb77726…3172` | treasury | success (returns 0x) |
| same two probes | legacy treasury `0xde420c83…1549` | attacker → `WrongAccess()`; `printr()` immutable = core |
| call `printr()` on both treasuries | — | both return the core proxy; immutable, not storage → cannot be re-pointed |

The treasury bytecode (2,228 B) exposes exactly 4 selectors: `withdraw` (d9caed12), `collectLiquidityFees`
(913233ef), `onERC721Received` (150b7a02), `printr` (f7cca092). Only the core can invoke the first two.

## 2. Admin/upgrade attempts — CLOSED (P)

`eth_call` from attacker (`0x…dEaD`) against the proxy:

| call | error |
|---|---|
| `pause()` / `unpause()` | `OwnableUnauthorizedAccount(address)` = 0x118cdaa7 |
| `transferOwnership(attacker)` / `renounceOwnership()` | `OwnableUnauthorizedAccount` |
| `upgradeToAndCall(attacker, "")` | `OwnableUnauthorizedAccount` |
| `updateGlobalProtocols([],[])` | `OwnableUnauthorizedAccount` |
| `updateTelecoinProtocols(bytes32(0),[],[])` | `OwnableUnauthorizedAccount` |
| `setLzDelegate(2, attacker)` | revert (owner-gated in the teleport decompile) |

Owner is a single EOA `0x8dd1886ba3ab106f595ab7a8a831577c2d21c273` (code size 0) on every chain checked.
Upgrade path = module's UUPS `upgradeToAndCall` (Ownable2Step) → privileged only.

## 3. Cross-chain mint attempts — CLOSED

`receiveFromChannel(uint8 protocol, bytes32 originSender, bytes message)` (0x08e56f01) lives in the teleport
contract (delegatecalled). Decompilation (heimdall) + live probes show three gates:

1. `msg.sender` must equal the CREATE3-computed channel address for the protocol.
2. `protocol == 2` (LZ_FAST); 0/1/3/4 rejected.
3. `originSender` must equal the hard-coded Solana peer
   `0x27289e1d3b5c3af5e16600167c7463fcaa125509fc61e2de08491aece7993b5f`.

Live matrix (block ~26.19M):

| from | peer | result |
|---|---|---|
| attacker | correct peer | `UnauthorizedCaller()` (0x5c427cd9) |
| channel `0x69b20d72…c384` | wrong peer | `UnauthorizedCaller()` |
| channel | correct peer | passes → payload parser → `InvalidPayloadLength()` (0x5e7407c2) |

The LZ channel itself (`0x69b20d72…`) requires `msg.sender == LZ endpoint` in `lzReceive` and gates
`send`/`setDelegate` on `msg.sender == printr` (`OnlyPrintr()`), so a forged message cannot be injected.
Mint (`teleportIn`) and burn (`teleportOut`) on the token contracts are additionally `msg.sender == printr`.

## 4. Trading round-trip attempts — CLOSED

Three live Ethereum telecoins with active curves were exercised on the fork:
`0xaE0f1B6a…77777`, `0x8aE65D8a…60226`, `0xB685dAB7…77777`.

- `spend{value: 0.01 ETH}(token, attacker, 0.01 ETH, 0)` buys tokens (succeeded on the first two tokens;
  amounts 4,901,706.14 and 272,739.56 tokens).
- `sell(token, attacker, balance, 0)` requires an ERC20 approval to the core (normal holder flow).
- After approval the round trip completes at a net ETH loss (1 % fee each way + protocol-favouring rounding;
  `_estimateTokenCost` rounds cost up, `_estimateTokenRefund` rounds refund down, `_quoteTokenAmount` subtracts
  1 wei on inexact division). Assertion in the PoC: `after < before` for every completed round trip.

No donation/price manipulation: the curve reserve is an internal storage value, not a `balanceOf`; donating
WETH to the treasury does not change pricing. Fee-on-transfer or malicious basePair tokens chosen by a creator
cannot extract real assets from the treasury (withdrawals for that basePair are bounded by its own balance).

## 5. Fee-collection attempts — CLOSED for the attacker

`collectProtocolFees(address)` (0x2a54db01, module) is **permissionless** — the attacker's call succeeds — but
it distributes `collectedFees[token]` to growth/buyback/team funds and the creator NFT owner (30 %), or to the
staking contract when staking is enabled. Fork measurement on three tokens with accumulated fees
(0.000659 / 0.013980 / 0.000637 WETH): attacker ETH delta = 0, WETH delta = 0, token delta = 0.
`collectLiquidityFees(address)` (0x372d695b) similarly routes LP fees to the same recipients via
`treasury.collectLiquidityFees`.

`getAccumulatedProtocolFees` was used to find tokens with fees; the mapping is zeroed before payout, so no
double-collection.

## 6. Creator-NFT capture — CLOSED

`printrDev` = `0x1e1577ba4dc74007ed6e8fb3d3ce2ce5477f531d` (9,880 B). `mint(bytes32,address)` (0x293c6a3a) from
an attacker reverts with `0x878d41a8` (custom error, mint gated). Becoming the “creator” of an existing
telecoin to capture the 30 % creator fee share is therefore not possible without the protocol's cooperation.

## 7. Witness/permit redirect — CLOSED (source-verified token)

`PrintrTelecoin` (verified source) `permitWitnessCall`:
- binds `keccak256(abi.encode(WITNESS_CALL_TYPEHASH, target, method, nativeValue, params))` into the signed
  witness (EIP-712 nested type), so the recipient/amount inside `params` cannot be swapped;
- enforces `params[0:32] == owner` (protects `witnessSell`, whose first param is the signer);
- rejects `target == address(0) || target == address(this)`;
- increments the owner's nonce, checks deadline, and requires `msg.value >= nativeValue`.
`witnessSell` in the core additionally requires `msg.sender == token`.

## 8. Other dead ends

- `LZ_SECURE` (3) and `LZ_SLOW` (4) channels are **not deployed** on Ethereum (`getLzChannel` returns
  codeless addresses) → only LZ_FAST teleports can be received; protocols 3/4 revert (liveness issue only).
- Legacy treasury holds only spam/dust tokens ($0 non-spam); staking contract holds dust on Ethereum and
  $0.02 on Base.
- `spend`/`buy` with `type(uint256).max` uses only the caller's own balance/allowance (`_getMaxAmount`);
  native refunds sweep only the current transaction's leftover ETH.
- `migrateTreasury` pulls funds from the legacy treasury **into the current treasury** (recipient is the
  treasury), never to the caller.
