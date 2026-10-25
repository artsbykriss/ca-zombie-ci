#!/usr/bin/env python3
"""Read-only live-state collector for the Wager Predict (BSC) target.

Keyless public RPC only (no keys, no secrets). Produces analysis/live_state.json.
Usage: python3 analysis/collect_live_state.py
"""
import json, os, sys, urllib.request

RPC = os.environ.get("BSC_PUBLIC_RPC", "https://bsc-rpc.publicnode.com")

# --- addresses (BSC mainnet) ---
A = {
    "SpotEngine":      "0x76b91e83f2A12dc52E33f856eeA300E5B3A62c0c",
    "Vault":           "0x88d163d40D6BFe0Ad2b17f4a90A03053fEbf3014",
    "USDW_proxy":      "0xe5eBE2AE0a036C955bfF58291826C50F7d670D43",
    "USDW_impl":       "0x7169d192b5e2add3268651cf598886af42518cd8",
    "USDC_BSC":        "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d",
    "aBnbUSDC":        "0x00901a076785e0906d1028c7d6372d247bec7d61",
    "depositRecipient_EOA": "0x255E92b8e79800349f137d5b8EA70c0B658fd397",
    "redemptionSource_7702_EOA": "0x959b4a9Ad2dD1beBfD2579121325a75768C4D024",
    "redemptionSource_delegate": "0x03a46a241aa7073552652032aba85be46f647795",
    "USDW_treasury_EOA": "0xB445A0A6eb574BA3d3Dcd0e81619a9240b85aa94",
    "Registry":        "0x2D7E1000da132C46f20C7ba4f39F1BEF74F7adb4",
    "FeeRouter":       "0x186DCA432CE9f9B5618fcBb7231a6bE3FcEAe454",
    "InsuranceFund":   "0x3E3f937922Ed0a843C1566ce76723564aC2872Ab",
    "ResolutionModule":"0xdfc40D309C0D8f4Cc42863991C8e606eD330e1E8",
    "AccessController":"0x108b97C4d76B8753232301196796B44Ad2F27bcE",
    "ProtocolConfig":  "0x3Ea6Ab92C08E761986c095b45baf63dB0C26685c",
    "GovSafe_2of3":    "0xF39342C6758156df432fc47cDfF0cDd593E6CcC0",
    "Timelock":        "0x8f1B33cfDdF0A2Da5a4dDa1E6250c02915ad8CE2",
    "PriceOracle":     "0x5c3a3b430E44bD18Fd7f29Cb3Ec1948Bac542a9A",
    "AdminProxy":      "0xc2Dc9aad79Ab63D2772fb65Ce106584979DF610e",
    "LmsrAsMaker":     "0xB6F097da776338D5367251B6BC333Ef6F4029dD3",
    "OutcomeToken":    "0x3D0fe29B4F3AeA6E8d823FC04D0B522BE1d268cB",
    "Leverage_stub":   "0x0DAdcFb837C2797922D3A7037Ac62579005ce4c4",
    "Exchange":        "0x5e5fc18953bB72Dc9E782727B8b92f1415a6329C",
    "Owner_EOA":       "0xd873d9a8B9E35455F16e2C95CbD5c8b16ac45eA7",
}
# roles
ROLE = {
    "SIGNER":   "SIGNER", "ISSUER": "ISSUER", "OPERATOR": "OPERATOR",
    "ORACLE":   "ORACLE", "GOVERNOR": "GOVERNOR",
}
AC_ROLE = ["DEFAULT_ADMIN_ROLE","GOVERNANCE_ROLE","CREATOR_ROLE","REVIEWER_ROLE",
           "RESOLVER_ROLE","MM_ROLE","PAUSE_GUARDIAN_ROLE","TRADE_RECORDER_ROLE",
           "RESOLUTION_ROLE","GRADUATION_ROLE","FEE_SOURCE_ROLE","LEVERAGE_ROLE"]

_id = 0
def rpc(method, params):
    global _id
    _id += 1
    body = json.dumps({"jsonrpc":"2.0","id":_id,"method":method,"params":params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=40) as r:
        return json.load(r).get("result")

def call(to, sig):
    return rpc("eth_call", [{"to":to,"data":"0x"+sig}, "latest"])

def keccak_sel(sig):
    # use cast if available; else a tiny pure-python keccak is overkill -> shell out
    import subprocess
    return subprocess.check_output(["cast","keccak",sig]).decode().strip()

def selector(fnsig):
    # fnsig like "balanceOf(address)" -> 4-byte selector hex (no 0x)
    import subprocess
    return subprocess.check_output(["cast","sig",fnsig]).decode().strip()[2:]

def enc_u256(v): return format(v,"064x")
def enc_addr(a): return a.lower().replace("0x","").rjust(64,"0")
def enc_bytes32(h): return h.replace("0x","").rjust(64,"0")

def dec_u(res):
    if not res or res=="0x": return None
    return int(res,16)

def main():
    out = {"rpc": RPC, "addresses": A, "block": None, "calls": {}, "notes": []}
    bn = rpc("eth_blockNumber", [])
    out["block"] = int(bn,16)
    out["block_timestamp"] = int(rpc("eth_getBlockByNumber",[bn,False])["timestamp"],16)

    def C(key, addr, sig, args=()):
        data = "0x"+selector(sig)+"".join(args)
        res = call(addr, data[2:])
        v = dec_u(res)
        out["calls"][key] = {"to":addr,"sig":sig,"raw":res,"u256":v}
        return v

    # balances
    for k,a in A.items():
        if "USDC_BSC" == k: continue
    C("SpotEngine.balanceOf_USDW", A["USDW_proxy"], "balanceOf(address)", [enc_addr(A["SpotEngine"])])
    C("Vault.balanceOf_USDW",      A["USDW_proxy"], "balanceOf(address)", [enc_addr(A["Vault"])])
    C("Registry.balanceOf_USDW",   A["USDW_proxy"], "balanceOf(address)", [enc_addr(A["Registry"])])
    C("GovSafe.balanceOf_USDW",    A["USDW_proxy"], "balanceOf(address)", [enc_addr(A["GovSafe_2of3"])])
    C("InsuranceFund.balanceOf_USDW", A["USDW_proxy"], "balanceOf(address)", [enc_addr(A["InsuranceFund"])])
    C("USDW_treasury_EOA.balanceOf_USDW", A["USDW_proxy"], "balanceOf(address)", [enc_addr(A["USDW_treasury_EOA"])])
    C("USDW.totalSupply", A["USDW_proxy"], "totalSupply()")
    C("depositRecipient.aBnbUSDC", A["aBnbUSDC"], "balanceOf(address)", [enc_addr(A["depositRecipient_EOA"])])
    C("depositRecipient.USDC_BSC", A["USDC_BSC"], "balanceOf(address)", [enc_addr(A["depositRecipient_EOA"])])
    C("redemptionSource.USDC_BSC", A["USDC_BSC"], "balanceOf(address)", [enc_addr(A["redemptionSource_7702_EOA"])])
    C("redemptionSource.USDW", A["USDW_proxy"], "balanceOf(address)", [enc_addr(A["redemptionSource_7702_EOA"])])
    C("LmsrAsMaker.balanceOf_USDW", A["USDW_proxy"], "balanceOf(address)", [enc_addr(A["LmsrAsMaker"])])

    # config / oracle
    C("USDW.priceOracle", A["USDW_proxy"], "priceOracle()")
    C("USDW.depositRecipient", A["USDW_proxy"], "depositRecipient()")
    C("USDW.redemptionSource", A["USDW_proxy"], "redemptionSource()")
    C("USDW.treasury", A["USDW_proxy"], "treasury()")
    C("USDW.paused", A["USDW_proxy"], "paused()")
    C("USDW.isInputStable_USDC", A["USDW_proxy"], "isInputStable(address)", [enc_addr(A["USDC_BSC"])])
    C("ProtocolConfig.permissionlessResolution", A["ProtocolConfig"], "permissionlessResolution()")
    C("ProtocolConfig.platformBps", A["ProtocolConfig"], "platformBps()")
    C("ProtocolConfig.creatorBps", A["ProtocolConfig"], "creatorBps()")
    C("ProtocolConfig.depthBps", A["ProtocolConfig"], "depthBps()")
    C("ProtocolConfig.lpBps", A["ProtocolConfig"], "lpBps()")
    C("ProtocolConfig.lpFeeDestination", A["ProtocolConfig"], "lpFeeDestination()")
    C("ProtocolConfig.treasury", A["ProtocolConfig"], "treasury()")
    C("ProtocolConfig.gradVolume", A["ProtocolConfig"], "gradVolume()")
    C("ProtocolConfig.gradTraders", A["ProtocolConfig"], "gradTraders()")
    C("Vault.totalPrincipal", A["Vault"], "totalPrincipal()")
    C("Vault.positionCount", A["Vault"], "positionCount()")
    C("Vault.feeBuffer", A["Vault"], "feeBuffer()")
    C("Vault.totalFeeShares", A["Vault"], "totalFeeShares()")
    C("Vault.accFeesPerShare", A["Vault"], "accFeesPerShare()")
    C("Registry.marketCount", A["Registry"], "marketCount()")

    # spot markets
    mkts = []
    n = out["calls"]["Registry.marketCount"]["u256"] or 0
    for i in range(1, n+1):
        st = C(f"m{i}.state", A["Registry"], "marketState(uint256)", [enc_u256(i)])
        gsm = call(A["SpotEngine"], ("0x"+selector("getSpotMarket(uint256)")+enc_u256(i))[2:])
        vals = None
        if gsm and gsm != "0x":
            h = gsm[2:]
            vals = [int(h[j:j+64],16) for j in range(0,len(h),64)]
        mkts.append({"id":i,"state":st,"spot":vals})
    out["markets"] = mkts

    # AccessController roles
    roles = {}
    for r in AC_ROLE:
        h = keccak_sel(r)
        cnt = C(f"AC.{r}.count", A["AccessController"], "getRoleMemberCount(bytes32)", [enc_bytes32(h)])
        members = []
        if cnt:
            for j in range(cnt):
                res = call(A["AccessController"], ("0x"+selector("getRoleMember(bytes32,uint256)")+enc_bytes32(h)+enc_u256(j))[2:])
                if res and res!="0x":
                    members.append("0x"+res[2:][24:])
        roles[r] = {"hash":h,"count":cnt,"members":members}
    out["ac_roles"] = roles

    # USDW Administrator roles (no enumeration -> probe candidates)
    adm = call(A["USDW_proxy"], ("0x"+selector("administrator()"))[2:])
    out["calls"]["USDW.administrator"] = {"raw":adm,"addr":("0x"+adm[2:][24:]) if adm and adm!="0x" else None}
    admaddr = "0x"+adm[2:][24:]
    probes = [A["SpotEngine"],A["Vault"],A["Registry"],A["ResolutionModule"],A["FeeRouter"],
              A["InsuranceFund"],A["depositRecipient_EOA"],A["redemptionSource_7702_EOA"],
              A["GovSafe_2of3"],A["Timelock"],A["Owner_EOA"],A["LmsrAsMaker"]]
    admroles = {}
    for r in ROLE:
        h = keccak_sel(r)
        admroles[r] = {}
        for p in probes:
            res = call(admaddr, ("0x"+selector("hasRole(bytes32,address)")+enc_bytes32(h)+enc_addr(p))[2:])
            if res and res!="0x" and int(res,16)!=0:
                admroles[r][p] = True
    out["usdw_admin_roles_true"] = admroles

    os.makedirs("analysis", exist_ok=True)
    with open("analysis/live_state.json","w") as f:
        json.dump(out, f, indent=1)
    print("wrote analysis/live_state.json block", out["block"])

if __name__ == "__main__":
    main()
