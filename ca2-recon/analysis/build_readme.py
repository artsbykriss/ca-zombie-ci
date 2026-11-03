#!/usr/bin/env python3
import re, json
tpl=open("analysis/README.template.md").read()
c=json.load(open("analysis/counts.json"))
rows=json.load(open("analysis/candidates.json"))
vals={
 "N":c["enumerated"],
 "N_README":c["by_source"]["README"],
 "N_AGENT":c["by_source"]["AGENT"],
 "N_PRIOR":c["prior_covered_rows"],
 "N_PC":c["by_disposition"].get("PRIOR-COVERED",0),
 "N_PP":c["by_disposition"].get("PRIOR-PARTIAL",0),
 "N_LEAD":c["by_disposition"].get("AGENT-ONLY-LEAD",0),
 "N_NONPROTO":c["by_disposition"].get("NOT-A-PROTOCOL",0),
 "N_OPEN":c["by_disposition"].get("OPEN",0),
}
vals["N_NONOPEN"]=vals["N"]-vals["N_OPEN"]
vals["N_AGENT_TABLE"]=sum(1 for r in rows if r["source"]=="AGENT" and r["disposition"] not in ("OPEN","NOT-A-PROTOCOL"))
for k,v in vals.items():
    tpl=tpl.replace("{{"+k+"}}",str(v))
tables=open("analysis/tables.md").read()
def sect(name):
    m=re.search(r"<!-- "+name+r" -->\n(.*?)(?=\n\n<!-- |\Z)", tables, re.S)
    return m.group(1).strip() if m else "MISSING"
tpl=tpl.replace("{{OPEN_TABLE}}",sect("OPEN_TABLE"))
tpl=tpl.replace("{{README_TABLE}}",sect("README_TABLE"))
tpl=tpl.replace("{{AGENT_TABLE}}",sect("AGENT_TABLE"))
tpl=tpl.replace("{{NONPROTO_TABLE}}",sect("NONPROTO_TABLE"))
open("README.md","w").write(tpl)
print("wrote README.md", len(tpl))
