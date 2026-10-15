"""Re-run only section 2 (staker-context simulations) and merge into probes.json."""
import json
import probes

r2, cur = probes.section2_staker_context()
d = json.load(open("probes.json"))
d["S2_staker_context"] = r2
d["cur"] = cur
json.dump(d, open("probes.json", "w"), indent=1, default=str)
print("S2 merged OK; cur =", cur)
print(json.dumps(r2, indent=1, default=str)[:6000])
