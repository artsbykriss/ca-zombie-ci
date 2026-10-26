> For the complete documentation index, see [llms.txt](https://docs.wildcat.finance/llms.txt). Markdown versions of documentation pages are available by appending `.md` to page URLs; this page is available as [Markdown](https://docs.wildcat.finance/security-measures/code-security-reviews.md).

# Code Security Reviews

Independent and Code4rena security reviews of the Wildcat V1 and V2 contracts, with reports.

The Wildcat protocol contracts have been subjected to independent security reviews and crowdsourced review via Code4rena.

The code repository for V2 is available

The results of these reviews (and associated reports) are available here:

## Wildcat V2 Reviews

### [alpeh\_v](https://x.com/alpeh_v) \[Independent Security Review]

**Date**: 12 - 23rd August 2024

**Scope**: Entire protocol

**LOC**: \~4,700

**Results**:

* 2 medium
* 2 low
* 2 notes

**Report**: <https://hackmd.io/@geistermeister/BJk4Ekt90>

### [Code4rena](https://code4rena.com/) \[$100,000 Competitive Public Audit]

**Date**: 31 August - 18 September 2024

**Scope**: See README/Scope [here](https://github.com/code-423n4/2024-08-wildcat/tree/main?tab=readme-ov-file#scope).

**LOC**: 3,784

**Results**:

* 1 high
* 8 medium

**Report**: <https://code4rena.com/audits/2024-08-the-wildcat-protocol>

Followed up by two subsequent mitigation reviews by [alpeh\_v](https://x.com/alpeh_v).<br>

***

## Wildcat V1 Reviews

### [alpeh\_v](https://x.com/alpeh_v) \[Independent Security Review]

**Date**: 13 - 29th September 2023

**Scope**: `src/markets/*`, `src/libraries/*`, `src/ReentrancyGuard.sol`

**LOC**: \~1,500

**Results**:

* 1 critical
* 2 high
* 4 medium
* 2 low
* Various notes

**Report**: <https://hackmd.io/@geistermeister/r15gj_y1p>

### [Code4rena](https://code4rena.com/) \[$60,500 Competitive Public Audit]

**Date**: 16 - 25th October 2023

**Scope**: Everything except `src/interfaces/*`

**LOC**: 2,332

**Results**:

* 6 high
* 11 medium

**Report**: <https://code4rena.com/contests/2023-10-the-wildcat-protocol>
