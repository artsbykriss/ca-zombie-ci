#!/usr/bin/env python3
"""Read-only live-state reader for Sushi Stellar (keyless). simulateTransaction + getLedgerEntries only."""
import json, sys, time
from stellar_sdk import SorobanServer, TransactionBuilder, Network, scval, Address, xdr

RPC = "https://mainnet.sorobanrpc.com"
NET = Network.PUBLIC_NETWORK_PASSPHRASE
SRC = "GCFB64LD5OX6XXUQW44LXAE7RAHORF2FJTSQ3DXEAV6DXVOML433X6HF"
_s = SorobanServer(RPC)

def sim(cid, fn, params=None, source=SRC):
    acct = _s.load_account(source)
    tx = (TransactionBuilder(source_account=acct, network_passphrase=NET, base_fee=100000)
          .append_invoke_contract_function_op(contract_id=cid, function_name=fn, parameters=params or [])
          .set_timeout(60).build())
    return _s.simulate_transaction(tx)

def val(resp):
    if getattr(resp, "error", None):
        return {"__error__": resp.error}
    if resp.results and getattr(resp.results[0], "xdr", None):
        try:
            return xdr.SCVal.from_xdr(resp.results[0].xdr)
        except Exception as e:
            return {"__decode__": str(e)}
    return None

def instance_wasm_contains(cid, known_hashes):
    """Return which known wasm hash the contract instance points to (byte-search, no SDK xdr parse)."""
    k = xdr.LedgerKey(type=xdr.LedgerEntryType.CONTRACT_DATA)
    k.contract_data = xdr.LedgerKeyContractData(
        contract=Address(cid).to_xdr_sc_address(),
        key=xdr.SCVal(xdr.SCValType.SCV_LEDGER_KEY_CONTRACT_INSTANCE),
        durability=xdr.ContractDataDurability.PERSISTENT)
    r = _s.get_ledger_entries([k])
    if not r.entries:
        return None
    raw = xdr.utils.base64_to_bytes(r.entries[0].xdr) if hasattr(xdr, "utils") else __import__("base64").b64decode(r.entries[0].xdr)
    for h in known_hashes:
        if bytes.fromhex(h) in raw:
            return h
    return "unknown:" + raw.hex()

if __name__ == "__main__":
    print(json.dumps({"note": "import and call from other scripts"}, indent=1))
