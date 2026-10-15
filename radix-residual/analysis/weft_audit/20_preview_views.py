#!/usr/bin/env python3
"""Preview helper: call view methods and read receipt.output programmatic_json."""
import json, sys, time
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import preview

MARKET = "component_rdx1cpy6putj5p7937clqgcgutza7k53zpha039n9u5hkk0ahh4stdmq4w"
POOL = "component_rdx1czmr02yl4da709ceftnm9dnmag7rthu0tu78wmtsn5us9j02d9d0xn"


def view_call(component, method, args_block="", extra=""):
    return f"""CALL_METHOD
    Address("{component}")
    "{method}"
{args_block}
;
{extra}
"""


def get_outputs(resp):
    rc = resp.get("receipt", {}) or {}
    outs = rc.get("output", []) or []
    vals = []
    for o in outs:
        pj = o.get("programmatic_json") if isinstance(o, dict) else None
        vals.append(pj)
    return rc.get("status"), rc.get("error_message"), vals


def preview_and_outs(manifest, label=""):
    resp = preview(manifest, nonce=1)
    st, err, outs = get_outputs(resp)
    return st, err, outs, resp


def get_cdp_batch(ids, nonce=1):
    idlist = ", ".join(f'NonFungibleLocalId("{i}")' for i in ids)
    m = f"""CALL_METHOD
    Address("{MARKET}")
    "get_cdp"
    Array<NonFungibleLocalId>({idlist})
;
"""
    return preview_and_outs(m)


def get_price(resource, res_addr=None):
    comp = MARKET if res_addr is None else res_addr
    m = f"""CALL_METHOD
    Address("{MARKET}")
    "get_price"
    Address("{resource}")
;
"""
    return preview_and_outs(m)


if __name__ == "__main__":
    # smoke tests
    ids = ["#1#", "#2#", "#50#"]
    st, err, outs, resp = get_cdp_batch(ids)
    print("get_cdp status:", st, "err:", err)
    if outs:
        print(json.dumps(outs, indent=1)[:3000])
    else:
        json.dump(resp, open("preview_getcdp_raw.json", "w"), indent=1)
        print("no outputs; raw saved")

    st2, err2, outs2, resp2 = get_price("resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd")
    print("get_price XRD status:", st2, "err:", err2)
    print(json.dumps(outs2, indent=1)[:1200] if outs2 else json.dumps(resp2.get("receipt", {}))[:600])
