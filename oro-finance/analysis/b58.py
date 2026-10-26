A='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
def b58enc(b):
    n=int.from_bytes(b,'big'); s=''
    while n>0:
        n,r=divmod(n,58); s=A[r]+s
    pad=0
    for c in b:
        if c==0: pad+=1
        else: break
    return '1'*pad+(s or '')
def b58dec(s):
    n=0
    for c in s: n=n*58+A.index(c)
    b=n.to_bytes((n.bit_length()+7)//8,'big')
    pad=0
    for c in s:
        if c=='1': pad+=1
        else: break
    return b'\x00'*pad+b
