import json,sys
def decode(c):
    return {
      "LTV": c & 0xFFFF,
      "liqThreshold": (c>>16)&0xFFFF,
      "liqBonus": (c>>32)&0xFFFF,
      "decimals": (c>>48)&0xFF,
      "active": (c>>56)&1,
      "frozen": (c>>57)&1,
      "borrowingEnabled": (c>>58)&1,
      "stableBorrowEnabled": (c>>59)&1,
      "paused": (c>>60)&1,
      "borrowableInIsolation": (c>>61)&1,
      "siloedBorrowing": (c>>62)&1,
      "flashloanEnabled": (c>>63)&1,
    }
for line in sys.stdin:
    line=line.strip()
    if not line.startswith('{'): continue
    try: o=json.loads(line)
    except: continue
    cfg=decode(o['config'])
    print(f"{o['symbol']:26} aTok={o['aTokenSupply']:>22} varDebt={o['varDebtSupply']:>20} | LTV={cfg['LTV']:>5} liqThr={cfg['liqThreshold']:>5} active={cfg['active']} frozen={cfg['frozen']} borrowEn={cfg['borrowingEnabled']} paused={cfg['paused']} flash={cfg['flashloanEnabled']} dec={cfg['decimals']}")
