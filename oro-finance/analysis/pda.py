from solders.pubkey import Pubkey
def find(seeds, prog):
    p=Pubkey.find_program_address(seeds, Pubkey.from_string(prog))
    return str(p[0]), p[1]
if __name__=="__main__":
    CORE="iNtiXEFgDNrc6FUt4cFALDe3D8RF3sVnNuKSHwxZRop"
    for w in ["22PtRWdqEfo68WRtE11isZcxVVifYjTSVdsWoyYB8Tnk","vHQEnpqGme6CtQ1jGRRTpYbDaJ7h4uVExEQ6jfVdLyc"]:
        for pre in [b"whitelist", b"autorized"]:
            a,b=find([pre, Pubkey.from_string(w).__bytes__()], CORE)
            print(pre.decode(), w[:12], a, b)
    for s in [b"price",b"vault",b"vault_a",b"vault_b",b"state",b"config",b"admin",b"integrator"]:
        a,b=find([s],CORE); print(s.decode(), a, b)
