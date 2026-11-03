import sys
sys.path.insert(0,'/home/heisenberg/.local/lib/python3.10/site-packages')
from uplc.tools import unflatten
import uplc.ast as A

def short(v, lim=120):
    s=repr(v)
    return s if len(s)<=lim else s[:lim]+'…'

def to_str(t, depth=6):
    if depth<=0: return '…'
    if isinstance(t,A.Apply): return f'[{to_str(t.f,depth-1)} {to_str(t.x,depth-1)}]'
    if isinstance(t,A.Lambda): return f'(lam {t.var_name} {to_str(t.term,depth-1)})'
    if isinstance(t,A.Delay): return f'(delay {to_str(t.term,depth-1)})'
    if isinstance(t,A.Force): return f'(force {to_str(t.term,depth-1)})'
    if isinstance(t,A.BuiltIn): return f'(builtin {t.builtin.name}{"!"*t.applied_forces})'
    if isinstance(t,A.Error): return '(error)'
    if isinstance(t,A.Constr): return f'(constr {t.tag} ...)'
    if isinstance(t,A.Constant):
        v=t.value
        return f'(con {type(v).__name__} {short(v)})'
    return type(t).__name__

def spine_has(t,name):
    while isinstance(t,A.Apply): t=t.f
    return isinstance(t,A.BuiltIn) and t.builtin.name==name

def walk(t,parent=None,path=()):
    yield t,parent,path
    if isinstance(t,A.Apply):
        yield from walk(t.f,t,path+('f',)); yield from walk(t.x,t,path+('x',))
    elif isinstance(t,(A.Lambda,A.Delay,A.Force)):
        yield from walk(t.term,t,path+('term',))
    elif isinstance(t,A.Constr):
        for i,f in enumerate(t.fields): yield from walk(f,t,path+(f'field{i}',))
    elif isinstance(t,A.Case):
        yield from walk(t.scrutinee,t,path+('scrut',))
        for i,b in enumerate(t.branches): yield from walk(b,t,path+(f'branch{i}',))

if __name__=="__main__":
    h=sys.argv[1]; name=sys.argv[2] if len(sys.argv)>2 else "sha3_256"
    p=unflatten(bytes.fromhex(open(f"analysis/{h}.hex").read().strip()))
    for node,parent,path in walk(p.term):
    if isinstance(node,A.BuiltIn) and node.builtin.name==name:
        print('=== builtin',name,'at depth',len(path),'path',path)
        print('  node:',to_str(node,3),'forces',node.applied_forces,'bound',[to_str(b,4) for b in node.bound_arguments])
        print('  parent:',to_str(parent,8))
