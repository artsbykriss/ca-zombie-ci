#!/usr/bin/env python3
"""Run attacker-substitution sims for each example instruction in ix_groups_<K>.json."""
import json, sys
import sim_attacker as SA

def summ(sim):
    if not sim: return {"raw":"none"}
    if "result" not in sim: return {"rpc_error": sim.get("error")}
    v = sim.get("result",{}).get("value")
    if v is None: return {"null":True}
    return {"err": v.get("err"), "cu": v.get("unitsConsumed"), "logs_tail": (v.get("logs") or [])[-5:]}

def main():
    K = sys.argv[1]
    pid = {"O13":"3vyr9DRfMZb2KvUQdnps7YG3PY38XdguLBQaJ2DFkSxk",
           "O14":"WRAPdXmxrH37RKUbH1QMnYrKdNe8w4Kz44t1cXmYeum",
           "O15":"zod11Jzp72T6qBbGVJfR38y1pGY3dBK8nSuouD4mMkZ"}[K]
    groups = json.load(open(f"ix_groups_{K}.json"))
    out = {}
    for d, info in sorted(groups.items(), key=lambda x:-x[1]["count"]):
        sig = info["example"]
        try:
            r = SA.run(sig, only_program=pid)
        except Exception as e:
            out[d] = {"name":info["name"],"sig":sig,"error":str(e)}
            print(f"{info['name']:40s} ERR {e}"); continue
        rec = {"name":info["name"],"sig":sig,"disc":r.get("disc"),"dlen":r.get("dlen"),
               "naccts":r.get("n_accts"),"orig_signers":r.get("orig_signers"),
               "attacker_pubkey":r.get("attacker_pubkey"),
               "control":summ(r.get("control")),"attacker":summ(r.get("attacker"))}
        out[d] = rec
        print(f"{info['name']:40s} sig={sig[:20]} naccts={rec['naccts']}")
        print(f"    control : {json.dumps(rec['control'])[:220]}")
        print(f"    attacker: {json.dumps(rec['attacker'])[:220]}")
    json.dump(out, open(f"sim_results_{K}.json","w"), indent=1)

if __name__=="__main__": main()
