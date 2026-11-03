#!/usr/bin/env python3
import json
rows=json.load(open("analysis/candidates.json"))
def table(rs):
    out=["| # | Candidate | Chain | Funds / at-risk (as reported) | CA2 rating | Disposition | Conf. | Basis |",
         "|---|---|---|---|---|---|---|---|"]
    for r in rs:
        out.append("| {id} | {name} | {chain} | {funds} | {ca2_rating} | **{disposition}** | {confidence} | {basis} |".format(**r))
    return "\n".join(out)
open_rows=[r for r in rows if r["disposition"]=="OPEN"]
readme=[r for r in rows if r["source"]=="README" and r["disposition"]!="OPEN"]
agent=[r for r in rows if r["source"]=="AGENT" and r["disposition"]!="OPEN" and r["disposition"]!="NOT-A-PROTOCOL"]
nonproto=[r for r in rows if r["disposition"]=="NOT-A-PROTOCOL"]
parts=[]
parts.append("<!-- OPEN_TABLE -->\n"+table(open_rows))
parts.append("<!-- README_TABLE -->\n"+table(readme))
parts.append("<!-- AGENT_TABLE -->\n"+table(agent))
parts.append("<!-- NONPROTO_TABLE -->\n"+table(nonproto))
open("analysis/tables.md","w").write("\n\n".join(parts))
print("open",len(open_rows),"readme",len(readme),"agent",len(agent),"nonproto",len(nonproto),"total",len(rows))
