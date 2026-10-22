import sys
from tonpy.types import LiteClient, Address, CellBuilder, VmDict
from tonpy.tvm import Emulator
from tonpy.autogen.block import Transaction
POOL="EQCrEHHG4Ff8TD3PzuH5tFSwHBD3zxeXaosz48jGLebwiiNx"
ATT="0:34461ba017e4799eeee0628521e505226ef405e087cabb765eb50a882e5550a2"
VAULT="0:06b609ebd46d170e294651170e077a54865f8ba3ffc9f936893f42b87b2f1cb9"
def coins(b,v):
    if v==0: b.store_uint(0,4); return
    nb=(v.bit_length()+7)//8; b.store_uint(nb,4); b.store_uint(v,nb*8)
def run(amount, sender):
    lc=LiteClient(mode="roundrobin",timeout=3,num_try=5)
    blk=lc.get_masterchain_info_ext().last; now=lc.get_time()
    st=lc.get_account_state(Address(POOL),blk); lt=st.last_trans_lt+1; ss=st.to_shard_state()
    _,cfgraw=lc.get_config_all(blk); new=VmDict(32)
    for k,cs in cfgraw.get_iter():
        if k!=43: new.set(k,cs)
    b=CellBuilder(); b.store_uint(0x7362d09c,32); b.store_uint(1700000000000,64); coins(b,amount); b.store_address(Address(sender)); b.store_bool(False)
    m=CellBuilder(); m.store_bool(False);m.store_bool(True);m.store_bool(True);m.store_bool(False)
    m.store_address(Address(ATT));m.store_address(Address(POOL));coins(m,1500000000);m.store_bool(False);coins(m,0);coins(m,0)
    m.store_uint(lt,64);m.store_uint(now,32);m.store_bool(False);m.store_bool(True);m.store_ref(b.end_cell())
    em=Emulator(new); em.set_ignore_chksig(True); em.emulate_transaction(ss,m.end_cell(),now,lt)
    tx=Transaction().cell_unpack(em.transaction.to_cell(), rec_unpack=True)
    print(f"--- amount={amount} sender={sender[:12]} outmsg_cnt={tx.outmsg_cnt}")
    ol=tx.r1.out_msgs
    try:
        node=ol
        i=0
        while node is not None and i<10:
            i+=1
            v=getattr(node,'value',None) or getattr(node,'cell',None) or node
            # node is OutListNode/OutList
            print("   node type", type(node), [a for a in dir(node) if not a.startswith('_') and a not in ('pack','unpack','cell_pack','cell_unpack','to_dict','dump','get_tag','get_tag_enum','get_tag_len','get_type_class','field_names','conditional_fields','name','negate_params','store_from')])
            node=getattr(node,'next',None)
            if node is None: break
    except Exception as e:
        print("  err", e)
for a,s in [(10**12,ATT),(0,ATT),(10**12,VAULT)]:
    run(a,s)
