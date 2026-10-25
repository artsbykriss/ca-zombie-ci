# Evidence record — Solstice YieldVault (eUSX) deep-dive

All reads read-only, slot 461,377,202 / blocktime 1792956767 (2026-10-25 ~18:52 UTC), unless noted.

## Program ELF hashes (zero-trimmed executable, sha256)
- YieldVault `eUSXyKoZ6aGejYVbnp3wtWQ1E8zuokLAJPecPxxtgG3` (programdata `BVDochYTcRGvCYmmdtsiX9qT63fy5dmGSB5hNgxMTbJY`):
  `77466e8b0805ae78a520de1bc4e0c614d97294cd1c2fc9a247edc965888fc19e` (613,216 B; last deploy slot 416,855,566)
- USX `USXyiSTsPEWz55pSK7sZoUL79ntoVGQbaTDT57tH6bx` (programdata `3P5mNf86DSd2CNu1DToPBxbvqQL4V2kNwAQjErCwZxMq`):
  `9901246e611934a9fd550178917953867744dea91e7a4193b8b05193b86b33ba` (963,440 B; last deploy slot 441,672,563)

Upgrade authorities: both **off-curve PDAs** (Squads v4 vaults) —
`CYr14TrXD5MAertRqcR58KirPz7XoHGZjfBsfn5M2voh` (YieldVault), `BzMuMbtah9bqN4HERkPo2PsVoaQKD2xfvYq1xfDCFwEb` (USX).

## PDA seeds (from IDL + ELF)
`CONTROLLER`, `VESTING_SCHEDULE`, `YIELD_POOL`, `ASSET_VAULT`, `SHARE_MINT`,
`PERMISSIONED_ACCOUNT`(+party), `COOLDOWN_ESCROW`(+user), `COOLDOWN_ESCROW_VAULT`(+user), `REDEEMABLE`.
Derivation verified against live accounts (controller/pool/vault/vesting/escrow all match).

## Error catalogue (YieldVault, from ELF + IDL)
6000 ProgramFrozen · 6001 InvalidMintDecimals · 6002 InvalidVestingPeriod · 6003 InvalidCooldownPeriod ·
6004 ProgramFreezeStatusUnchanged · 6005 LastVestingNotEnded · 6006 InvalidCurrentBlockTime · 6007 InvalidOwner ·
6008 InvalidAuthority · 6009 InvalidPermissions · 6010 InvalidPermissionRights · 6011 InvalidAssetMint ·
6012 InvalidShareMint · 6013 CooldownNotEnded · 6014 InvalidAmount · 6015 InsufficientFunds · 6016 MathError ·
6017 ZeroShareAmount (“Cannot mint zero share.”) · 6018 InvalidAuthorityTransfer.
Anchor framework: 2006 ConstraintSeeds · 3007 AccountOwnedByWrongProgram.

## Source modules (from ELF debug strings)
`programs/yield-vault/src/instructions/{lock,unlock,withdraw,transfer_in_yield,initialize_*,edit_*,…}.rs`,
`src/state/yield_pool.rs`, `src/events.rs`,
`src/utils/{helper,maths,validate_amount,validate_controller,validate_cooldown,validate_permission,validate_yield}.rs`.
Anchor error source lines observed: `lock.rs:113`, `withdraw.rs:113`.

## Escrow population (getProgramAccounts)
13,956 `CooldownEscrow` accounts; 1,029 with `asset_amount > 0`; **556,229.813281 USX** total.
Top escrow `8JZqu1Svamiaw3Aikn6ikErUdEJvr65MsMkQQ5oUGdNG` (user `9HsFJKqobLFZ6QLT7xXhS3ggDfSGTJPUh2Rfug4VFGWh`)
holds `353,498.439895` USX with matching per-user vault balance `353,498.439895` (per-user escrow confirmed).

## Independent corroboration
`Hudgins333/solana-audit-verification` → `writeups/solstice-usx.md`: Halborn assessment Mar 25–27 2026
(scoped to USX freeze-token delta); **YieldVault audited Dec 1–3 2025** (two Informational, solved
2026-01-28); “economic attack vectors explicitly out of scope”. Solstice “Non-Upgradeable” applies to the
SPL **token** programs only; both protocol **programs** are upgradeable (3-of-5 Squads, 24 h timelock).
