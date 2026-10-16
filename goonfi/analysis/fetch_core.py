#!/usr/bin/env python3
"""Fetch GoonFi core accounts + upgrade history (read-only). Saves raw JSON/bin to analysis/."""
import json, os, sys, base64
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

OUT = os.path.dirname(os.path.abspath(__file__))

PROG = "goonuddtQRrWqqn5nFyczVKaie28f3kDkHWkHtURSLE"
PROGDATA = "124gUYwjVnJQ4sJsFug9gHPzPLEtwCbAQC5LkbaDgx9s"
PROG_V1 = "goonERTdGsjnkZqWuVjs73BZ3Pb9qoCUdBUL17BnS5j"
POOL = "2U5S52n2L9Rr8vjDiEFRmHo5iQjJQg9zAgJ5nY1aWXK1"
VAULT_WSOL = "8ncU5YW1CQwvr4gs7buH57bW58e86TDau4STrCJBuz8z"
AUTH = "GMCJvYGf5Ex2ARiMquaBDqU6iKM8uiEQkB8jCnoNfHpC"
INCIDENT_A8 = "7yecFG22heommABQ5svcbQLK1Ua4ZrJsHPiktZ17jfm3"
INCIDENT_A9 = "BNrK9LpEn65QA4TyBLVSMdngW3XHj3xLfFPwGdCBv8wV"


def acct(addr):
    return rpc("getAccountInfo", [addr, {"encoding": "base64"}])


def save(name, obj):
    with open(os.path.join(OUT, name), "w") as f:
        json.dump(obj, f, indent=1)


def main():
    out = {}
    for label, addr in [("prog_v2", PROG), ("progdata_v2", PROGDATA), ("prog_v1", PROG_V1),
                        ("pool", POOL), ("vault_wsol", VAULT_WSOL), ("auth", AUTH),
                        ("incident_a8", INCIDENT_A8), ("incident_a9", INCIDENT_A9)]:
        r = acct(addr)
        v = r.get("result", {}).get("value")
        out[label] = {"addr": addr, "exists": v is not None,
                      "owner": v.get("owner") if v else None,
                      "lamports": v.get("lamports") if v else None,
                      "executable": v.get("executable") if v else None,
                      "space": v.get("space") if v else None,
                      "data_len": len(v["data"][0]) if v and v.get("data") else None}
        print(label, addr, "exists=", v is not None, "owner=", v.get("owner") if v else None,
              "lamports=", v.get("lamports") if v else None, "space=", v.get("space") if v else None)
        if v and v.get("data"):
            raw = base64.b64decode(v["data"][0])
            with open(os.path.join(OUT, f"{label}-account.bin"), "wb") as f:
                f.write(raw)
            save(f"{label}-account.json", r)
    save("core-accounts-summary.json", out)


if __name__ == "__main__":
    main()
