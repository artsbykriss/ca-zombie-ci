# Cega V1 EVM side — OUT OF SCOPE (notes retained)

The parent's initial target (CEGA_STATE / CEGA_PRODUCT_VIEWER + FCN/LOV products) is the **V1 EVM
deployment**, not DefiLlama slug `cega-v2`. Work was stopped on request.

Partial findings captured before the correction (read-only, public RPC):

- ETH CegaState 0x0730AA138062D8Cc54510aa939b533ba7c30f26B (verified, non-proxy); ARB 0xc809B7F21250B1ce0a61b7Fb645AEf5CE7c1B5ed
- ETH viewer 0x31C73c07Dbd8d026684950b17dD6131eA9BAf2C4 ; ARB viewer 0x8c32a5d9f29da36ed68a9d454eda1b374795b6ca (both verified, non-proxy, EIP-1967 slots empty)
- Structural note that also applies to V2: FCNVault holds **no** tokens; share mint/burn is `onlyOwner` (the product);
  all USDC sits in the *product* contract. `checkBarriers` / `calculateVaultFinalPayoff` are permissionless;
  every value-moving function (`processDepositQueue`, `processWithdrawalQueue`, `collectFees`, `sendAssetsToTrade`,
  `moveAssetsToProduct`) is TRADER_ADMIN-gated.
- Four contract addresses above are the parent's verified list; no vulnerability claim is made here.
