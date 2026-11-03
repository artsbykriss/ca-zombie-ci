import sys
sys.path.insert(0,'/home/heisenberg/.local/lib/python3.10/site-packages')
from uplc.tools import unflatten
import uplc.ast as A

def subst(t, name, val, depth=0):
    if depth>400: return t
    if isinstance(t,A.Variable):
        return val if t.name==name else t
    if isinstance(t,A.Apply): return A.Apply(subst(t.f,name,val,depth+1), subst(t.x,name,val,depth+1))
    if isinstance(t,A.Lambda):
        if t.var_name==name: return t
        return A.Lambda(t.var_name, subst(t.term,name,val,depth+1))
    if isinstance(t,A.Delay): return A.Delay(subst(t.term,name,val,depth+1))
    if isinstance(t,A.Force): return A.Force(subst(t.term,name,val,depth+1))
    if isinstance(t,A.Constr): return A.Constr(t.tag,[subst(f,name,val,depth+1) for f in t.fields])
    if isinstance(t,A.Case): return A.Case(subst(t.scrutinee,name,val,depth+1),[subst(b,name,val,depth+1) for b in t.branches])
    return t

def inline(t, budget=[2000]):
    if budget[0]<=0: return t
    if isinstance(t,A.Apply) and isinstance(t.f,A.Lambda):
        v=t.f.var_name; body=t.f.term; arg=t.x
        budget[0]-=1
        return inline(subst(body,v,arg), budget)
    if isinstance(t,A.Apply): return A.Apply(inline(t.f,budget), inline(t.x,budget))
    if isinstance(t,A.Lambda): return A.Lambda(t.var_name, inline(t.term,budget))
    if isinstance(t,A.Delay): return A.Delay(inline(t.term,budget))
    if isinstance(t,A.Force): return A.Force(inline(t.term,budget))
    if isinstance(t,A.Constr): return A.Constr(t.tag,[inline(f,budget) for f in t.fields])
    if isinstance(t,A.Case): return A.Case(inline(t.scrutinee,budget),[inline(b,budget) for b in t.branches])
    return t

def pp(t, ind=0):
    pad='  '*ind; sp=' '*(ind*2)
    if isinstance(t,A.Apply):
        if isinstance(t.f,A.Lambda):
            return f'(let {t.f.var_name} = {pp(t.f.term,ind+1)}\n{sp}in {pp(t.x,ind+1)})'
        return f'[{pp(t.f,ind)} {pp(t.x,ind)}]'
    if isinstance(t,A.Lambda): return f'(lam {t.var_name} {pp(t.term,ind)})'
    if isinstance(t,A.Delay): return f'(delay {pp(t.term,ind)})'
    if isinstance(t,A.Force): return f'(force {pp(t.term,ind)})'
    if isinstance(t,A.BuiltIn): return t.builtin.name
    if isinstance(t,A.Error): return '(error)'
    if isinstance(t,A.Constr): return f'(constr {t.tag} '+' '.join(pp(f,ind) for f in t.fields)+')'
    if isinstance(t,A.Case): return f'(case {pp(t.scrutinee,ind)} '+' '.join(pp(b,ind) for b in t.branches)+')'
    if isinstance(t,A.Variable): return t.name
    if isinstance(t,A.Constant):
        v=getattr(t,'value',None)
        if isinstance(v,bytes): return f'#{v.hex()}'
        return repr(v)
    return type(t).__name__

h=sys.argv[1]
p=unflatten(bytes.fromhex(open(f'analysis/{h}.hex').read().strip()))
sys.setrecursionlimit(30000)
t=inline(p.term)
# find sha3 arg
def walk(t,parent=None):
    yield t,parent
    for nm in ('f','x','term'):
        v=getattr(t,nm,None)
        if v is not None and hasattr(v,'__class__') and v.__class__.__module__.startswith('uplc'):
            yield from walk(v,t)
    if isinstance(t,(A.Constr,A.Case)):
        for f in getattr(t,'fields',[]) or []: yield from walk(f,t)
        for b in getattr(t,'branches',[]) or []: yield from walk(b,t)
for node,parent in walk(t):
    if isinstance(node,A.BuiltIn) and node.builtin.name==sys.argv[2]:
        print('SHA3 ARG:', pp(parent,0)[:6000])
        break
