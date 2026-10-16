import sys, json; sys.path.insert(0,'.')
from rpc import rpc, batch, enc_sel, dec
from decode import addr, words

PM = "0x8366a39cc670b4001a1121b8f6a443a643e40951"
pools = json.load(open("registry_pools.json"))
hooks = sorted(set(p['hooks'].lower() for p in pools))

sel_liq = enc_sel("getLiquidity(bytes32)")
sel_bal6909 = enc_sel("balanceOf(address,uint256)")
sel_cfo = enc_sel("claimFeeOwed(address)")
sel_do = enc_sel("distributorOwed(address)")

def enc_addr(a): return a.lower().replace("0x","").rjust(64,"0")
def enc_uint(n): return hex(n)[2:].rjust(64,"0")
def curid(c): return int(c,16)  # currencyId = uint256(address)

calls, keys = [], []
for p in pools:
    pid = p['id']
    calls.append(("eth_call",[{"to":PM,"data":sel_liq+pid[2:]},"latest"])); keys.append(("liq",p['id']))
    for c in (p['currency0'], p['currency1']):
        if c.lower()=="0x0000000000000000000000000000000000000000": continue
        calls.append(("eth_call",[{"to":PM,"data":sel_bal6909+enc_addr(p['hooks'])+enc_uint(curid(c))},"latest"])); keys.append(("hclaim:"+c.lower(),p['id']))
        calls.append(("eth_call",[{"to":PM,"data":sel_bal6909+enc_addr(PM)+enc_uint(curid(c))},"latest"])); keys.append(("pmbal:"+c.lower(),p['id']))
for h in hooks:
    for c in set([p['currency0'].lower() for p in pools if p['hooks'].lower()==h] + [p['currency1'].lower() for p in pools if p['hooks'].lower()==h]):
        if c=="0x0000000000000000000000000000000000000000": continue
        calls.append(("eth_call",[{"to":h,"data":sel_cfo+enc_addr(c)},"latest"])); keys.append(("cfo:"+c,h))
        calls.append(("eth_call",[{"to":h,"data":sel_do+enc_addr(c)},"latest"])); keys.append(("do:"+c,h))

print("calls:", len(calls))
res = batch(calls, chunk=8)
out = {"pool_liq":{}, "hook_claims":{}, "pm_balance":{}, "claimFeeOwed":{}, "distributorOwed":{}, "native_balance":{}}
for (tag,k), r in zip(keys, res):
    v = dec(r) if isinstance(r,str) and r.startswith("0x") and len(r)>2 else 0
    if tag=="liq": out["pool_liq"][k]=v
    elif tag.startswith("hclaim:"): out["hook_claims"].setdefault(k,{})[tag[7:]]=v
    elif tag.startswith("pmbal:"): out["pm_balance"].setdefault(k,{})[tag[6:]]=v
    elif tag.startswith("cfo:"): out["claimFeeOwed"].setdefault(k,{})[tag[4:]]=v
    elif tag.startswith("do:"): out["distributorOwed"].setdefault(k,{})[tag[3:]]=v
for h in hooks:
    b = rpc("eth_getBalance",[h,"latest"])
    out["native_balance"][h] = dec(b)
json.dump(out, open("value_enum.json","w"), indent=1)
print("== pool liquidity (nonzero):")
for p in pools:
    if out["pool_liq"].get(p['id'],0): print(" ", p['id'][:18], p['hooks'][:10], p['currency0'][:10], p['currency1'][:10], out["pool_liq"][p['id']])
print("== hook ERC6909 claims (nonzero):")
for h,d in out["hook_claims"].items():
    for c,v in d.items():
        if v: print(" ", h, c, v)
print("== claimFeeOwed (nonzero):")
for h,d in out["claimFeeOwed"].items():
    for c,v in d.items():
        if v: print(" ", h, c, v)
print("== distributorOwed (nonzero):")
for h,d in out["distributorOwed"].items():
    for c,v in d.items():
        if v: print(" ", h, c, v)
print("== native balances:")
for h,v in out["native_balance"].items():
    if v: print(" ", h, v, "wei =", v/1e18, "ETH")
