import json, os, re, sys

SRCDIR="src"
OUT="extracted"
os.makedirs(OUT, exist_ok=True)

def extract(addr):
    p=os.path.join(SRCDIR, addr+".json")
    d=json.load(open(p))
    r=d.get("result")[0]
    name=r.get("ContractName")
    sc=r.get("SourceCode") or ""
    files={}
    if sc.startswith("{{"):
        # standard-json
        try:
            obj=json.loads(sc[1:-1])
            for fn, v in obj.get("sources",{}).items():
                files[fn]=v.get("content","")
        except Exception as e:
            print("  stdjson err", e)
    elif sc.startswith("{"):
        try:
            obj=json.loads(sc)
            for fn, v in obj.get("sources",{}).items():
                files[fn]=v.get("content","")
        except Exception as e:
            # maybe plain
            files[name+".sol"]=sc
    else:
        files[name+".sol"]=sc
    base=os.path.join(OUT, name)
    for fn, content in files.items():
        safe=fn.replace("../","_").lstrip("/")
        fp=os.path.join(base, safe)
        os.makedirs(os.path.dirname(fp), exist_ok=True)
        open(fp,"w").write(content)
    return name, len(files), list(files.keys())

addrs=[a for a in os.listdir(SRCDIR) if a.endswith(".json")]
for a in sorted(addrs):
    n,c,ks=extract(a[:-5])
    print(f"{a[:-5]}  {n}  files={c}")
    for k in ks[:60]:
        print("    ", k)
