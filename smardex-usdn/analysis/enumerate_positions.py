#!/usr/bin/env python3
"""
Enumerate live long positions of the SMARDEX USDN protocol (Ethereum mainnet).
READ-ONLY. Uses a keyless public RPC. Reads storage directly from the ERC1967 proxy.

Storage layout derived from the deployed (Etherscan-verified) UsdnProtocolTypes.Storage
struct, main storage base = 0xd143a936a6a372725e12535db83a2cfabcb3715dfd88bc350da3399604dc9700
"""
import json, sys
from web3 import Web3
from eth_abi import encode

RPC = "https://ethereum-rpc.publicnode.com"
PROXY = Web3.to_checksum_address("0x656cB8C6d154Aad29d8771384089be5B5141f01a")
S = int("d143a936a6a372725e12535db83a2cfabcb3715dfd88bc350da3399604dc9700", 16)

SLOT_TICKVERSION   = S + 38
SLOT_LONGPOSITIONS = S + 39
SLOT_TICKDATA      = S + 40
SLOT_HIGHEST       = S + 41
SLOT_TOTALPOS      = S + 42
SLOT_BITMAP        = S + 43
SLOT_LASTPRICE     = S + 26
SLOT_TOTALEXPO     = S + 35

MIN_TICK = -322378
TICK_SPACING = 100

w3 = Web3(Web3.HTTPProvider(RPC, request_kwargs={"timeout": 30}))

def sread(slot):
    return int.from_bytes(w3.eth.get_storage_at(PROXY, slot), "big")

def keccak(data: bytes) -> bytes:
    return Web3.keccak(data)

def mapping_slot(key_int_or_bytes, base):
    if isinstance(key_int_or_bytes, int):
        # sign-extend / left pad to 32 bytes
        k = (key_int_or_bytes & (2**256 - 1)).to_bytes(32, "big")
    elif isinstance(key_int_or_bytes, bytes):
        k = key_int_or_bytes.rjust(32, b"\x00") if len(key_int_or_bytes) <= 32 else key_int_or_bytes
    else:
        raise TypeError
    return int.from_bytes(keccak(k + base.to_bytes(32, "big")), "big")

def tick_to_index(tick):
    return (tick - MIN_TICK) // TICK_SPACING

def index_to_tick(index):
    # Solidity truncates toward zero: MIN_TICK/TICK_SPACING == -3223 (NOT floor -3224)
    return (index + int(MIN_TICK / TICK_SPACING)) * TICK_SPACING

def read_position_slot(base_elem_slot):
    a = sread(base_elem_slot)          # validated|timestamp|user
    b = sread(base_elem_slot + 1)      # totalExpo | amount
    validated = bool(a & 0xFF)
    timestamp = (a >> 8) & ((1 << 40) - 1)
    user = Web3.to_checksum_address(((a >> 48) & ((1 << 160) - 1)).to_bytes(20, "big"))
    totalExpo = b & ((1 << 128) - 1)
    amount = (b >> 128) & ((1 << 128) - 1)
    return dict(validated=validated, timestamp=timestamp, user=user,
                totalExpo=totalExpo, amount=amount)

def main():
    latest = w3.eth.block_number
    highest = sread(SLOT_HIGHEST)
    totalpos = sread(SLOT_TOTALPOS)
    lastprice = sread(SLOT_LASTPRICE) & ((1 << 128) - 1)
    totalexpo = sread(SLOT_TOTALEXPO)
    # signed highest
    if highest >= 2**23:
        highest -= 2**24
    # find populated ticks via bitmap
    max_index = tick_to_index(highest)
    max_word = max_index >> 8
    populated = []
    for w in range(0, max_word + 2):
        word = sread(mapping_slot(w, SLOT_BITMAP))
        if word == 0:
            continue
        for b in range(256):
            if (word >> b) & 1:
                idx = (w << 8) + b
                tick = index_to_tick(idx)
                if tick > highest:
                    continue
                populated.append(tick)
    populated.sort()

    positions = []
    for tick in populated:
        version = sread(mapping_slot(tick, SLOT_TICKVERSION))
        # _tickHash = keccak256(abi.encodePacked(int24 tick, uint256 version)) -> 3 bytes + 32 bytes
        tickhash = keccak(tick.to_bytes(3, "big", signed=True) + version.to_bytes(32, "big"))
        # tick data
        td_base = mapping_slot(tickhash, SLOT_TICKDATA)
        td_totalexpo = sread(td_base)
        td_totalpos = sread(td_base + 1) & ((1 << 248) - 1)
        td_penalty = sread(td_base + 2) & ((1 << 24) - 1)
        # positions array
        arr_len_slot = mapping_slot(tickhash, SLOT_LONGPOSITIONS)
        arr_len = sread(arr_len_slot)
        elem_base = int.from_bytes(keccak(arr_len_slot.to_bytes(32, "big")), "big")
        for i in range(arr_len):
            pos = read_position_slot(elem_base + 2 * i)
            if pos["user"] == Web3.to_checksum_address("0x" + "00" * 20) or pos["amount"] == 0:
                continue
            positions.append(dict(tick=tick, tickVersion=version, index=i,
                                  penaltyBps=td_penalty, tickTotalExpo=td_totalexpo,
                                  tickTotalPos=td_totalpos, **pos))

    out = dict(
        rpc=RPC, latestBlock=latest, proxy=PROXY,
        highestPopulatedTick=highest, totalLongPositions=totalpos,
        bitmapPopulatedTicks=len(populated), positionsFound=len(positions),
        lastPrice=str(lastprice), totalExpo=str(totalexpo),
        positions=positions,
    )
    print(json.dumps(out, indent=2))

if __name__ == "__main__":
    main()
