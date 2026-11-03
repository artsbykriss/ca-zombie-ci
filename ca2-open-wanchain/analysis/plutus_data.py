import cbor2
class Constr:
    def __init__(self,tag,fields): self.tag=tag; self.fields=fields

def enc_int(i):
    # Plutus Data integer encoding is canonical CBOR (bignum for >64-bit)
    return cbor2.dumps(i)

def enc_data(x):
    if isinstance(x,Constr):
        body=cbor2.dumps([enc_obj(f) for f in x.fields])  # this is wrong: need nested encoding
        return body
