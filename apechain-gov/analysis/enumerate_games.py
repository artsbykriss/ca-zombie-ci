#!/usr/bin/env python3
"""Read-only enumeration of APEPredicts games on ApeChain (chain 33139).

Extracts, for every gameId in 1..gameCount, the head words that live at fixed
slots of the public `games(uint256)` getter return data:
  word10 = totalPoolA (wei)   word11 = totalPoolB (wei)
  word12 = resolved (bool)    word17 = status (1 pending 2 rejected 3 approved 4 cancelled)
No transaction is ever sent. Uses the keyless public RPC only.
"""
import json, urllib.request

RPC = "https://rpc.apechain.com/http"
TARGET = "0xF609394F0882B732b287db10d1b0F53211a09f75"
GAMES_SEL = "0x117a5b90"        # games(uint256)
GAMES_COUNT_SEL = "0x4d1975b4"  # gameCount()


def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(
        RPC, data=body,
        headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)["result"]


def main():
    count = int(rpc("eth_call", [{"to": TARGET, "data": GAMES_COUNT_SEL}, "latest"]), 16)
    games = []
    for i in range(1, count + 1):
        data = GAMES_SEL + hex(i)[2:].rjust(64, "0")
        raw = rpc("eth_call", [{"to": TARGET, "data": data}, "latest"])
        h = raw[2:]
        w = lambda n: h[n * 64:(n + 1) * 64]
        games.append({
            "id": i,
            "totalPoolA": int(w(10), 16),
            "totalPoolB": int(w(11), 16),
            "resolved": int(w(12), 16) == 1,
            "status": int(w(17), 16),
        })
    print(json.dumps({"gameCount": count, "games": games}, indent=1))


if __name__ == "__main__":
    main()
