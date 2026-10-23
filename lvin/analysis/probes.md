# Live eth_call probes (read-only) — BSC mainnet, block 129,283,473

| call | from | result |
|---|---|---|
| `recycle(uint256)` `0xdd1c35bc` arg=1 | `0x…beef` (random EOA) | revert **`recycle fail`** |
| `recycle(uint256)` arg=1 | `0xe120bBf90eb051A43A3BDc0408b194b6F99b488E` (Stake) | **success (0x)** — gate is exactly `stake == msg.sender` |
| `Stake.transfer(address,uint256)` arg=`(0xbeef,1)` | `0x…beef` | revert **`sell amount fail`** (no reward → sell() aborts before recycle) |
| `Stake.transfer(address,uint256)` arg=`(TOP_STAKER,1)` | `0x28AC07…6039` (top staker, EOA) | **success** → `sell()` → `token.recycle(reward)` fires |
| `TOKEN.setStake(address)` | `0x…beef` | revert `OwnableUnauthorizedAccount(0x…bEEF)` (owner renounced) |
| `TOKEN.owner()` | any | `0x0000…0000` (renounced) |
| `STAKE.owner()` | any | `0x0000…0000` (renounced) |
| `UC.registerForAddr(TOP_STAKER)` | `0x…beef` | **success (0x)** — permissionless registration |
| `UC.getOpenActive()` | any | `0` |

Selector notes:
- `recycle(uint256)` = `0xdd1c35bc` (LULA-family selector) present in TOKEN runtime bytecode.
- `sync()` `0xfff6cae9` and `getReserves()` `0x0902f1ac` in TOKEN bytecode are the *interface* selectors
  used by TOKEN to call the pair (`IUniswapV2Pair.sync()`), not token functions.
- `TOKEN._isExcludedFromFees[stake] = 1` (slot `keccak(stake,23)`), so recycle's transfer is fee-free.

Reached via `Stake.sell()`:
```
Stake.transfer(to,value)  [value != 3 ether]
  require(!isContract(msg.sender) && tx.origin==msg.sender)
  -> sell(msg.sender)
       sellAmt = getAllReward(account)   // balances + staticReward + dynamicReward
       require(sellAmt>0)
       require(u.resetId==resetId); require(u.outAmt>0)
       require(token.balanceOf(stake) >= sellAmt)
       ... swap LVIN->USDT ...
       token.recycle(sellAmt)            // msg.sender == Stake == TOKEN.stake  -> passes gate
```
