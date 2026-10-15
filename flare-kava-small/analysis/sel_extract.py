import subprocess, re, json, sys
rpc=sys.argv[1]; addr=sys.argv[2]
code=subprocess.run(["cast","code",addr,"--rpc-url",rpc],capture_output=True,text=True).stdout.strip()
b=bytes.fromhex(code[2:])
sels=set()
i=0
while i < len(b)-5:
    if b[i]==0x63 and i+5<=len(b) and b[i+5] in (0x14,0x15):  # PUSH4 xxxx EQ/ISZERO?
        sels.add(b[i+1:i+5].hex())
    i+=1
print(len(sels))
out=[]
for s in sorted(sels):
    try:
        r=subprocess.run(["curl","-s",f"https://www.4byte.directory/api/v1/signatures/?hex_signature=0x{s}"],capture_output=True,text=True).stdout
        d=json.loads(r)
        names=[x['text_signature'] for x in d.get('results',[])]
    except Exception as e:
        names=[]
    out.append((s,names))
for s,names in out:
    print("0x"+s, names[:3])
