#!/usr/bin/env python3
"""Compute current claimable amounts for a set of UNCX vesting schedules.

Usage: python3 residual_calc.py <rpc_url> <vm_address> <ids_csv>
Calls: getVestingSchedule (public), _depositedShares (storage slot 12),
       _totalTokenShares (slot 11), shareRatio (slot 15), token balanceOf.
Vested amount: implemented per VestingCalculator (LINEAR/INTERVAL), capped by manager.
"""
import json, sys, urllib.request, time
from eth_utils import keccak
from eth_abi import decode as abi_decode

def rpc_batch(url, calls):
    payload = [{"jsonrpc":"2.0","id":i,"method":m,"params":p} for i,(m,p) in enumerate(calls)]
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
        headers={'Content-Type':'application/json','User-Agent':'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=90) as r:
        out = json.load(r)
    res=[None]*len(calls)
    for item in out: res[item['id']]=item.get('result')
    return res

def slot_map_u256(key_int, base_slot):
    key = hex(key_int)[2:].rjust(64,'0'); s = hex(base_slot)[2:].rjust(64,'0')
    return '0x'+keccak(bytes.fromhex(key+s)).hex()
def slot_map_addr(addr, base_slot):
    key = addr[2:].rjust(64,'0'); s = hex(base_slot)[2:].rjust(64,'0')
    return '0x'+keccak(bytes.fromhex(key+s)).hex()
def selector(sig): return '0x'+keccak(text=sig)[:4].hex()
def enc_u256(x): return hex(x)[2:].rjust(64,'0')
def enc_addr(a): return a[2:].rjust(64,'0')

def calc_vested(tranches, now):
    """tranches: list of (time, amount, eqType); per VestingCalculator."""
    if now <= tranches[0][0]: return 0
    if now >= tranches[-1][0]: return tranches[-1][1]
    i = 1
    while i < len(tranches) and now > tranches[i][0]: i += 1
    st, sa, _ = tranches[i-1]
    et, ea, _ = tranches[i]
    eq = tranches[i-1][2]
    if et == st: return ea
    if eq == 2:  # INTERVAL
        return ea
    # LINEAR (0) / others: linear interpolation
    elapsed = now - st; dur = et - st; diff = ea - sa
    progress = (elapsed * 10**18) // dur
    return sa + (diff * progress) // 10**18

def fetch_schedule(url, vm, i, attempts=6):
    """Fetch and decode one schedule, retrying on transient RPC corruption."""
    import time as _t
    for a in range(attempts):
        r2 = rpc_batch(url, [("eth_call",[{"to":vm,"data":selector("getVestingSchedule(uint256)")+enc_u256(i)},"latest"])])
        raw2 = r2[0]
        if raw2 and raw2 != '0x':
            try:
                res = abi_decode(
                    ["(address,address,address,uint256,uint256,bool,bool,bool,bool,uint8,(uint256,uint256,uint8)[])"],
                    bytes.fromhex(raw2[2:]))
                return res[0]
            except Exception:
                pass
        _t.sleep(0.5)
    raise RuntimeError(f"failed to fetch schedule {i} after {attempts} attempts")

def main():
    url, vm, ids = sys.argv[1], sys.argv[2], [int(x) for x in sys.argv[3].split(',')]
    now = int(time.time())
    # first fetch schedules
    calls = [("eth_call",[{"to":vm,"data":selector("getVestingSchedule(uint256)")+enc_u256(i)},"latest"]) for i in ids]
    calls += [("eth_getStorageAt",[vm, slot_map_u256(i,12), "latest"]) for i in ids]
    res = rpc_batch(url, calls)
    sch = {}
    tokens = set()
    for k,i in enumerate(ids):
        raw = res[k]; D = int(res[len(ids)+k],16)
        try:
            (t,c,b,T,R,soft,nft,top,canc,vt,tr), = abi_decode(
                ["(address,address,address,uint256,uint256,bool,bool,bool,bool,uint8,(uint256,uint256,uint8)[])"],
                bytes.fromhex(raw[2:]))
        except Exception as e:
            import sys as _s
            print(f"[debug] decode failed id={i} rawlen={len(raw) if raw else None} err={str(e)[:70]}", file=_s.stderr)
            # refetch individually with retries (transient RPC corruption observed)
            (t,c,b,T,R,soft,nft,top,canc,vt,tr) = fetch_schedule(url, vm, i)
        sch[i] = dict(token=t, creator=c, ben=b, T=T, R=R, soft=soft, topable=top,
                      cancelled=canc, D=D, tranches=[tuple(x) for x in tr])
        tokens.add(t)
    # pool state per token
    calls2 = []
    tl = sorted(tokens)
    for t in tl:
        calls2.append(("eth_getStorageAt",[vm, slot_map_addr(t,11), "latest"]))
        calls2.append(("eth_call",[{"to":t,"data":selector("balanceOf(address)")+enc_addr(vm)},"latest"]))
    res2 = rpc_batch(url, calls2)
    pools = {}
    for k,t in enumerate(tl):
        pools[t] = dict(S=int(res2[2*k],16), B=int(res2[2*k+1],16))
    out=[]
    for i in ids:
        s = sch[i]; p = pools[s['token']]
        V = calc_vested(s['tranches'], now)
        if s['cancelled']:
            claim_sh = max(0, s['D'] - s['R'])
            claimable_note = 'cancelled: D - released'
        else:
            vc = min(V, s['T'])
            vs = (s['D'] * vc) // s['T'] if s['T'] else 0
            if vs > s['D']: vs = s['D']
            claim_sh = max(0, vs - s['R'])
            claimable_note = 'active: D*V/T - released'
        amount = (claim_sh * p['B']) // p['S'] if p['S'] else 0
        out.append(dict(id=i, token=s['token'], creator=s['creator'], ben=s['ben'],
                        T=s['T'], released=s['R'], D=s['D'], cancelled=s['cancelled'],
                        soft=s['soft'], topable=s['topable'],
                        poolS=p['S'], poolB=p['B'],
                        claimableShares=claim_sh, claimableAmount=amount, note=claimable_note))
    print(json.dumps(out, indent=1))

if __name__ == '__main__':
    main()
