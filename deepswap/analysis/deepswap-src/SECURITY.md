# Security policy

## Reporting a vulnerability

Please report security issues privately, never in a public issue, pull request or discussion.

- **Email:** security@deepliquidity.fun
- **GitHub:** [report a vulnerability privately](https://github.com/Deep-Liquidity/contracts/security/advisories/new)
  in this repository.

Please include the program, the instruction or accounts involved, the impact you expect (funds at
risk, funds stuck, denial of service, wrong accounting), and steps or a test that reproduce it.
Please give us reasonable time to fix the issue before you disclose it.

## Scope

The three DEEP programs whose source is in this repository:

| Program               | Mainnet program ID                             |
| --------------------- | ---------------------------------------------- |
| `deep-curve`          | `7czURwVLkQpcF1HVhhZU5GGzvPA8YniogZY1BhZHCDtA` |
| `deep-amm` (DeepSwap) | `HCrCy6bzHhZ1b6bXwQAucEFkKXyzYMh3hgAR8UPrYSEP` |
| `deep-rewards`        | `4z2KpxUcdNFXFpzxKtcmTv6aDMqE4CMLCdbYExLYeDE2` |

Issues in the DEEP web app, API or SDK can be reported to the same address.

## Upgrades

The programs' upgrade authority is DEEP's Squads multisig, with a 48-hour time lock on every
upgrade. Each mainnet binary can be checked against this source with `solana-verify` (see the
README).
