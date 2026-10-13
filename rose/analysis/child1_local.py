#!/usr/bin/env python3
"""Child1: local differential test - deploy canonical (original) and vase2 reconstruction on
plain anvil and compare behavior on the same calldata battery. No secrets (anvil unlocked accounts)."""
import json, os, subprocess, time, urllib.request, sys
from Crypto.Hash import keccak

ANALYSIS = "/home/heisenberg/CA/rose/analysis"
solc_bin = os.path.expanduser("~/.solc-select/artifacts/solc-0.6.12/solc-0.6.12")
RPC = "http://127.0.0.1:8545"
ANVIL_ACCT = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

def rpc(method, params, retries=3):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    for _ in range(retries):
        try:
            req = urllib.request.Request(RPC, data=payload, headers={"Content-Type": "application/json"})
            r = json.load(urllib.request.urlopen(req, timeout=30))
            if "error" in r:
                return {"error": r["error"]}
            return {"result": r["result"]}
        except Exception:
            time.sleep(1)
    return {"error": {"message": "unreachable"}}

def compile_variant(srcfile, outjson, weth):
    text = open(srcfile, newline='').read()
    inp = {"language": "Solidity",
           "sources": {"BentoBoxFlat.sol": {"content": text}},
           "settings": {"optimizer": {"enabled": True, "runs": 999999},
                        "metadata": {"bytecodeHash": "ipfs"},
                        "outputSelection": {"*": {"*": ["evm.bytecode.object"]}}}}
    open(f"{ANALYSIS}/child1_local_stdin.json", "w").write(json.dumps(inp))
    with open(f"{ANALYSIS}/child1_local_stdin.json") as f:
        r = subprocess.run([solc_bin, "--standard-json"], stdin=f, capture_output=True, text=True)
    out = json.loads(r.stdout)
    code = out["contracts"]["BentoBoxFlat.sol"]["BentoBoxV1"]["evm"]["bytecode"]["object"]
    arg = weth.lower()[2:].rjust(64, "0")
    return "0x" + code + arg

def deploy(creation):
    r = rpc("eth_sendTransaction", [{"from": ANVIL_ACCT, "data": creation, "gas": "0x1c9c380"}])
    if "error" in r:
        return None, r["error"]
    txh = r["result"]
    for _ in range(30):
        rc = rpc("eth_getTransactionReceipt", [txh])
        if rc.get("result"):
            return rc["result"]["contractAddress"], None
        time.sleep(0.5)
    return None, "no receipt"

def main():
    original = compile_variant(f"{ANALYSIS}/child1_bentobox_flat.sol", "original", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2")
    vase2 = compile_variant(f"{ANALYSIS}/child1_vase2_flat.sol", "vase2", "0xC9Bdeed33CD01541e1eed10F90519d2C06Fe3feb")
    print("creation sizes:", (len(original) - 2) // 2, (len(vase2) - 2) // 2)

    # start anvil
    anvil = subprocess.Popen(["anvil", "--silent", "--port", "8545"],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(2.5)
    try:
        # sanity
        chk = rpc("eth_chainId", [])
        print("anvil chainId:", chk)
        addr_o, err_o = deploy(original)
        addr_v, err_v = deploy(vase2)
        print("deployed original:", addr_o, err_o, " vase2:", addr_v, err_v)
        if not addr_o or not addr_v:
            return
        # battery
        sys.path.insert(0, ANALYSIS)
        import importlib.util
        spec = importlib.util.spec_from_file_location("dc", f"{ANALYSIS}/child1_diffcall.py")
        dc = importlib.util.module_from_spec(spec); spec.loader.exec_module(dc)
        cases = []
        cases.append(("batch_empty_false", dc.batch_calldata([], False)))
        cases.append(("batch_one_empty_bytes", dc.batch_calldata([b""], False)))
        cases.append(("batch_call_nonces_dead", dc.batch_calldata([bytes.fromhex(dc.SEL["nonces"][2:]) + bytes.fromhex(dc.w(dc.DEAD))], False)))
        cases.append(("batch_call_owner", dc.batch_calldata([bytes.fromhex(dc.SEL["owner"][2:])], False)))
        cases.append(("batch_call_bytes4_padded", dc.batch_calldata([b"\xde\xad\xbe\xef"], False)))
        cases.append(("batch_malformed_len1_nodata", dc.raw_batch(0x40, 0, dc.w(1))))
        cases.append(("batch_malformed_offset_oob", dc.raw_batch(0x40, 0, dc.w(1) + dc.w(0xffff))))
        cases.append(("batch_malformed_len_huge", dc.raw_batch(0x40, 0, dc.w(1) + dc.w(0x20) + dc.w(int("ff" * 32, 16)) + "00" * 16)))
        cases.append(("batch_call_unknown_selector", dc.batch_calldata([b"\x11\x22\x33\x44"], False)))
        cases.append(("batch_call_nested", dc.batch_calldata([dc.batch_calldata([], False)], False)))
        cases.append(("deploy_master_zero", dc.raw_deploy("0x" + "0" * 40, False, "0x")))
        cases.append(("deploy_master_dead_noinit", dc.raw_deploy(dc.DEAD, False, "0x")))
        cases.append(("transferMultiple_emptytos_v", "0x0fca8843" + dc.w(addr_v) + dc.w(addr_v) + dc.w(0x80) + dc.w(0xA0) + dc.w(0) + dc.w(0)))

        out = {"original": addr_o, "vase2": addr_v, "cases": {}}
        for name, data in cases:
            if isinstance(data, (bytes, bytearray)):
                data = "0x" + data.hex()
            to = addr_v if name.endswith("_v") else addr_o
            a = rpc("eth_call", [{"to": addr_o, "data": data, "from": ANVIL_ACCT, "gas": hex(3000000)}, "latest"])
            b = rpc("eth_call", [{"to": addr_v, "data": data, "from": ANVIL_ACCT, "gas": hex(3000000)}, "latest"])
            same = dc.norm(a) == dc.norm(b)
            out["cases"][name] = {"original": a, "vase2": b, "equal": same}
            print(f"--- {name}: equal={same}")
            print(f"    orig : {json.dumps(a)[:170]}")
            print(f"    vase2: {json.dumps(b)[:170]}")
        json.dump(out, open(f"{ANALYSIS}/child1_local_diff.json", "w"), indent=1)
        neq = [k for k, v in out["cases"].items() if not v["equal"]]
        print("unequal:", neq)
    finally:
        anvil.terminate()

if __name__ == "__main__":
    main()
