import sys, json; sys.path.insert(0,'.')
from rpc import rpc, batch, enc_sel, dec, keccak
from decode import addr
PM = "0x8366a39cc670b4001a1121b8f6a443a643e40951"
POOLS_SLOT = (6).to_bytes(32,'big')
LIQ_OFFSET = 3

def pool_state_slot(pid_hex):
    pid = bytes.fromhex(pid_hex[2:])
    return keccak(pid + POOLS_SLOT)

def slot_add(slot: bytes, n: int) -> bytes:
    return (int.from_bytes(slot,'big') + n).to_bytes(32,'big')

sel_extsload = enc_sel("extsload(bytes32)")
pools = json.load(open("registry_pools.json"))
calls, keys = [], []
for p in pools:
    st = pool_state_slot(p['id'])
    calls.append(("eth_call",[{"to":PM,"data":sel_extsload+st.hex()},"latest"])); keys.append(("slot0",p['id']))
    calls.append(("eth_call",[{"to":PM,"data":sel_extsload+slot_add(st,LIQ_OFFSET).hex()},"latest"])); keys.append(("liq",p['id']))
res = batch(calls, chunk=8)
out = {}
for (tag,pid), r in zip(keys, res):
    v = dec(r) if isinstance(r,str) and len(r)>2 else 0
    out.setdefault(pid,{})[tag]=v
json.dump(out, open("pool_liquidity.json","w"), indent=1)
nz = [(p['id'], p['hooks'], out[p['id']]['liq']) for p in pools if out[p['id']]['liq']]
print("pools with nonzero liquidity:", len(nz), "of", len(pools))
for pid, h, l in nz:
    print(" ", pid[:20], h[:12], f"L={l/1e18:.4f}e18")
