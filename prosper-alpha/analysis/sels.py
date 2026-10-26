import subprocess,re,sys,json,urllib.request
R="https://rpc.pharos.xyz"
def code(a):
    return subprocess.check_output(["cast","code",a,"--rpc-url",R]).decode().strip()[2:]
def sels(a):
    c=code(a)
    out=set()
    for m in re.finditer(r'63([0-9a-f]{8})14',c):
        out.add(m.group(1))
    return sorted(out)
for name,a in [("market","0xb05749a8Cc5Dd1205Bc36326Cf94A2cA83f7D672"),
               ("tradeRouter","0x533e70b9d51c330bf4c037f6c55fa8dd822a6c64"),
               ("migrationEscrow","0xcc143ad74665cea035bce2ec17d74e5e9e301768"),
               ("ptokenClaim","0x8c23f2be8127c20ecbaf4806d99ea35c60b7e469"),
               ("buyback","0x150fB446BDda9d832208B00aBCE2D5Bd1d4E4E2a"),
               ("depositRouter","0xb3c011977c21d0f40e9884d250b638e4eed6ad91"),
               ("feeFallback","0x607b54ed30752ce173f65eff91e6549ffcf6930e"),
               ("accessController","0x9a4dbfa541c3f49e123e0c36c4c4125a3e9eb2c3")]:
    s=sels(a)
    print(name, len(s), s)
