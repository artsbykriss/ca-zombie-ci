#!/usr/bin/env python3
"""Build analysis/evidence.json: read-only view-call evidence for the ApeChain targets.

Keyless public RPC only. No transactions. Records the block for every read.
"""
import json, urllib.request

RPC = "https://rpc.apechain.com/http"
BLOCK = 53009900

APEPREDICTS = "0xF609394F0882B732b287db10d1b0F53211a09f75"
HOUSE_OLD = "0x2054709F89F18a4CCAC6132acE7b812E32608469"
CASHORCRASH = "0x8c63d2a77480178868A5fd80AF23821a91fD8517"
GOVMANAGER = "0x8632f22e5A921C751CFbBFF92F058A3b11E96b8a"
HOUSE_NEW = "0xB7EcD1F3fA462d2c6c65F55357E8c16c614CC2f1"
MIGRATOR = "0xaB9b74286CE69A8a3541a9f695CAA47021B769DC"
SAFE = "0xb5C3a66741E21CD80eBdDa25479B10A98Ea80c52"
APE_OWNER = "0xd5d013cef20373839635Fbce206A1cf0054EC565"
COC_OWNER = "0x1fFc20b99E1f4D0319c08d3bbb6B1ca92Db316f8"

SEL = {
    "owner()": "0x8da5cb5b",
    "paused()": "0x5c975abb",
    "house()": "0xff9b3acf",
    "migrator()": "0x7cd07e47",
    "totalShares()": "0x3a98ef39",
    "calculatePrice()": "0xd348b409",
    "gameCount()": "0x4d1975b4",
    "gameCounter()": "0x2e0be39a",
    "messagePrefix()": "0x91da2b3d",
    "getThreshold()": "0xe75235b8",
    "getOwners()": "0xa0e67e2b",
    "v1House()": "0x0ba985b4",
    "houseV2()": "0x5d86cecd",
}


def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, data=body,
                                headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=60))["result"]


def call(to, sig, block=BLOCK):
    try:
        return rpc("eth_call", [{"to": to, "data": SEL[sig]}, hex(block)])
    except Exception as e:  # noqa: BLE001
        return f"ERROR: {e}"


def addr(word):
    return "0x" + word[-40:]


def num(word):
    return int(word, 16)


def main():
    ev = {
        "block": BLOCK,
        "chain": "apechain",
        "chain_id": 33139,
        "rpc": "public keyless endpoint",
        "reads": {},
    }
    r = ev["reads"]

    r["APEPredicts.owner"] = addr(call(APEPREDICTS, "owner()"))
    r["APEPredicts.paused"] = bool(num(call(APEPREDICTS, "paused()")))
    r["APEPredicts.gameCount"] = num(call(APEPREDICTS, "gameCount()"))

    r["GovernanceManager.owner"] = addr(call(GOVMANAGER, "owner()"))
    r["GovernanceManager.house"] = addr(call(GOVMANAGER, "house()"))
    r["GovernanceManager.paused"] = bool(num(call(GOVMANAGER, "paused()")))

    r["HouseOld.migrator"] = addr(call(HOUSE_OLD, "migrator()"))
    r["HouseOld.totalShares"] = str(num(call(HOUSE_OLD, "totalShares()")))
    r["HouseOld.calculatePrice"] = str(num(call(HOUSE_OLD, "calculatePrice()")))
    r["HouseNew.migrator"] = addr(call(HOUSE_NEW, "migrator()"))
    r["HouseNew.totalShares"] = str(num(call(HOUSE_NEW, "totalShares()")))

    r["CashOrCrash.owner"] = addr(call(CASHORCRASH, "owner()"))
    r["CashOrCrash.gameCounter"] = num(call(CASHORCRASH, "gameCounter()"))

    r["Migrator.v1House"] = addr(call(MIGRATOR, "v1House()"))
    r["Migrator.houseV2"] = addr(call(MIGRATOR, "houseV2()"))

    # Safe owners
    raw = call(SAFE, "getThreshold()")
    r["Safe.threshold"] = num(raw) if raw.startswith("0x") else raw
    owners_raw = call(SAFE, "getOwners()")
    if isinstance(owners_raw, str) and owners_raw.startswith("0x"):
        h = owners_raw[2:]
        length = int(h[64:128], 16)
        owners = ["0x" + h[128 + i * 64 + 24:128 + (i + 1) * 64] for i in range(length)]
        r["Safe.owners"] = owners
    else:
        r["Safe.owners"] = owners_raw

    ev["notes"] = [
        "Every read is a read-only eth_call at block %d." % BLOCK,
        "No transaction was signed or broadcast.",
        "CashOrCrash.initialize() reverts InvalidInitialization for a non-deployer (already initialized); "
        "the immutable _initOwner guard (revert NotInitOwner) is the second layer.",
        "GovernanceManager.owner is a 2-of-4 Gnosis Safe (1.3.0); there is no voting contract.",
        "HouseOld.migrator != 0 -> deposit()/withdraw() revert 'Migration In Progress'; only migrate() works.",
    ]
    print(json.dumps(ev, indent=1))


if __name__ == "__main__":
    main()
