import json, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from rpc import batch, block_number, uint, addr, sel

V = {
    "ethereum": {"WETH": "0x29bcfeD246ce37319d94eBa107db90C453D4c43D", "USDC": "0x9B44efCa3e2a707B63Dc00CE79d646E5E5D24bA5"},
    "optimism": {"WETH": "0x91b8657aea26Caa8A0E9D6DD4E24727Ccf32F822", "USDC": "0xAf510a560744880410f0f65e3341A020FBC2cA41"},
    "arbitrum": {"WETH": "0xfe8F223F3d81462F55bf8609897B8cEcfA4B195C", "USDC": "0xEba62B842081CeF5a8184318Dc5C4E4aACa9f651"},
    "base": {"USDC": "0xb8BeFE5a6941ca4022a52042075ff269C3C67467"},
}
ALCH = {
    "ethereum:alUSD": ("ethereum", "0xeB83112d925268BeDe86654C13D423a987587e3E"),
    "ethereum:alETH": ("ethereum", "0xfa995B6ABc387376C3e7De5f6d394Ab5B6beE26B"),
    "optimism:alUSD": ("optimism", "0x930750a3510E703535e943E826ABa3c364fFC1De"),
    "optimism:alETH": ("optimism", "0xDeD3A04612FF12b57317abE38e68026Fc9D28114"),
    "arbitrum:alUSD": ("arbitrum", "0x930750a3510E703535e943E826ABa3c364fFC1De"),
    "arbitrum:alETH": ("arbitrum", "0xDeD3A04612FF12b57317abE38e68026Fc9D28114"),
    "base:alUSDb": ("base", "0xEb380d86EeD275C9F2eD77745aB1B2ccf364BF7A"),
}

out = {"vaults": {}, "alchemists": {}, "blocks": {}}
for chain, vs in V.items():
    bn = block_number(chain)
    out["blocks"][chain] = bn
    calls = []
    for a in vs.values():
        calls += [(a, sel("totalAssets()")), (a, sel("totalSupply()")), (a, sel("maxRate()")),
                  (a, sel("convertToAssets(uint256)") + hex(10**18)[2:].zfill(64))]
    r = batch(chain, calls, bn, chunk=10)
    i = 0
    for k, a in vs.items():
        out["vaults"][chain + ":" + k] = {
            "vault": a, "block": bn,
            "totalAssets": uint(r[i]), "totalSupply": uint(r[i + 1]),
            "maxRate": uint(r[i + 2]), "pricePer1e18": uint(r[i + 3]),
        }
        i += 4

for k, (chain, a) in ALCH.items():
    bn = block_number(chain)
    r = batch(chain, [(a, sel("totalSyntheticsIssued()")), (a, sel("getTotalUnderlyingValue()")),
                      (a, sel("getTotalLockedUnderlyingValue()")), (a, sel("minimumCollateralization()")),
                      (a, sel("collateralizationLowerBound()"))], bn, chunk=5)
    out["alchemists"][k] = {
        "alchemist": a, "block": bn,
        "totalSyntheticsIssued": uint(r[0]), "totalUnderlyingValue": uint(r[1]),
        "totalLockedUnderlyingValue": uint(r[2]),
        "minimumCollateralization": uint(r[3]), "collateralizationLowerBound": uint(r[4]),
    }

os.makedirs("ci-out", exist_ok=True)
json.dump(out, open("ci-out/live_state.json", "w"), indent=1)
print(json.dumps({"blocks": out["blocks"], "vaults": {k: v["totalAssets"] for k, v in out["vaults"].items()}}, indent=1))
