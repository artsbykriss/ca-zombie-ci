import sys
sys.path.insert(0,'/home/heisenberg/.local/lib/python3.10/site-packages')
from uplc.tools import unflatten
import uplc.ast as A

def to_str(t, depth=6):
    if depth<=0: return '…'
    if isinstance(t,A.Apply): return f'[{to_str(t.f,depth-1)} {to_str(t.x,depth-1)}]'
    if isinstance(t,A.Lambda): return f'(lam {t.var_name} {to_str(t.term,depth-1)})'
    if isinstance(t,A.Delay): return f'(delay {to_str(t.term,depth-1)})'
    if isinstance(t,A.Force): return f'(force {to_str(t.term,depth-1)})'
    if isinstance(t,A.BuiltIn): return f'(builtin {t.builtin.name})'
    if isinstance(t,A.Error): return '(error)'
    if isinstance(t,A.Constr): return f'(constr {t.tag} ...)'
    if isinstance(t,A.Constant):
        v=t.value; s=repr(v); return f'(con {s if len(s)<80 else s[:80]+"…"})'
    if isinstance(t,A.Variable): return t.name
    return type(t).__name__

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

def getvar(t,name):
    try: return getattr(t,name)
    except Exception: return None

if __name__=='__main__':
    h=sys.argv[1]; name=sys.argv[2]; depth=int(sys.argv[3]) if len(sys.argv)>3 else 12
    p=unflatten(bytes.fromhex(open(f'analysis/{h}.hex').read().strip()))
    for node,parent,path in walk(p.term):
        if isinstance(node,A.BuiltIn) and node.builtin.name==name:
            print('=== ',name,'depth',len(path))
            print('PARENT:',to_str(parent,depth))
            t=parent
            while isinstance(t,A.Apply):
                print('  fn:',to_str(t.f,4),'  ARG:',to_str(t.x,depth))
                t=t.x
            break
