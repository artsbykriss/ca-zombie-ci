import sys, json; sys.path.insert(0,'.')
from rpc import rpc, batch, enc_sel, dec
from decode import addr

AM = "0xa362d98b33a7bb5b5e2180a05f995a70fb404f30"
hooks = {"ramp":"0x08e52564bad99e05a694b4809f397edca417a080","rwa":"0x5eb87f69be00df39981622fd60a8de4b7837e080","rampeth":"0x594e8e6281edf2d363a0293a50004cf868e7a080"}
sel_getrole = enc_sel("getTargetFunctionRole(address,bytes4)")
sel_closed = enc_sel("isTargetClosed(address)")
sel_exp = enc_sel("expiration()")
sel_min = enc_sel("minSetback()")
sel_admin_role = enc_sel("ADMIN_ROLE()")
sel_pub_role = enc_sel("PUBLIC_ROLE()")
sel_hasrole = enc_sel("hasRole(uint64,address)")
sel_admindelay = enc_sel("getTargetAdminDelay(address)")
sel_roleadmin = enc_sel("getRoleAdmin(uint64)")
sel_roleguard = enc_sel("getRoleGuardian(uint64)")
sel_roledelay = enc_sel("getRoleGrantDelay(uint64)")

def enc_addr(a): return a.lower().replace("0x","").rjust(64,"0")
def enc_u64(n): return hex(n)[2:].rjust(64,"0")

fns = {
 "ramp": [("0x3f740010","pokeFee"),("0x5f4934a8","clearPoke"),("0x4dc4b5c9","setPoolConfig"),("0x05e517e7","setClaimFee"),("0x017a31b8","setClaimFeeBps"),("0xd0ba2baa","setDistributor"),("0x26f5ef52","setFFFeeSink"),("0x136439dd","pause"),("0x51789ea2","setPaused"),("0x016b937e","pausePool"),("0xb56cc687","setPoolPaused"),("0xae4a5785","setBallotGate"),("0x4cee6193","setPoolAsymmetry"),("0xab9e5bfd","sweepClaimFee"),("0xbdde80c6","sweepDistributor"),("0x36a9ca1a","deposit"),("0xa2ba1fc8","withdraw"),("0x4e8d0048","claimFees"),("0x6fa9f5ca","stake"),("0x7fa7b6ac","syncRanges")],
 "rwa": [("0x3f740010","pokeFee"),("0xe8fe08b8","setPoolConfig"),("0x4e8d0048","claimFees"),("0x36a9ca1a","deposit")],
 "rampeth": [("0x3f740010","pokeFee"),("0x4dc4b5c9","setPoolConfig"),("0x36a9ca1a","deposit"),("0xbdde80c6","sweepDistributor")],
}
calls, keys = [], []
for tag, fns_ in fns.items():
    h = hooks[tag]
    calls.append(("eth_call",[{"to":AM,"data":sel_closed+enc_addr(h)},"latest"])); keys.append(("closed",tag))
    for sel, name in fns_:
        calls.append(("eth_call",[{"to":AM,"data":sel_getrole+enc_addr(h)+sel[2:]},"latest"])); keys.append(("role:"+name,tag))
calls.append(("eth_call",[{"to":AM,"data":sel_exp},"latest"])); keys.append(("expiration","am"))
calls.append(("eth_call",[{"to":AM,"data":sel_min},"latest"])); keys.append(("minSetback","am"))
calls.append(("eth_call",[{"to":AM,"data":sel_admin_role},"latest"])); keys.append(("ADMIN_ROLE","am"))
calls.append(("eth_call",[{"to":AM,"data":sel_pub_role},"latest"])); keys.append(("PUBLIC_ROLE","am"))
res = batch(calls, chunk=8)
out = {}
for (tag,k), r in zip(keys, res):
    v = dec(r) if isinstance(r,str) and r.startswith("0x") and len(r)>2 else None
    if k=="am": out[tag] = v
    else:
        out.setdefault(k,{})[tag] = v
print(json.dumps(out, indent=1))
