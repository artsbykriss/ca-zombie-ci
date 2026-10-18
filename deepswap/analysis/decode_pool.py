#!/usr/bin/env python3
import json, base64, struct, urllib.request, time
j=json.load(open('/home/heisenberg/CA/deepswap/analysis/pools_rpc.json'))
acc=j['result'][0]; data=base64.b64decode(acc['account']['data'][0])
print('pubkey',acc['pubkey'],'len',len(data))
o=8
def pk():
    global o
    v=data[o:o+32]; o+=32; return v.hex()
f={}
for n in ['amm_config','pool_creator','token_0_vault','token_1_vault','lp_mint','token_0_mint','token_1_mint','token_0_program','token_1_program','observation_key']:
    f[n]=pk()
f['auth_bump']=data[o]; o+=1
f['status']=data[o]; o+=1
f['lp_mint_decimals']=data[o]; o+=1
f['mint_0_decimals']=data[o]; o+=1
f['mint_1_decimals']=data[o]; o+=1
for n in ['lp_supply','protocol_fees_token_0','protocol_fees_token_1','fund_fees_token_0','fund_fees_token_1','open_time','recent_epoch']:
    f[n]=struct.unpack_from('<Q',data,o)[0]; o+=8
f['creator_fee_on']=data[o]; o+=1
f['enable_creator_fee']=data[o]; o+=1
f['padding1']=data[o:o+6].hex(); o+=6
for n in ['creator_fees_token_0','creator_fees_token_1']:
    f[n]=struct.unpack_from('<Q',data,o)[0]; o+=8
f['fee_model']=data[o]; o+=1
f['reward_model']=data[o]; o+=1
f['padding2']=data[o:o+6].hex(); o+=6
f['reward_rate_snapshot']=struct.unpack_from('<Q',data,o)[0]; o+=8
print(json.dumps(f,indent=1))
json.dump({'pubkey':acc['pubkey'],'state':f},open('/home/heisenberg/CA/deepswap/analysis/pool_decoded.json','w'),indent=1)
# base58
import base58
for k in ['amm_config','pool_creator','token_0_vault','token_1_vault','lp_mint','token_0_mint','token_1_mint']:
    print(k, base58.b58encode(bytes.fromhex(f[k])).decode())
