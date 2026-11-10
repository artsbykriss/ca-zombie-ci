#!/usr/bin/env python3
"""Read-only state collection at explicit blocks (archive RPC from env var ETH_ARCHIVE)."""
import json,os,sys,urllib.request

SEL={
 'totalAssets':'0x01e1d114','totalSupply':'0x18160ddd','getTotalCollateral':'0xd6eb5910',
 'strategyToDebtRatio':'0x22c74b11','lastStrategyBalance':'0x6231eaff','loanManager':'0xb3ccbcfe',
 'yieldStrategy':'0x13f14fee','asset':'0x38d52e0f','loanExists':'0xd3286d71',
 'getCurrentLTV':'0xe8621149','getCurrentDebt':'0xccee305e','getPositionValues':'0x36d2b5aa',
 'get_virtual_price':'0xbb7b8b80','balances':'0x4903b0d1','calc_withdraw_one_coin':'0xcc2b27d7',
 'price_oracle':'0x86fc88d3','balanceOf':'0x70a08231','depositCap':'0xdbd5edc7',
 'depositsPaused':'0x60da3e83','emergencyMode':'0x0905f560','targetLtv':'0xec921dc1',
 'maxSlippage':'0x8c04166f','rebalanceBountyRate':'0xb5acbd7f','getDebtBalance':'0x5ccbbdf1',
 'getCollateralBalance':'0x1529a639',
}
def enc_addr(a): return a.lower().replace('0x','').rjust(64,'0')
def enc_u(x): return hex(x)[2:].rjust(64,'0')
def call(to,data,block):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":to,"data":data},hex(block)]}).encode()
    req=urllib.request.Request(os.environ['ETH_ARCHIVE'],data=body,headers={"content-type":"application/json","user-agent":"Mozilla/5.0 research"})
    r=json.load(urllib.request.urlopen(req,timeout=40))
    return r.get('result'),r.get('error')

VAULTS={
 'wstETH':{'addr':'0x23f189de34eed95f6303cff1c77f7676f211dd2c','asset':'0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0'},
 'WBTC':{'addr':'0x18e2f4f2e6565187fce73ecc707579e5f7933f74','asset':'0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599'},
}
POOL='0x390f3595bca2df7d23783dfd126427cceb997bf4'
out={}
for blk in [26371405,26371412,26371413,26371414]:
    b={}
    for name,v in VAULTS.items():
        d={}
        for k in ['totalAssets','totalSupply','getTotalCollateral','strategyToDebtRatio','lastStrategyBalance','depositCap','targetLtv']:
            d[k]=call(v['addr'],SEL[k],blk)[0]
        d['loanManager']=call(v['addr'],SEL['loanManager'],blk)[0]
        d['yieldStrategy']=call(v['addr'],SEL['yieldStrategy'],blk)[0]
        d['assetBal']=call(v['asset'],SEL['balanceOf']+enc_addr(v['addr']),blk)[0]
        lm=d['loanManager']; ys=d['yieldStrategy']
        if lm and lm!='0x'+'0'*64:
            lm='0x'+lm[-40:]
            d['loanExists']=call(lm,SEL['loanExists'],blk)[0]
            d['getCurrentDebt']=call(lm,SEL['getCurrentDebt'],blk)[0]
            d['getPositionValues']=call(lm,SEL['getPositionValues'],blk)[0]
            d['lmAssetBal']=call(v['asset'],SEL['balanceOf']+enc_addr(lm),blk)[0]
        if ys and ys!='0x'+'0'*64:
            ys='0x'+ys[-40:]
            d['stratDebtVal']=call(ys,SEL['balanceOf'],blk)[0]
        b[name]=d
    p={}
    for k in ['get_virtual_price','totalSupply']:
        p[k]=call(POOL,SEL[k],blk)[0]
    for i in range(2):
        p[f'balances{i}']=call(POOL,SEL['balances']+enc_u(i),blk)[0]
    b['pool']=p
    out[blk]=b
json.dump(out,open('analysis/zenji_state.json','w'),indent=1)
def dec(h):
    if not h: return None
    return int(h,16)
for blk,b in out.items():
    print('block',blk)
    for n in ['wstETH','WBTC']:
        d=b[n]
        print(' ',n,'equity',dec(d['totalAssets']),'shares',dec(d['totalSupply']),
              'collat',dec(d['getTotalCollateral']),'loanExists',dec(d.get('loanExists','0x0')),
              'debt',dec(d.get('getCurrentDebt','0x0')),'stratVal',dec(d.get('stratDebtVal','0x0')),
              'assetBal',dec(d['assetBal']))
    print('  pool vp',dec(b['pool']['get_virtual_price']),'lpSupply',dec(b['pool']['totalSupply']),'b0',dec(b['pool']['balances0']),'b1',dec(b['pool']['balances1']))
