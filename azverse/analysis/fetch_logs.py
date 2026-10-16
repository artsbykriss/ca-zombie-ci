#!/usr/bin/env python3
"""Fetch all event logs for the AZverse AssetVault proxy via Etherscan V2 (key from env, never printed).
Writes analysis/logs_<topicname>.json  (keyless artifacts)."""
import json, os, sys, time, urllib.parse, urllib.request

KEY = os.environ.get("ETHERSCANV2_API_KEY")
if not KEY:
    sys.exit("ETHERSCANV2_API_KEY not set")
PROXY = "0x91ba525861c16aa8cd4d6974e4058cc846f42ebe"
FROM_BLOCK = 482030474
OUT = os.path.dirname(os.path.abspath(__file__))

TOPICS = {
    "RoleGranted": "0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d",
    "RoleRevoked": "0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b",
    "TokenAdded": "0xa818a22273fc309f0a3682b642c74c5b5c25c0615ff378d07767cd231e19fffc",
    "TokenUpdated": "0x5d4804fe0ec949f552f757bfb400c951422d44c10c004077ecd19a9d1f503562",
    "WithdrawalAdded": "0x731460a77cb4c10004423c5a964ac266e4d1a760b11735f42cecdd78af0b473f",
    "WithdrawExecuted": "0x88ecdd7bcb1da09d72f0e0bce9ce7f1574212c4a0593608898b310f0f22eed01",
    "ValidatorsAdded": "0x69ed361dd8367cb9f4ff4a266ac08a848390b6b32913193f8f1adca2ff9a08d2",
    "ValidatorsRemoved": "0xbdbed5a9cdc7d17d78d6b710bc2d9d41aae560182712accbccf2c53939306e9a",
    "Upgraded": "0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b",
    "PendingWithdrawalToggled": "0x80324f158b877f8ca8d4ccea6e64a8a30f30ef218cb6a46710f9eaa9b7bfb1a3",
    "RebalanceWithdrawExecuted": "0x85eb8e55bbdba6c1911faa926cd388278a3ebb287742b9cf5092b9cf6962f665",
    "ValidatorRequiredPowerUpdated": "0x9006ab03e305686c9ab21d2f41ffdf1e64cb5a327cc99d6871aba1900aea29f7",
}

def fetch(params):
    q = urllib.parse.urlencode(params)
    url = f"https://api.etherscan.io/v2/api?{q}&apikey={KEY}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 research"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)

def main():
    for name, topic in TOPICS.items():
        out = []
        start = FROM_BLOCK
        while True:
            p = {"chainid": "42161", "module": "logs", "action": "getLogs",
                 "address": PROXY, "fromBlock": start, "toBlock": "latest",
                 "topic0": topic, "page": 1, "offset": 1000}
            d = fetch(p)
            if d.get("status") != "1":
                if d.get("message") == "No records found":
                    break
                print(name, "ERR", d.get("message"), d.get("result"), file=sys.stderr)
                break
            res = d["result"]
            out.extend(res)
            if len(res) < 1000:
                break
            start = int(res[-1]["blockNumber"]) + 1
            time.sleep(0.3)
        fn = os.path.join(OUT, f"logs_{name}.json")
        json.dump(out, open(fn, "w"), indent=1)
        print(f"{name}: {len(out)} logs -> {fn}")

if __name__ == "__main__":
    main()
