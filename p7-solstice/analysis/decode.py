import json, base64, struct
ALPH="123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58(b):
    n=int.from_bytes(b,'big'); s=''
    while n: n,r=divmod(n,58); s=ALPH[r]+s
    for c in b:
        if c==0: s='1'+s
        else: break
    return s or '1'
def u64(b,o): return struct.unpack_from('<Q',b,o)[0]
def u128(b,o): return struct.unpack_from('<QQ',b,o)
data=json.load(open('analysis/program_accounts.json'))
D={k:None for k in ["Controller","CooldownEscrow","PermissionedAccount","VestingSchedule","YieldPool"]}
esc=[]
for k,pk,ln,h in data:
    d=bytes.fromhex(h)
    if k=="CooldownEscrow": esc.append((pk,d)); continue
    D[k]=(pk,d)
# Controller
pk,d=D["Controller"]
o=8
auth=b58(d[o:o+32]); o+=32
bump=d[o]; o+=1
share_mint=b58(d[o:o+32]); o+=32
share_dec=d[o]; o+=1
vest=u64(d,o); o+=8
cool=u64(d,o); o+=8
proposed=b58(d[o:o+32]); o+=32
hasprop=d[o]; o+=1
frozen=d[o]; o+=1
fastcut=u64(d,o); o+=8
fastper=u64(d,o); o+=8
ctrl=dict(pda=pk,authority=auth,bump=bump,share_mint=share_mint,share_mint_decimals=share_dec,
  vesting_period=vest,cooldown_period=cool,proposed_new_authority=proposed,has_proposed=hasprop,
  is_frozen=frozen,fast_cooldown_cutoff=fastcut,fast_cooldown_period=fastper)
# YieldPool
pk,d=D["YieldPool"]; o=8
bump=d[o]; o+=1
asset_mint=b58(d[o:o+32]); o+=32
asset_dec=d[o]; o+=1
asset_vault=b58(d[o:o+32]); o+=32
avb=d[o]; o+=1
ta=u128(d,o); o+=16
ss=u128(d,o); o+=16
pool=dict(pda=pk,bump=bump,asset_mint=asset_mint,asset_decimals=asset_dec,asset_vault=asset_vault,
  asset_vault_bump=avb,total_assets=ta[0]+(ta[1]<<64),shares_supply=ss[0]+(ss[1]<<64))
# VestingSchedule
pk,d=D["VestingSchedule"]; o=8
bump=d[o]; o+=1
va=u64(d,o); o+=8
st=u64(d,o); o+=8
en=u64(d,o); o+=8
vs=dict(pda=pk,bump=bump,vesting_amount=va,start_time=st,end_time=en)
# Permissioned
pk,d=D["PermissionedAccount"]; o=8
bump=d[o]; o+=1
csy=d[o]; o+=1
pa=dict(pda=pk,bump=bump,can_send_yield=csy)
out=dict(controller=ctrl,yield_pool=pool,vesting_schedule=vs,permissioned_account=pa)
json.dump(out,open('analysis/decoded_state.json','w'),indent=1)
print(json.dumps(out,indent=1))
print("num cooldown escrows:",len(esc))
# decode a few escrows
rows=[]
for pk,d in esc:
    o=8
    user=b58(d[o:o+32]); o+=32
    bump=d[o]; o+=1
    am=b58(d[o:o+32]); o+=32
    aa=u64(d,o); o+=8
    ce=u64(d,o); o+=8
    rows.append((pk,user,am,aa,ce))
rows.sort(key=lambda r:-r[3])
print("top escrows by asset_amount:")
for r in rows[:10]: print(r)
print("escrows with asset_amount>0:",sum(1 for r in rows if r[3]>0))
tot=sum(r[3] for r in rows)
print("total escrowed (6dp):",tot, tot/1e6)
