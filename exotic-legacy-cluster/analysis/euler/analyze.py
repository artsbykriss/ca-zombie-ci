import json, os, sys
from harness import *

ADMIN_SLOT = "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"
IMPL_SLOT = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"

def main():
    v = json.load(open(os.path.join(HERE, "vaults_priced.json")))
    # unique by chain
    bychain = {}
    for x in v:
        bychain.setdefault(x["chain"], []).append(x)
    out = {}
    for chain, xs in bychain.items():
        r = RPC(CHAINS[chain]["rpc"]); r.block = None
        blk = r.blocknum()
        oracles = sorted({x["oracle"] for x in xs if x.get("oracle") and x["oracle"] != "0x"+"0"*40})
        govs = sorted({x["governorAdmin"] for x in xs if x.get("governorAdmin")})
        codes = r.batch("eth_getCode", [[a, "latest"] for a in oracles + govs])
        n = len(oracles)
        oc = {a: codes[i] for i, a in enumerate(oracles)}
        gc = {a: codes[n+i] for i, a in enumerate(govs)}
        for a in list(oc):
            if oc[a] in (None, "0x"):
                try:
                    oc[a] = r.call("eth_getCode", [a, "latest"])
                except Exception:
                    pass
        for a in list(gc):
            if gc[a] in (None, "0x"):
                try:
                    gc[a] = r.call("eth_getCode", [a, "latest"])
                except Exception:
                    pass
        # proxy slots for oracles
        slots = r.batch("eth_getStorageAt", [[a, ADMIN_SLOT, "latest"] for a in oracles] +
                                               [[a, IMPL_SLOT, "latest"] for a in oracles])
        adm = {a: slots[i] for i, a in enumerate(oracles)}
        imp = {a: slots[n+i] for i, a in enumerate(oracles)}
        for x in xs:
            x["oracleCode"] = oc.get(x.get("oracle"))
            x["govCode"] = gc.get(x.get("governorAdmin"))
            x["oracleAdminSlot"] = adm.get(x.get("oracle"))
            x["oracleImplSlot"] = imp.get(x.get("oracle"))
            f = set(x["flags"])
            if x.get("oracle") and x["oracle"] != "0x"+"0"*40 and (oc.get(x["oracle"]) in (None, "0x")):
                f.add("oracle_no_code")
            if x.get("governorAdmin") and gc.get(x["governorAdmin"]) in (None, "0x"):
                f.add("gov_eoa")
            x["flags"] = sorted(f)
        out[chain] = blk
        print(f"[{chain}] blk {blk} oracles {len(oracles)} no_code {sum(1 for a in oracles if oc.get(a) in (None,'0x'))} gov_eoa {sum(1 for a in govs if gc.get(a) in (None,'0x'))}/{len(govs)}", flush=True)
    json.dump(v, open(os.path.join(HERE, "vaults_flags.json"), "w"))
    json.dump(out, open(os.path.join(HERE, "blocks_codes.json"), "w"))
    import collections
    c = collections.Counter()
    for x in v:
        for f in x["flags"]:
            c[f] += 1
    print(c)

if __name__ == "__main__":
    main()
