#!/usr/bin/env python3
"""Fetch recent/historical event pages for the trio (read-only, TronGrid v1)."""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tronlib as T

OUT = os.path.dirname(os.path.abspath(__file__))
C = {"CherryPool": "TQxzSmRaCf1qrWdP6sfCihmrdXLNs8r4RR",
     "PokerGame": "TAcszQSbMybSkhfy4nQrAptmACRTDcYUgn",
     "FireFull": "TFxznGmEVdp5XxnQnyGp2FhFfBkMAprveW"}
EV = {"CherryPool": ["OnDeposit", "OnWithdraw"],
      "PokerGame": ["WithDraw", "RoomToBet", "OwnershipTransferred"],
      "FireFull": ["JoinEvent", "WithdrawEvent", "SuperPlayerEvent"]}


def main():
    out = {}
    for name, addr in C.items():
        out[name] = {}
        for ev in EV[name]:
            rows, fp, pages = [], None, 0
            while pages < 5:
                j = T.events(addr, ev, limit=200, fingerprint=fp)
                data = j.get("data", [])
                rows.extend(data)
                fp = (j.get("meta") or {}).get("fingerprint")
                pages += 1
                if not fp or len(data) < 200:
                    break
                time.sleep(1.2)
            out[name][ev] = rows
            print(f"{name} {ev}: {len(rows)} events" + (f" fp={fp}" if fp else ""))
            if rows:
                print("  first:", json.dumps(rows[0])[:300])
                print("  last :", json.dumps(rows[-1])[:300])
    json.dump(out, open(f"{OUT}/events.json", "w"), indent=1)


if __name__ == "__main__":
    main()
