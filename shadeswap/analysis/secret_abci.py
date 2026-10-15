#!/usr/bin/env python3
"""Minimal Secret Network ABCI-query client (read-only, keyless).

Uses the Tendermint RPC /abci_query endpoint with CosmWasm gRPC query paths
because public LCDs on secret-4 do not expose /cosmwasm/* REST routes.

No secrets; public endpoint only.
"""
import base64
import json
import sys
import time
import urllib.parse
import urllib.request

RPC = "https://rpc.secret.mainnet.secret3.dev"


def varint(n: int) -> bytes:
    out = b""
    while True:
        b = n & 0x7F
        n >>= 7
        out += bytes([b | (0x80 if n else 0)])
        if not n:
            return out


def ld(field: int, payload: bytes) -> bytes:
    """length-delimited protobuf field"""
    return varint((field << 3) | 2) + varint(len(payload)) + payload


def read_varint(b: bytes, i: int):
    shift = 0
    val = 0
    while True:
        x = b[i]
        i += 1
        val |= (x & 0x7F) << shift
        if not (x & 0x80):
            return val, i
        shift += 7


def parse_proto(b: bytes):
    """Return list of (field, wiretype, value). LD values are bytes; varints int."""
    i = 0
    out = []
    while i < len(b):
        key, i = read_varint(b, i)
        field, wt = key >> 3, key & 7
        if wt == 0:
            v, i = read_varint(b, i)
            out.append((field, wt, v))
        elif wt == 2:
            ln, i = read_varint(b, i)
            out.append((field, wt, b[i:i + ln]))
            i += ln
        else:
            raise ValueError(f"unsupported wiretype {wt}")
    return out


def abci_query(path: str, data: bytes, height: int = 0, retries: int = 4, rpc: str = None):
    params = {"path": f'"{path}"', "data": "0x" + data.hex()}
    if height:
        params["height"] = str(height)
    url = f"{rpc or RPC}/abci_query?" + urllib.parse.urlencode(params)
    last = None
    for a in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=20) as r:
                j = json.load(r)
            resp = j["result"]["response"]
            if resp.get("code", 0) != 0:
                raise RuntimeError(f"abci code={resp.get('code')} log={resp.get('log')}")
            return base64.b64decode(resp["value"]), int(j["result"].get("height", 0))
        except Exception as e:  # noqa
            last = e
            time.sleep(1.5 * (a + 1))
    raise RuntimeError(f"abci_query failed: {last}")


def contract_info(addr: str):
    """Secret fork: QueryContractInfoResponse{ contract_address=1, contract_info=2(nested) }."""
    data = ld(1, addr.encode())
    raw, height = abci_query("/secret.compute.v1beta1.Query/ContractInfo", data)
    info = {"code_id": None, "creator_raw": None, "admin": None, "label": None,
            "created": None, "ibc_port_id": None}
    for f, wt, v in parse_proto(raw):
        if f == 1:
            info["contract_address"] = v.decode()
        elif f == 2 and wt == 2:
            for f2, wt2, v2 in parse_proto(v):
                if f2 == 1 and wt2 == 0:
                    info["code_id"] = v2
                elif f2 == 2 and wt2 == 2:
                    info["creator_raw"] = v2.hex()
                elif f2 == 4 and wt2 == 2:
                    info["label"] = v2.decode()
                elif f2 == 5 and wt2 == 2:
                    info["created"] = parse_proto(v2)
                elif f2 == 6 and wt2 == 2:
                    info["ibc_port_id"] = v2.decode()
                elif f2 == 7 and wt2 == 2:
                    info["admin"] = v2.decode()
                elif f2 == 9 and wt2 == 0:
                    info["require_governance"] = bool(v2)
    return info, height


def smart_query(addr: str, query: dict, height: int = 0):
    data = ld(1, addr.encode()) + ld(2, json.dumps(query).encode())
    raw, h = abci_query("/secret.compute.v1beta1.Query/QuerySecretContract", data, height=height)
    for f, wt, v in parse_proto(raw):
        if f == 1 and wt == 2:
            return json.loads(v.decode()), h
    return None, h


def contracts_by_code(code_id: int):
    data = varint(1 << 3) + varint(code_id)  # field1 varint
    raw, h = abci_query("/secret.compute.v1beta1.Query/ContractsByCodeId", data)
    out = []
    for f, wt, v in parse_proto(raw):
        if f == 1 and wt == 2:
            entry = {}
            for f2, wt2, v2 in parse_proto(v):
                if f2 == 1:
                    entry["address"] = v2.decode()
                elif f2 == 2:
                    ci = {}
                    for f3, wt3, v3 in parse_proto(v2):
                        if f3 == 1:
                            ci["code_id"] = v3
                        elif f3 == 2:
                            ci["creator_raw"] = v3.hex()
                        elif f3 == 4:
                            ci["label"] = v3.decode()
                        elif f3 == 7:
                            ci["admin"] = v3.decode()
                    entry["info"] = ci
            out.append(entry)
    return out, h


def address_by_label(label: str):
    data = ld(1, label.encode())
    raw, h = abci_query("/secret.compute.v1beta1.Query/AddressByLabel", data)
    for f, wt, v in parse_proto(raw):
        if f == 1 and wt == 2:
            return v.decode(), h
    return None, h


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "info":
        info, h = contract_info(sys.argv[2])
        print(json.dumps({"height": h, "info": info}, indent=1))
    elif cmd == "smart":
        q = json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}
        res, h = smart_query(sys.argv[2], q)
        print(json.dumps({"height": h, "result": res}, indent=1))
    elif cmd == "bycode":
        res, h = contracts_by_code(int(sys.argv[2]))
        print(json.dumps({"height": h, "count": len(res), "contracts": res}, indent=1))
    elif cmd == "bylabel":
        res, h = address_by_label(sys.argv[2])
        print(json.dumps({"height": h, "address": res}, indent=1))
