#!/usr/bin/env python3
"""Anchor discriminator helper. disc = sha256(prefix:name)[:8].
Account disc: sha256("account:"+Name)[:8]; instruction: sha256("global:"+ix)[:8].
Read-only."""
import hashlib

IX = ["Initialize","GrantRole","RevokeRole","InitProposeChain","InitProposeToken",
      "SetContractStatus","DepositNative","DepositToken","ProposeDeposit","ReviewToken",
      "ReviewTokenSolV1","InitRiskConfig","UpdateRiskConfig","ApplyRiskConfig",
      "AddWhitelistEntry","RemoveWhitelistEntry","ApplyWhitelistEntry","ReviewNative"]

ACC = ["BridgeAccount","Custody","NativeVault","ProposeAccount","ReviewAccount",
       "RiskConfig","RiskConfigPending","RiskWindowStat","WhitelistEntry",
       "WhitelistPendingEntry","AddressFreqStat","AccessControl","RoleData"]

def ix_disc(name): return hashlib.sha256(("global:"+name).encode()).digest()[:8]
def acc_disc(name): return hashlib.sha256(("account:"+name).encode()).digest()[:8]

IX_DISC = {n: ix_disc(n) for n in IX}
ACC_DISC = {n: acc_disc(n) for n in ACC}
ACC_BY_DISC = {v: k for k, v in ACC_DISC.items()}
IX_BY_DISC = {v: k for k, v in IX_DISC.items()}

if __name__ == "__main__":
    for n in IX:
        print("global:", n, ix_disc(n).hex())
    for n in ACC:
        print("account:", n, acc_disc(n).hex())
