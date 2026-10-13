#!/usr/bin/env python3
import json, urllib.request, time, sys
sels = sys.argv[1:]
out = {}
for s in sels:
    try:
        url = f"https://www.4byte.directory/api/v1/signatures/?hex_signature=0x{s}"
        req = urllib.request.Request(url, headers={"User-Agent":"Mozilla/5.0"})
        d = json.load(urllib.request.urlopen(req, timeout=20))
        names = sorted({r["text_signature"] for r in d.get("results", [])})
        out[s] = names[:5]
    except Exception as e:
        out[s] = [f"ERR {e}"]
    time.sleep(0.15)
for s, names in out.items():
    print(s, "=>", "; ".join(names))
json.dump(out, open("sel4byte.json","a"), indent=1)
