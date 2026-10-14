#!/usr/bin/env python3
"""Read stable() + decimals + reserves for top Base pairs."""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpcb as B

PAIRS = [
    "0xC6AC0110084f6cA058bFaA741Aa68Be5189A8Ca4",
    "0xF94334e3dce3fd15762eD2F6658437082c3560d4",
    "0x454d03605929252F037E1702e13f70129D8F64B1",
    "0x10F4602f0A879f006e00be0E5f7706E00d576119",
    "0xcd90949084f62D445FbaA6a5297AF639a3E2152E",
    "0xc20C6a3E2a06dA41f68946dF705A77B76aBbc134",
    "0xc22eE0812500CffEd68819877edb9072296b9485",
    "0x78F71c9D9F286932ab2f1d8A4cAbFdb94bFe882b",
    "0x4320B004317Ec14D5A20AD1A759b45E37bA3DAdf",
    "0x5e5c584E601108e87c69b1e8f70a3a50e1059013",
    "0x3E52499B171E55B562cCD0be1909Bfe2ba74c7bb",
    "0x1f42bAb334990E72906F6f0Ab588355ec9F6b393",
    "0x527e97aB9C691643ef5d1d240eD61B783F37EFDE",
    "0x2bB463d8fa6C43B06dB83C21C3221B71DA6BC0D7",
    "0x40D2790C048C9D5e3ec36AF1aE48DA2c5370A678",
    "0xD3dEf587e7b973257781eDe9362100A3EF62d30b",
    "0x2A2A947f4547387c13f57A0Ac27Cce2865E1A45D",
    "0x5c90c6FBe268Ab1d909aEC4847Fd18DCE464DE84",
    "0x6646C70f3dE8887E7af66BE0708cEdDDbdB15dEF",
    "0xeF849707A01ffF93a7b4B398307b8CD839F6a57b",
    "0x39Cd508373B831D78B3f1256cdf84f1994cd00Dd",
    "0x919a606FA442203ABBBF2F2e83F5F9E38f2c0b9E",
    "0x8dA4e59AbB5AfBF59CD6cD01eC8647Dd7e72D78b",
    "0xB380FB7AAe228e754372049CF25c0a5cD89c15b5",
]
SEL_STABLE = "0x22be3de1"
SEL_DEC0 = "0x0dfe1681"
SEL_DEC1 = "0xd21220a7"

def main():
    print("pair | stable | t0 | t1 | r0 | r1 | b0 | b1")
    for p in PAIRS:
        try:
            r = B.batch("base", [
                ("eth_call", [{"to": p, "data": SEL_STABLE}, "latest"]),
                ("eth_call", [{"to": p, "data": SEL_DEC0}, "latest"]),
                ("eth_call", [{"to": p, "data": SEL_DEC1}, "latest"]),
                ("eth_call", [{"to": p, "data": "0x0902f1ac"}, "latest"]),
            ])
            stable = bool(B.dec_uint(B.words(r[0])[0])) if r[0] and r[0] != "0x" else None
            t0 = B.dec_addr(B.words(r[1])[0]) if r[1] and r[1] != "0x" else None
            t1 = B.dec_addr(B.words(r[2])[0]) if r[2] and r[2] != "0x" else None
            ws = B.words(r[3]) if r[3] and r[3] != "0x" else []
            r0 = B.dec_uint(ws[0]) if ws else None
            r1 = B.dec_uint(ws[1]) if len(ws) > 1 else None
            print(f"{p} | {stable} | {t0} | {t1} | {r0} | {r1}")
        except Exception as e:
            print(p, "ERR", str(e)[:80])

if __name__ == "__main__":
    main()
