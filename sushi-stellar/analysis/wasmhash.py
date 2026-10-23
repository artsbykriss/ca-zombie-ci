#!/usr/bin/env python3
"""Read-only Soroban helpers. Keyless public RPC. Never signs/sends."""
import json, sys
from stellar_sdk import SorobanServer, xdr, Address, StrKey

RPC = "https://mainnet.sorobanrpc.com"

def instance_wasm_hash(cid):
    s = SorobanServer(RPC)
    k = xdr.LedgerKey(type=xdr.LedgerEntryType.CONTRACT_DATA)
    k.contract_data = xdr.LedgerKeyContractData(
        contract=Address(cid).to_xdr_sc_address(),
        key=xdr.SCVal(xdr.SCValType.SCV_LEDGER_KEY_CONTRACT_INSTANCE),
        durability=xdr.ContractDataDurability.PERSISTENT)
    r = s.get_ledger_entries([k])
    out = []
    for e in r.entries:
        le = xdr.LedgerEntry.from_xdr(e.xdr)
        inst = le.data.contract_data.val.contract_instance
        out.append(inst.executable.wasm_hash.hex())
    return out

if __name__ == "__main__":
    for cid in sys.argv[1:]:
        print(cid, instance_wasm_hash(cid))
