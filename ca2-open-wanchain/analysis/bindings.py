import sys
sys.path.insert(0,'/home/heisenberg/.local/lib/python3.10/site-packages')
from uplc.tools import unflatten
import uplc.ast as A
import json

def const(c):
    v=getattr(c,'value',None)
    if v is None: return type(c).__name__
    if isinstance(v,bytes): return '#'+v.hex()
    return repr(v)
def pp(t, d=0):
    if d>6: return '…'
    if isinstance(t,A.Apply):
        return f'[{pp(t.f,d+1)} {pp(t.x,d+1)}]'
    if isinstance(t,A.Lambda): return f'(lam {t.var_name} {pp(t.term,d+1)})'
    if isinstance(t,A.Delay): return f'(delay {pp(t.term,d+1)})'
    if isinstance(t,A.Force): return f'(force {pp(t.term,d+1)})'
    if isinstance(t,A.BuiltIn): return t.builtin.name
    if isinstance(t,A.Error): return '(error)'
    if isinstance(t,A.Constr): return f'(constr {t.tag})'
    if isinstance(t,A.Case): return f'(case {pp(t.scrutinee,d+1)} …)'
    if isinstance(t,A.Variable): return t.name
    if isinstance(t,A.Constant): return f'(con {const(t)})'
    return type(t).__name__

h=sys.argv[1]
p=unflatten(bytes.fromhex(open(f'analysis/{h}.hex').read().strip()))
# collect top-level spine
args=[]; cur=p.term
while isinstance(cur,A.Apply):
    args.append(cur.x); cur=cur.f
args.reverse()
names=[]; t=cur
while isinstance(t,A.Lambda):
    names.append(t.var_name); t=t.term
print('top lambdas',len(names),'args',len(args))
binding={}
for n,a in zip(names,args): binding[n]=a
for v in sys.argv[2:]:
    a=binding.get(v)
    print(v,'=',pp(a,0) if a is not None else '<none>')
