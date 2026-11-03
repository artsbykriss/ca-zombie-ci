import sys,re
src=open(sys.argv[1]).read().strip()
out=[];depth=0;i=0;n=len(src);line=''
def flush():
    global line
    if line.strip(): out.append('  '*depth+line.strip())
    line=''
while i<n:
    c=src[i]
    if c=='(':
        flush(); depth+=1; line='('; i+=1
    elif c==')':
        flush(); depth=max(0,depth-1); out.append('  '*depth+')'); i+=1
    elif c=='"':
        j=i+1
        while j<n:
            if src[j]=='\\': j+=2; continue
            if src[j]=='"': break
            j+=1
        line+=src[i:j+1]; i=j+1
    else:
        line+=c; i+=1
flush()
print('\n'.join(out))
