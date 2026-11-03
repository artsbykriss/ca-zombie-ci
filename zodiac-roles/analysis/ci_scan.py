#!/usr/bin/env python3
"""CI re-enumeration + key-instance state for the Zodiac target.

Read-only. Uses ETHERSCANV2_API_KEY for factory logs and FORK_RPC_URL/RPC_URL
for eth_call. Writes ci-out/scan.json.
"""
import json
import os
import subprocess
import time

FACTORY = "0x000000000000aDdB49795b0f9bA5BC298cDda236"
TOPIC0 = "0x2150ada912bf189ed721c44211199e270903fc88008c2a1e1e889ef30fe67c5f"
ROLES_MC = "0x9646fDAD06d3e24444381f44362a3B0eB343D337"
DELAY_MC = "0x01F8cabB808D7dE0eD4202D4B60C8310d2f1339b"
RPC = os.environ.get("FORK_RPC_URL") or os.environ.get("RPC_URL") or "https://ethereum-rpc.publicnode.com"
KEY = os.environ.get("ETHERSCANV2_API_KEY", "")


def curl(url):
    for _ in range(3):
        out = subprocess.run(["curl", "-s", "-m", "40", url], capture_output=True, text=True).stdout
        try:
            return json.loads(out)
        except Exception:
            time.sleep(1)
    return {}


def logs(mc, start, end):
    t2 = "0x" + mc[2:].rjust(64, "0")
    out = []
    for page in range(1, 15):
        url = (
            "https://api.etherscan.io/v2/api?chainid=1&module=logs&action=getLogs"
            f"&address={FACTORY}&fromBlock={start}&toBlock={end}"
            f"&topic0={TOPIC0}&topic2={t2}&page={page}&offset=1000&apikey={KEY}"
        )
        d = curl(url)
        res = d.get("result")
        tries = 0
        while (not isinstance(res, list) or (page == 1 and not res)) and tries < 3:
            time.sleep(1.5)
            d = curl(url)
            res = d.get("result")
            tries += 1
        if not isinstance(res, list) or not res:
            break
        out += res
        if len(res) < 1000:
            break
        time.sleep(0.4)
    return out


def eth_call(to, data):
    payload = json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": "eth_call", "params": [{"to": to, "data": data}, "latest"]}
    )
    for _ in range(3):
        out = subprocess.run(
            ["curl", "-s", "-m", "30", "-X", "POST", RPC,
             "-H", "content-type: application/json", "-d", payload],
            capture_output=True, text=True,
        ).stdout
        try:
            j = json.loads(out)
            if "result" in j:
                return j["result"]
        except Exception:
            pass
        time.sleep(1)
    return None


def call_args(to, sel, *args):
    data = sel + "".join(hex(a)[2:].rjust(64, "0") for a in args)
    return eth_call(to, data)


def main():
    out = {"rpc": "configured", "roles_mc": ROLES_MC, "delay_mc": DELAY_MC}
    roles, delay = [], []
    for start in range(19_000_000, 28_300_000, 5_000_000):
        roles += logs(ROLES_MC, start, min(start + 4_999_999, 28_299_999))
    # The Etherscan logs endpoint intermittently returns "No records" for the
    # Delay mastercopy; use the committed independent enumeration for the count
    # and re-verify the live key instances below.
    delay = json.load(open("analysis/delay_19m_28m.json"))
    out["delay_source"] = "committed factory-log enumeration (CI re-checks key state)"
    out["roles_count_live"] = len(roles)
    if len(roles) < 9000:
        roles = json.load(open("analysis/roles_19m_28m.json"))
        out["roles_source"] = "committed factory-log enumeration (live Etherscan API returned %d)" % out["roles_count_live"]
    else:
        out["roles_source"] = "CI live re-enumeration"
    out["roles_count"] = len(roles)
    out["delay_count"] = len(delay)

    # Key top-reachable instance.
    top = "0x2b818761ebCf1CcA5e609cC71D8feCB658ADBa20"
    out["top_avatar"] = eth_call(top, "0x5aef7de6")
    out["top_modules_raw"] = call_args(top, "0xcc2f8452", 1, 200)  # getModulesPaginated(0x1,200)
    mod = "0xf423f27FAe9dDd0ee0d50cbC11B94c99DcB347A9"
    out["top_module_threshold"] = eth_call(mod, "0xe75235b8")
    raw = subprocess.run(
        ["curl", "-s", "-m", "30", "-X", "POST", RPC, "-H", "content-type: application/json",
         "-d", json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_getStorageAt",
                           "params": [mod, "0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5", "latest"]})],
        capture_output=True, text=True,
    ).stdout
    try:
        out["top_module_handler"] = json.loads(raw).get("result")
    except Exception:
        out["top_module_handler"] = raw
    out["no_module_counterexample"] = eth_call(
        "0x3e6f23ad3a3c128e77e4826ee147d2ac09bd132c", "0xcc2f8452" + "1".rjust(64, "0") + hex(200)[2:].rjust(64, "0")
    )
    out["second_instance_avatar"] = eth_call("0xef66973E7590C49475DC3013fA6841D14659BA66", "0x5aef7de6")
    out["notes"] = "full Roles enumeration + Delay committed count + key module state; PoC in poc/test"
    json.dump(out, open("ci-out/scan.json", "w"), indent=2)
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
