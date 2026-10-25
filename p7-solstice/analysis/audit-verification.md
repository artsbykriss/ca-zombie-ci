# Verifying an Audit Report Against the Chain

**A reproducible method for independently checking what a smart contract audit actually proves — worked through on Solstice Finance's USX program on Solana.**

---

## Summary

Audit reports publish build hashes and protocols publish security claims. Almost nobody checks either. Both are checkable in about ten minutes from a public RPC endpoint, with no credentials and no special tooling.

This is that check, run end to end against a live protocol.

**Result: every on-chain claim Solstice Finance makes on its security page holds.** The deployed bytecode matches the hash published in Halborn's March 2026 assessment. The upgrade authority is a Squads v4 multisig configured 3-of-5 with a 24-hour timelock, exactly as stated, with the configuration authority nulled so the parameters cannot be changed except through the multisig's own process.

Three items remain open, none of them a vulnerability. They are documented below.

**This is a verification exercise, not a vulnerability disclosure.** Everything referenced is published by the vendors or readable from public chain state. Nothing here asserts that any protocol is unsafe, and no non-public information was used or sought.

---

## Why this matters

An audit report is a claim about a specific artifact at a specific commit. A security page is a claim about a running system. Neither is self-verifying, and the gap between them is where reasonable people get misled — usually not through deception, but through imprecision that nobody ever checks.

The interesting question is not "did the auditor find bugs." It is "what did the auditor actually look at, and is that still what's running."

---

## What can and cannot be verified

| Claim | Third-party verifiable? |
|---|---|
| Deployed bytecode matches the published hash | Yes |
| Program is upgradeable, and by whom | Yes |
| Multisig threshold, timelock, members | Yes |
| Timelock is actually enforced | Yes, observationally |
| Published hash was built from the audited source | **No** |
| Signer device hygiene, key custody | **No** |

The last two rows bound the whole exercise. On-chain verification is powerful about configuration and silent about people.

---

## Subject

Solstice Finance is a Solana protocol issuing USX, an overcollateralized settlement asset, with yield strategies layered on top. The USX program was assessed by Halborn from **March 25–27, 2026** (report last updated 03/31/2026).

Program under test:

```
USX Program     USXyiSTsPEWz55pSK7sZoUL79ntoVGQbaTDT57tH6bx
ProgramData     3P5mNf86DSd2CNu1DToPBxbvqQL4V2kNwAQjErCwZxMq
```

---

## Finding 1 — Read the scope before the findings

The report's headline is two Informational findings, both acknowledged, neither remediated. The more useful information is the scope.

The engagement covered **nine files**, was allotted **two days**, and used **one engineer**. The assessment summary states it plainly: scoped to *the updated freeze token functionality*.

Files in scope:

```
programs/usx/src/events.rs
programs/usx/src/instructions/edit_program_admin.rs
programs/usx/src/instructions/freeze_token.rs
programs/usx/src/instructions/initialize_program_admin.rs
programs/usx/src/instructions/mod.rs
programs/usx/src/lib.rs
programs/usx/src/state/program_admin.rs
programs/usx/src/utils/validate_token_extension.rs
tests/src/api/program_usx/process_freeze_token.rs
```

This is a delta review of one change, not a re-audit of USX. The mint and redeem escrow flow, the two-step request/confirm logic, and collateral accounting were not re-examined in this engagement.

Two earlier engagements are bundled in the same PDF — YieldVault (Dec 1–3, 2025, two Informational findings, both **solved** 01/28/2026) and Rewarder (Dec 8–15, 2025, no findings). Both state *economic attack vectors* explicitly out of scope.

That exclusion is the correct boundary for a program audit. It is also worth stating clearly, because it means the audit stack is silent on liquidity and market-structure failure modes by design.

### Reading a severity score

The Token-2022 finding is a good specimen of why severity ratings need decoding rather than skimming. The `DISALLOWED` extension list was reduced to a single entry:

```rust
const DISALLOWED: [ExtensionType; 1] = [
    // ExtensionType::TransferFeeConfig,
    // ExtensionType::TransferHook,
    ExtensionType::InterestBearingConfig,
    // ExtensionType::PermanentDelegate,
    // ExtensionType::ConfidentialTransferMint,
    // ExtensionType::ConfidentialTransferFeeConfig,
    // ExtensionType::MintCloseAuthority,
    // ExtensionType::NonTransferable,
];
```

Scored `AO:S/AC:L/AX:M/R:N/S:U/C:N/A:N/I:N/D:C/Y:N (1.3)`.

Note `D:C` — deposit impact is **Critical**, the maximum. The score lands at 1.3 and gets labelled Informational entirely because of `AO:S`, "attack origin: specific", which applies a 0.2 exploitability multiplier. In plain terms: catastrophic impact, gated behind an authorized actor.

Solstice acknowledged and declined to change it, stating they intend to accept collateral case by case with governance-level assessment. That is a defensible product decision. It also means collateral safety moved from compiler-enforced to process-enforced, and the strength of the control is now the strength of the governance.

Which is precisely why the rest of this exercise is about identifying that governance.

---

## Finding 2 — The bytecode is authentic

The report publishes two values for commit `a940fa`:

```
sha       f7c99b7ca1cd3e545cfbd2e623cece54156d41b9254dee8672e23a0cf3c1f3ee
checksum  b6f5881bc078f4f870692a0276ed270fe2b19b14989d8db41eaef24d4481c513
```

An upgradeable Solana program is two accounts. The Program account holds a pointer; the ProgramData account holds a 45-byte header followed by the ELF. Because the account is over-allocated so a larger future upgrade fits, the ELF is followed by zero padding — so a naive `sha256` of the account body matches nothing. The *executable hash* is `sha256` of the bytecode with trailing zeros stripped.

Result:

```
total account size ....... 963485 bytes
bytes after 45B header ... 963440
bytes after zero-trim .... 924705
zero padding ............. 38735 bytes
ELF magic ................ 7f454c46

sha256(padded body) ...... 1c60358051d4f890ae94894ca6a0c7d17466e02b9f3f7cde5391895bbc161122
sha256(zero-trimmed) ..... f7c99b7ca1cd3e545cfbd2e623cece54156d41b9254dee8672e23a0cf3c1f3ee
```

**The published `sha` matches the zero-trimmed executable hash exactly.** The bytecode running on mainnet is the artifact Halborn hashed.

I expected the opposite mapping — `checksum` as the executable hash, `sha` as the local artifact. It is the reverse. The tool computes both and reports which matched rather than assuming; assuming would have produced a false negative.

**Open item:** `checksum` `b6f5881b…` matches neither computation, and the report does not document how it was derived. A published value a third party cannot reproduce or interpret is a documentation gap, not a defect.

---

## Finding 3 — "Non-upgradeable" needs a careful reading

Solstice's security page states, under *Security Architecture — Defence in depth*:

> **Non-Upgradeable** — USX and SLX tokens use non-upgradeable SPL programs. Deployed code cannot be changed. Zero proxy contract risk.

On-chain, the USX Program has a live upgrade authority. Byte 12 of ProgramData is `1`:

```
last deployed slot ... 410547056  (2026-04-02 14:10:34 UTC)
upgrade authority .... BzMuMbtah9bqN4HERkPo2PsVoaQKD2xfvYq1xfDCFwEb
status ............... UPGRADEABLE
```

A narrow reading of the claim is defensible: the USX *token mint* uses the standard SPL Token program, which is genuinely immutable and is a separate thing from the USX *Program*. Under that reading the sentence is true and simply does not cover the audited program.

A reader encountering it beside "PDA-Only Minting" and "Squads Multisig", under a heading about defence in depth, will reasonably conclude the protocol's programs cannot be changed. They can be.

This is recorded as **imprecise wording, not a false claim**. The substantive question is what controls that authority — which turns out to be reassuring.

---

## Finding 4 — Identifying the authority correctly

The authority account returns:

```
owner ....... 11111111111111111111111111111111   (System Program)
data len .... 0
```

**This is not sufficient to conclude anything.** A plain wallet and a Squads vault PDA are indistinguishable by that query — both are System-owned with zero data. Concluding "single keypair" here would have been wrong, and would have been the most dramatic and most incorrect finding in the piece.

The decisive test is ed25519 curve membership. Real public keys are valid curve points; PDAs are off-curve by construction, which is what the bump seed search guarantees.

```
BzMuMbtah9bqN4HERkPo2PsVoaQKD2xfvYq1xfDCFwEb
  hex ......... a3469c30483a30c60a95f20b74e207c83d71d10be36379a2d6300a9b94d5bd0c
  on curve .... False
  => OFF CURVE (PDA)
```

Off curve. No private key exists for this address; it is controlled by a program.

The deploy transaction identifies which:

```
Program SQDS4ep65T869zMMBKyuUq6aD6EgTu8psMjkvj52pCf invoke [1]
Program log: Instruction: VaultTransactionExecute
Program BPFLoaderUpgradeab1e11111111111111111111111 invoke [2]
Upgraded program USXyiSTsPEWz55pSK7sZoUL79ntoVGQbaTDT57tH6bx
```

Squads Protocol v4.

---

## Finding 5 — The configuration verifies

Multisig account `AEb1u8FK8EuXLcPtprCy8s4NkqBNoP5mfbuEEop2dJGf`, decoded against the Squads v4 layout:

```
threshold ................. 3
members ................... 5
=> configuration .......... 3 of 5

time_lock ................. 86400 seconds  (24.00 hours)
transaction_index ......... 242
config_authority .......... 11111111111111111111111111111111  (None)

members:
   0  BSfsLADCq7q6xDh28HQWcZXqE27ZKKRz24PHsRzMxXZK   Initiate+Vote+Execute
   1  DtWpcoMN5LMKmvw4sRXVArExBBDyHNk1mQ7DrbYhGADS   Initiate+Vote+Execute
   2  E1iyboRnxBSD8KJncj8mkkzbJu17gr5w6CiTN6q4YoUN   Initiate+Vote+Execute
   3  EBCXuPcvNP39vbVSjadH7YwtKRt47iWK7Xs2yATDhmJ7   Vote
   4  GHynRYHV1YcePhhRRKvicCvVqnWvnSPm1GiVj7s34K7r   Vote
```

Every published claim matches. Two details exceed what is advertised:

**`config_authority` is null.** No external key can alter the threshold or timelock. Any configuration change must itself pass the 3-of-5 and serve the 24-hour delay. This is the strongest available setting and is not mentioned on their security page.

**Permissions are split.** Three members can initiate and execute; two can only vote. All five participate in approval; only three can act.

### The timelock is enforced, not just declared

Proposal `D9jbhs8GTids54Fsuke3Swa3vkZ1cw8FhsdzaNQFSAvP` lifecycle:

| Time (UTC) | Event |
|---|---|
| 2026-03-31 12:44:54 | proposal activity |
| 2026-03-31 15:51:51 | proposal activity |
| 2026-04-01 09:30:46 | final approval |
| 2026-04-02 14:10:34 | **execute — program upgraded** |

**28h 39m 48s** from final approval to execution, against a declared 86400s. Declared configuration and observed behaviour agree.

The deploy also falls six days after the engagement closed on March 27 — audited, then deployed, in the correct order.

---

## A methodological error worth recording

Partway through, I inferred the member count from the account size. 495 bytes factors cleanly as 11 members with `rent_collector = Some`, and as 11.97 — impossible — with `None`.

The decoder reports `bytes consumed 265 of 495`. Squads over-allocates the account so members can be added later, so total size never constrained anything.

**On Solana, allocated account size tells you nothing about contents. Decode the length prefix.** I am leaving this in rather than quietly removing it, because the failure mode — an elegant inference that happens to be false — is the one worth guarding against.

---

## Open items

None of these are vulnerabilities. All are gaps in what a third party can confirm.

**1. Source is not independently verifiable.** The report states artifacts were reproduced via `anchor build --verifiable` from the `usx-program` repository. No public repository by that name exists. The bytecode-to-hash link is verifiable; the source-to-hash link rests entirely on the auditor's attestation. Normal for a closed-source protocol, but it bounds what "verifiable build" means to anyone outside the engagement.

**2. The `checksum` value is unexplained.** `b6f5881b…` matches neither the padded nor the trimmed hash, and its derivation is undocumented.

**3. An undocumented program sits in the privileged call path.** `L2TExMFKdjpN9kozasaurPirfHy9P8sbXoAN1qA3S95` appears as a top-level instruction in every privileged transaction examined, is executable, consumes exactly 1425 compute units each time, and emits no logs. Constant cost with no output is consistent with a marker or attribution program appended by the transaction-building client, not part of the authorization path. Recorded as unidentified rather than guessed at.

**4. Documentation date error.** The public audits page lists the USX engagement as `3/27/2025`. The report gives March 25–27, **2026**. Corroborated on-chain: the first deploy to this ProgramData account was 2025-06-20, one week after the `13/06/2025` core-contracts audit listed in an earlier version of that page. The 2025 entry is a typo. Reported to the vendor prior to publication.

---

## An architectural observation

`transaction_index = 242`.

Two hundred forty-two transactions have passed through the multisig that can replace the program's bytecode. Inspection shows these are not all upgrades — several execute `InitializePermissionedAccount` against the USX program, which given Solstice's documented model (KYC'd institutional partners mint and redeem) is routine counterparty whitelisting.

So upgrade authority and routine operational authority share one vault. Member 0 fee-paid and executed both the April upgrade and a July operational transaction.

This is an architectural choice, not a flaw. Separating privileged upgrade authority from operational authority into distinct multisigs with different thresholds is a recognized pattern, and the reason is behavioural: a vault used weekly trains its signers to treat approvals as routine.

Which leads to the only serious residual risk.

---

## What none of this can tell you

On April 1, 2026, Drift Protocol lost approximately $285M. No contract was broken. Attackers ran a months-long social engineering campaign, compromised contributor devices, and induced signers to pre-sign malicious governance transactions using durable nonces. Drift's Security Council was **also Squads v4** — configured 2-of-5 with a zero-second timelock. Execution took about twelve minutes.

Solstice is configured better on both axes that failed there: 3-of-5 rather than 2-of-5, and a 24-hour timelock rather than none. The timelock in particular changes the economics — a malicious proposal sits publicly on-chain for a day and can be cancelled, so the same attack would require the compromise *plus* twenty-four hours of nobody noticing.

That is a real defence. It is also a *detection* defence, which makes incident tooling load-bearing. Halborn's second finding — that `freeze_token` returns raw SPL errors instead of protocol-defined ones, making operational tooling and incident handling brittle — was acknowledged and not remediated. Detection at hour twelve is worth little if the emergency controls are the part you have not hardened.

Everything verified in this piece is the observable layer. Whether signers use hardware wallets, whether they would recognize a misrepresented transaction, whether anyone has been cultivating them at conferences for six months — none of that is on chain.

And within the governance layer, that is now the largest remaining risk, essentially by elimination. There is no configuration weakness left to attack.

**Though governance is not the largest risk to capital in this protocol.** Governance compromise has not happened here. A 90% depeg has — in December 2025, when secondary market depth on Orca and Raydium was overwhelmed and the peg was restored by manual liquidity injection about three hours later. The structural condition behind it is unchanged: primary redemption remains gated at KYC and a $500K minimum, so retail exit runs entirely through AMM depth. Nor does any of this touch off-chain custody, exchange counterparty exposure on the delta-neutral book, or newer products such as aiUSX and strcUSX, which are credit instruments rather than delta-neutral positions and settle into the same asset.

Honest ranking of residual risk: liquidity and redemption asymmetry first, off-chain counterparty second, social engineering third. Third is still real, and it is the one whose downside is catastrophic rather than merely painful.

---

## Reproduce it

Python 3 only. No Solana CLI, no Docker, no Rust toolchain, no API key.

```bash
python verify_program.py --program USXyiSTsPEWz55pSK7sZoUL79ntoVGQbaTDT57tH6bx \
  --rpc https://api.mainnet-beta.solana.com \
  --expect-sha f7c99b7ca1cd3e545cfbd2e623cece54156d41b9254dee8672e23a0cf3c1f3ee \
  --expect-checksum b6f5881bc078f4f870692a0276ed270fe2b19b14989d8db41eaef24d4481c513

python oncurve.py BzMuMbtah9bqN4HERkPo2PsVoaQKD2xfvYq1xfDCFwEb
python whodeployed.py 3P5mNf86DSd2CNu1DToPBxbvqQL4V2kNwAQjErCwZxMq
python ixaccounts.py 4wdJagCYXakXePcxUH1fe27no3EVsKaDsUUENdMqtDUWVa57Zf6VWNa5neBft9Vk25aDcHUokUgE2HZWR4T3Lahw
python msdecode.py multisig.bin
```

All scripts are read-only. They issue `getAccountInfo`, `getSignaturesForAddress`, `getTransaction`, and `getBlockTime` calls and nothing else. No keypair is loaded, no transaction is signed, no wallet is touched. Verify that yourself before running them — that is rather the point.

---

## Verdict

| Claim | Result |
|---|---|
| Bytecode matches published audit hash | **Verified** |
| Squads 3/5 multisig | **Verified** |
| 24-hour timelock declared | **Verified** (86400s) |
| 24-hour timelock enforced | **Verified** (28h 39m observed) |
| Signer addresses disclosed | **Verified** |
| Configuration authority locked | **Verified** (exceeds claims) |
| Deploy followed audit | **Verified** (six days after) |
| "Non-upgradeable" as written | **Imprecise** |
| Source-to-hash reproducibility | **Not verifiable** |
| `checksum` derivation | **Undocumented** |

Solstice's on-chain security posture is what they say it is, and in one respect better. The findings here are documentation and reproducibility gaps, not defects.

The method is the point. It works against any Solana protocol, takes about ten minutes, and requires nothing but a public endpoint.

---

*Published in good faith and without coordination with Solstice Finance beyond notifying them of the documentation date error. All data is public chain state or vendor-published material. Corrections welcome via issue or PR.*
