#!/usr/bin/env python3
"""Preview: liquidate_nft on #523 (XRD debt, CaviarNine LSU claim NFT)."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import preview

MARKET = "component_rdx1cpy6putj5p7937clqgcgutza7k53zpha039n9u5hkk0ahh4stdmq4w"
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"
NFT = "resource_rdx1nfesadfsnamled8dqz6wvntez29gj7x474a8scluvch6sqjs3msx9y"
NFTID = "{760d380e7a76cc91-73f44d6cbd50ca40-63a7ecbda2070f30-87b3012b13f4b672}"
ACCT = "account_rdx16ydf4jd8rljv4h238nfjr4uadq84jzclr6sfl7j3jpd02r7gsxydkk"

CDP = sys.argv[1] if len(sys.argv) > 1 else "#523#"
PAY = sys.argv[2] if len(sys.argv) > 2 else "2944.373"   # full or half?
COMP = sys.argv[3] if len(sys.argv) > 3 else "0"
NFT_ARG = sys.argv[4] if len(sys.argv) > 4 else NFT
NFT_ID_ARG = sys.argv[5] if len(sys.argv) > 5 else NFTID

manifest = f"""
CALL_METHOD
    Address("{ACCT}")
    "withdraw"
    Address("{XRD}")
    Decimal("{float(PAY)+float(COMP)+1}")
;
TAKE_FROM_WORKTOP
    Address("{XRD}")
    Decimal("{PAY}")
    Bucket("pay")
;
TAKE_FROM_WORKTOP
    Address("{XRD}")
    Decimal("{COMP}")
    Bucket("comp")
;
CALL_METHOD
    Address("{MARKET}")
    "liquidate_nft"
    NonFungibleLocalId("{CDP}")
    Array<Bucket>(Bucket("pay"))
    Address("{NFT_ARG}")
    NonFungibleLocalId("{NFT_ID_ARG}")
    Bucket("comp")
;
CALL_METHOD
    Address("{ACCT}")
    "deposit_batch"
    Expression("ENTIRE_WORKTOP")
;
"""
resp = preview(manifest, nonce=1200)
rc = resp.get("receipt", {})
print("status:", rc.get("status"))
if rc.get("status") != "Succeeded":
    print("ERR:", str(rc.get("error_message"))[-700:])
    json.dump(resp, open("preview_liqnft_failed.json", "w"), indent=1)
else:
    json.dump(resp, open("preview_liqnft.json", "w"), indent=1)
    print("cost units:", rc.get("fee_summary", {}).get("execution_cost_units_consumed"))
    for e in rc.get("events", []):
        tid = e.get("type", {}).get("type_reference", {})
        print("-", tid.get("entity_address", "")[-14:], json.dumps(e.get("data", {}).get("programmatic_json"))[:260])
