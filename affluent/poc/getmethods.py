#!/usr/bin/env python3
"""Query Affluent get-methods via tonapi runGetMethod (anonymous). READ-ONLY."""
import json, urllib.request, urllib.error

API = "https://tonapi.io/v2/blockchain/accounts/%s/methods/%s"

TARGETS = {
    "BasicPool":        ("EQCrEHHG4Ff8TD3PzuH5tFSwHBD3zxeXaosz48jGLebwiiNx", "get_pool_data"),
    "AdvancedPool":     ("EQBCXQp2sSTJhvnV6DlBqhTsdNMZc_tJcXQJ5XjoWiy-OAge", "get_pool_data"),
    "LendingVaultPool": ("EQBQMDjWVLeX0vAUNDTRL-aA665EItLzSvONywKDHXJRCuxB", "get_pool_data"),
    "EthenaPool":       ("EQA9iTdgsPxvk08idCXQoefGqJGLTDQFy4W34AtEj7Z_25iT", "get_pool_data"),
    "LV_factorialUSDT": ("EQAGtgnr1G0XDilGURcOB3pUhl-Lo__J-TaJP0K4ey8cuSaW", "get_vault_data"),
    "LV_factorialTON":  ("EQADQ6JcK0NMuNM5uwCcS9bjcn2RTvcxYIZjNlhIhywUrfBN", "get_vault_data"),
    "LV_affluentUSDT":  ("EQAc65JgiTwcoC3M1VYnQcM2Ivq4DTWOtyY2k2EaBuXsKRAZ", "get_vault_data"),
    "MV2_ton1":         ("EQDtxQqkgIRQQR5hWlrQxiJMtLwjR3rEYNUBbEcvPDwCs1Ng", "get_vault_data"),
    "MV2_usdt1":        ("EQBzSItiC1vpDUEftDeWDyjgMutf6CIzme16gzn9iNlolpcY", "get_vault_data"),
    "MV2_sentoraWallet":("EQD5O4qzJmVwuKDIfDcuM6HI7fUf1AOolgF2oiPGyqr_WZsp", "get_vault_data"),
}

def call(addr, method, **params):
    url = API % (addr, method)
    if params:
        url += "?" + "&".join(f"{k}={v}" for k, v in params.items())
    req = urllib.request.Request(url, headers={"User-Agent": "research"})
    try:
        with urllib.request.urlopen(req, timeout=25) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        return {"error": f"HTTP {e.code}", "body": e.read()[:200].decode(errors='replace')}
    except Exception as e:
        return {"error": repr(e)}

def main():
    out = {}
    for name, (addr, method) in TARGETS.items():
        r = call(addr, method)
        out[name] = {"address": addr, "method": method, "result": r}
        print(f"=== {name} {method} ===")
        if "error" in r:
            print("  ", r["error"], r.get("body", ""))
        else:
            print("  ", json.dumps(r)[:1200])
        print()
    json.dump(out, open("/home/heisenberg/CA/affluent/analysis/getmethods.json", "w"), indent=1)

if __name__ == "__main__":
    main()
