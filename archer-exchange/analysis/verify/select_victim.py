#!/usr/bin/env python3
import json
books = json.load(open("maker_books.json"))
mkts = {m["market"]: m for m in json.load(open("markets.json"))}
print("total books", len(books), "total markets", len(mkts))
cands = []
for b in books:
    m = mkts.get(b["market"])
    if not m:
        continue
    if m["status"] != 0:
        continue
    if b["quote_free"] <= 0:
        continue
    cands.append((b, m))
print("active-market books with quote_free>0:", len(cands))
for b, m in sorted(cands, key=lambda x: -x[0]["quote_free"])[:15]:
    print("book", b["book"], "maker", b["maker"], "qf", b["quote_free"], "bf", b["base_free"],
          "| mkt", m["market"], "base", m["base_mint"], "quote", m["quote_mint"], "st", m["status"])
json.dump([{"book": b, "market": m} for b, m in cands], open("candidates.json", "w"), indent=2)
