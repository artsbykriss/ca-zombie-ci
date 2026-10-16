#!/usr/bin/env python3
"""Reconcile AZverse withdrawals: added vs executed; find live (unexecuted) ones. Keyless."""
import json, os
D = os.path.dirname(os.path.abspath(__file__))

def load(n): return json.load(open(os.path.join(D, f"logs_{n}.json")))
def bn(l):
    v = l["blockNumber"]
    return int(v, 16) if isinstance(v, str) and v.startswith("0x") else int(v)
def words(data):
    d = data[2:]
    return [d[i:i+64] for i in range(0, len(d), 64)]
def w_int(w): return int(w, 16)
def w_addr(w): return "0x" + w[24:]
def w_bool(w): return w_int(w) != 0

added = {}
for l in sorted(load("WithdrawalAdded"), key=bn):
    ws = words(l["data"])
    wid = w_int(ws[0]); token = w_addr(ws[1]); amount = w_int(ws[2]); fee = w_int(ws[3])
    receiver = w_addr(ws[4]); pending = w_bool(ws[5]); force = w_bool(ws[6]); nonce = w_int(ws[7])
    added[wid] = dict(wid=wid, token=token, amount=amount, fee=fee, receiver=receiver,
                      pending=pending, force=force, nonce=nonce,
                      block=bn(l), ts=int(l["timeStamp"], 16), tx=l["transactionHash"])

executed = {}
for l in sorted(load("WithdrawExecuted"), key=bn):
    ws = words(l["data"])
    wid = w_int(ws[0]); to = w_addr(ws[1]); token = w_addr(ws[2]); amount = w_int(ws[3])
    fee = w_int(ws[4]); pending = w_bool(ws[5]); flushed = w_bool(ws[6]); paused = w_bool(ws[7]); nonce = w_int(ws[8])
    executed.setdefault(wid, []).append(dict(block=bn(l), ts=int(l["timeStamp"], 16), to=to, token=token,
                                             amount=amount, fee=fee, pending=pending, flushed=flushed,
                                             paused=paused, nonce=nonce, tx=l["transactionHash"]))

print(f"added: {len(added)} unique ids | executed: {len(executed)} unique ids")
double = {k: v for k, v in executed.items() if len(v) > 1}
print("ids executed more than once:", list(double.keys()))

not_executed = {k: v for k, v in added.items() if k not in executed}
print(f"\n=== ADDED BUT NEVER EXECUTED: {len(not_executed)} ===")
for wid, a in sorted(not_executed.items()):
    print(f"id={wid} block={a['block']} ts={a['ts']} token={a['token']} amount={a['amount']} fee={a['fee']} receiver={a['receiver']} pending={a['pending']} force={a['force']} nonce={a['nonce']}")
json.dump({str(k): v for k, v in not_executed.items()}, open(os.path.join(D, "unexecuted_withdrawals.json"), "w"), indent=1)

pend = [a for a in added.values() if a["pending"]]
print(f"\npending-mode withdrawals ever added: {len(pend)}")
exp_pending = [a for a in pend if a["wid"] in executed]
print(f"pending withdrawals executed: {len(exp_pending)}")
# summary of executed amounts per token
from collections import defaultdict
agg = defaultdict(lambda: [0, 0])
for e in [e[0] for e in executed.values()]:
    agg[e["token"]][0] += 1; agg[e["token"]][1] += e["amount"]
print("\n=== executed totals per token ===")
for t, (n, amt) in sorted(agg.items()):
    print(f"{t}: {n} withdrawals, raw total {amt}")

json.dump({str(k): v for k, v in added.items()}, open(os.path.join(D, "all_withdrawals.json"), "w"), indent=1)
