import rpc,json,sys
def walk(c,depth=0,out=None):
    if out is None: out=[]
    inp=c.get('input','')
    sel=inp[:10] if len(inp)>=10 else ''
    out.append(f"{'  '*depth}{c.get('type','')} {c.get('from','')[:10]}->{c.get('to','')[:10]} sel={sel} gas={int(c.get('gasUsed','0x0'),16)} val={int(c.get('value','0x0'),16)} out={c.get('output','')[:18]}")
    for x in c.get('calls',[]): walk(x,depth+1,out)
    return out
h=sys.argv[1]
t=rpc.rpc('monad','eth_getTransactionByHash',[h])
print('TX to',t['to'],'from',t['from'],'sel',t['input'][:10],'val',int(t['value'],16))
tr=rpc.rpc('monad','debug_traceTransaction',[h,{'tracer':'callTracer'}])
print('\n'.join(walk(tr)))
