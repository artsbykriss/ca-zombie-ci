import sys, json; sys.path.insert(0,'.')
from rpc import rpc, batch, enc_sel, dec
from decode import addr

hooks = ["0x08e52564bad99e05a694b4809f397edca417a080","0x5eb87f69be00df39981622fd60a8de4b7837e080","0x594e8e6281edf2d363a0293a50004cf868e7a080",
"0xca89f079af00f752bfd3c345358dc38d4d73e080","0x66622f77b797d506e5376f7798b67ab288966080","0xa0e8fbff13e24af2b5e61a72800e08a161bde080",
"0x79576fbad6e83915630bbb5d5658483f05532080","0x70a9a88402989226847ec122043ce5e7ff462080","0x67d86050d22d574df046f3d90f722045f714e080",
"0x06a889870c8f83640d6816319f72e2aa579b6080","0xb608a78761f179f7c56f15e7d13921b92f00a080","0xa4570c37590e45f0b06898123d4de16307a32080",
"0x8af95932ec4484fb10c641a4cbcf19a798cb2080"]
sels = {
 "poolManager": enc_sel("poolManager()"),
 "authority": enc_sel("authority()"),
 "distributor": enc_sel("distributor()"),
 "distributorFF": enc_sel("distributorFF()"),
 "ffFeeSink": enc_sel("ffFeeSink()"),
 "claimFeeRecipient": enc_sel("claimFeeRecipient()"),
 "ballotGate": enc_sel("ballotGate()"),
 "pausedUntil": enc_sel("pausedUntil()"),
 "ABSOLUTE_MAX_FEE": enc_sel("ABSOLUTE_MAX_FEE()"),
 "weth": enc_sel("weth()"),
}
calls = []
keys = []
for h in hooks:
    calls.append(("eth_getCode",[h,"latest"])); keys.append((h,"code"))
    for name, sel in sels.items():
        calls.append(("eth_call",[{"to": h, "data": sel},"latest"])); keys.append((h,name))
res = {}
for (h,name), r in zip(keys, batch(calls)):
    if name == "code":
        res.setdefault(h,{})["code_bytes"] = (len(r)-2)//2 if isinstance(r,str) and r.startswith("0x") else None
        continue
    if not isinstance(r,str) or r=="0x":
        res.setdefault(h,{})[name] = None; continue
    w = r[2:].rjust(64,'0')
    if name in ("pausedUntil","ABSOLUTE_MAX_FEE"): res.setdefault(h,{})[name] = dec(w)
    else: res.setdefault(h,{})[name] = addr(w)
json.dump(res, open("hook_state.json","w"), indent=1)
for h,d in res.items():
    print(h, d.get("code_bytes"), "pm=",d.get("poolManager"), "auth=",d.get("authority"), "dist=",d.get("distributor"), "ffsink=",d.get("ffFeeSink"), "cfr=",d.get("claimFeeRecipient"), "gate=",d.get("ballotGate"), "paused=",d.get("pausedUntil"), "maxfee=",d.get("ABSOLUTE_MAX_FEE"))
