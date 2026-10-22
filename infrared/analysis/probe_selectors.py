#!/usr/bin/env python3
"""Probe every value-moving / privileged selector on the iBERA proxy from a
FRESH unprivileged address. Read-only eth_call. Records revert data + decoded reason."""
import json, os, urllib.request, time

RPC = os.environ.get("BERA_RPC", "https://rpc.berachain.com")
PROXY = "0x9b6761bf2397Bb5a6624a856cC84A3A14Dcd3fe5"
FRESH = "0x00000000000000000000000000000000DeaDBeef"
ZERO32 = "0"*64
ID = 0

def rpc(method, params):
    global ID
    ID += 1
    body = json.dumps({"jsonrpc":"2.0","id":ID,"method":method,"params":params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"content-type":"application/json","user-agent":"Mozilla/5.0 (research)"})
    for a in range(4):
        try:
            with urllib.request.urlopen(req, timeout=40) as r:
                return json.loads(r.read())
        except Exception as e:
            if a == 3: return {"error":{"message":str(e)}}
            time.sleep(1.5)

def call(data, frm=FRESH, value=0, block="latest"):
    tx = {"to":PROXY, "data":data, "from":frm}
    if value: tx["value"] = hex(value)
    r = rpc("eth_call", [tx, block])
    if "error" in r:
        e = r["error"]
        return "REVERT:"+str(e.get("data", e.get("message","")))[:300]
    return r.get("result")

def addr32(a): return ZERO32[:-40]+a[2:].lower()
def u256(n): return format(n,"064x")

ADMIN="0x0000000000000000000000000000000000000000000000000000000000000000"
GOV="0x71840dc4906352362b0cdaf79870196c8e42acafade72d5d5a6d59291253ceb1"
KEEPER="0xfc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab"
PAUSER="0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a"

# candidate callers to test hasRole for
CALLERS = {
  "fresh":FRESH,
  "deployer_probe":FRESH,
  "proxy_self":PROXY,
  "depositor":"0x04CddC538ea65908106416986aDaeCeFD4CAB7D7",
  "withdrawor":"0x8c0e122960dc2e97dc0059c07d6901dce72818e1",
  "receivor":"0xf6a4a6acecd5311327ae3866624486b6179fef97",
  "infrared":"0xb71b3DaEA39012Fb0f2B14D2a9C86da9292fC126",
  "rateProvider":"0x776fd57bbeb752bdeeb200310fafae9a155c50a0",
}

probes = {
  # initialize / upgrade
  "initialize()":"0x8129fc1c",
  "initialize(address,address)":"0x485cc955"+addr32(FRESH)+addr32(FRESH),
  "upgradeToAndCall(address,bytes)":"0x4f1ef286"+addr32(FRESH)+u256(0x40)+u256(0),
  "proxiableUUID()":"0x52d1902d",
  # access control
  "grantRole(ADMIN,fresh)":"0x2f2ff15d"+ADMIN[2:]+addr32(FRESH),
  "grantRole(GOV,fresh)":"0x2f2ff15d"+GOV[2:]+addr32(FRESH),
  "grantRole(KEEPER,fresh)":"0x2f2ff15d"+KEEPER[2:]+addr32(FRESH),
  "grantRole(PAUSER,fresh)":"0x2f2ff15d"+PAUSER[2:]+addr32(FRESH),
  "revokeRole(ADMIN,fresh)":"0xd547741f"+ADMIN[2:]+addr32(FRESH),
  "renounceRole(ADMIN,fresh)":"0x36568abe"+ADMIN[2:]+addr32(FRESH),
  # pause
  "pause()":"0x8456cb59",
  "unpause()":"0x3f4ba83a",
  # mint/burn
  "mint(fresh) 0 value":"0x6a627842"+addr32(FRESH),
  "mint(fresh) 1e18 value":"0x6a627842"+addr32(FRESH),
  "burn(fresh,1e18)":"0x9dc29fac"+addr32(FRESH)+u256(10**18),
  "burn(fresh,1e16)":"0x9dc29fac"+addr32(FRESH)+u256(10**16),
  # admin setters
  "setWithdrawalsEnabled(false)":"0x0a179327"+u256(0),
  "updateBurnFee(0)":"0x71e36753"+u256(0),
  "updateRateProvider(fresh)":"0x496c62e7"+addr32(FRESH),
  "updateProofTimestampBuffer(1)":"0x00b4f1ad"+u256(1),
  "setFeeDivisorShareholders(1)":"0x6c84ce92"+u256(1),
  "setDepositSignature(0x00,0x00)":"0x5f481dc5"+u256(0x40)+u256(0x40)+u256(0)+u256(0),
  "claimExitFees(fresh)":"0x297b1cc0"+addr32(FRESH),
  # value moving / restricted
  "collect()":"0xe5225381",
  "sweep()":"0x35faa416",
  "compound()":"0xf69e2046",
  "register(0x00,1)":"0x4c98a2a9"+u256(0x40)+u256(1)+u256(0),
  "registerViaProofs(...)":"0x31bf59ee",
  "fafe94a8()":"0xfafe94a8",
}

out = {"block": rpc("eth_blockNumber",[]).get("result"), "proxy":PROXY, "fresh":FRESH,
       "role_holders":{}, "probes":{}}

# hasRole enumeration
for rname,role in [("DEFAULT_ADMIN_ROLE",ADMIN),("GOVERNANCE_ROLE",GOV),("KEEPER_ROLE",KEEPER),("PAUSER_ROLE",PAUSER)]:
    out["role_holders"][rname] = {}
    for cname,c in CALLERS.items():
        out["role_holders"][rname][cname] = call("0x91d14854"+role[2:]+addr32(c))

for name,data in probes.items():
    val = 10**18 if "1e18 value" in name else 0
    out["probes"][name] = {"data":data, "result": call(data, FRESH, val)}

print(json.dumps(out, indent=2))
