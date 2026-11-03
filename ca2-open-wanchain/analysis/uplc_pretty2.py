import sys
sys.path.insert(0,'/home/heisenberg/.local/lib/python3.10/site-packages')
from uplc.tools import unflatten
import uplc.ast as A

def const(c):
    v=getattr(c,'value',None)
    if v is None: return type(c).__name__
    try:
        if isinstance(v,bytes): return '#'+(v.hex() if v else '')
        if isinstance(v,bool): return 'True' if v else 'False'
        if hasattr(v,'values'): return '['+', '.join(const_val(x) for x in v.values)+']'
    except Exception: pass
    s=repr(v)
    return s if len(s)<70 else s[:70]+'…'

def const_val(x):
    s=repr(x)
    return s if len(s)<40 else s[:40]+'…'

def pp(t, ind=0, prec=0):
    pad='  '*ind
    if isinstance(t,A.Apply):
        # let-style
        if isinstance(t.f,A.Lambda) and isinstance(t.f.term,A.Apply) or (isinstance(t.f,A.Lambda)):
            lam=t.f; name=lam.var_name
            body=pp(lam.term, ind+1)
            val=pp(t.x, ind+1)
            return f'(let {name} =\n{val}\n{pad}in\n{body})'
        # flatten application spine
        spine=[]; cur=t
        while isinstance(cur,A.Apply):
            spine.append(cur.x); cur=cur.f
        spine.reverse()
        parts=[pp(cur,ind+1)]+[pp(a,ind+1) for a in spine]
        return '['+' '.join(parts)+']'
    if isinstance(t,A.Lambda):
        return f'(lam {t.var_name}\n{pp(t.term,ind+1)})'
    if isinstance(t,A.Delay): return f'(delay {pp(t.term,ind)})'
    if isinstance(t,A.Force): return f'(force {pp(t.term,ind)})'
    if isinstance(t,A.BuiltIn): return t.builtin.name
    if isinstance(t,A.Error): return '(error)'
    if isinstance(t,A.Constr): return f'(constr {t.tag} '+' '.join(pp(f,ind) for f in t.fields)+')'
    if isinstance(t,A.Case):
        return f'(case {pp(t.scrutinee,ind)} '+' '.join(pp(b,ind) for b in t.branches)+')'
    if isinstance(t,A.Constant): return f'(con {const(t)})'
    if isinstance(t,A.Variable): return t.name
    return type(t).__name__

h=sys.argv[1]
p=unflatten(bytes.fromhex(open(f'analysis/{h}.hex').read().strip()))
sys.setrecursionlimit(20000)
print(pp(p.term))
