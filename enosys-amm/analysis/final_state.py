#!/usr/bin/env python3
"""Assemble the final live-state evidence JSON for Enosys AMM V3."""
import json, hashlib, time
import rpc

TVL = json.load(open("tvl_final.json"))
SEC = json.load(open("security_tests.json"))

ADDRS = {
    "14": {
        "factory_proxy": "0x17aa157ac8c54034381b840cb8f6bf7fc355f0de",
        "factory_impl": "0xd835919c035ccd8ae295c43be4277aa3002d5e2c",
        "npm_proxy": "0xD9770b1C7A6ccd33C75b5bcB1c0078f46bE46657",
        "npm_impl": "0x0714c223cee8b138cced16e10fbf452b9178b416",
        "pool_impl": "0x23f02a41dea4fe6180b8e4aa56a745ea1ba4a88e",
        "pool_impl_verified_predecessor": "0xC07b7A5A44a037C8F7163e1C7B926D0c3906086d",
        "proxy_admin": "0xce22c2af6839ea3702df1a5d3167f5a8d71e9d35",
        "pools_proxy_admin": "0xAb856c28Ea2259Ce171FCF6560d8C0AEA9F42cec",
        "safe": "0xdedda08961216adb9ca09b88986d110127b24270",
        "protocol_fee_receiver": "0x36794833ae009368fdFb9736216F1160B9d1cBbE",
        "tracker_epoch": "0x5646f8f757ed7238f28ae930ab7e1d806413df36",
        "tracker_block": "0x46d99cf15f21a2a16fd2c70fc5412044506a8b30",
        "ftso_redistributor": "0x5a0BfF8Ff1AF1DF28619Fce57d07E3bBb7BAF3d7",
        "monthly_redistributor": "0xef514BCC4ab6226f5666a30d0c4672f00946e3dD",
        "wnat_registry": "0x3BaC97Fab1AEcA6815DB4464CaA9B2a7E0cFd220",
        "reward_manager": "0x38B542B05198aE2c8A16520B9f8A208b6552B77a",
        "epoch_manager": "0x389D610CBB52A2Da635a589013Ba542e807C74f7",
    },
    "19": {
        "factory_proxy": "0x416f1ccbc55033ae0133da96f9096fe8c2c17e7d",
        "factory_impl": "0xf0de831540c7210376f6f7e798c694ded99851fc",
        "npm_proxy": "0xFC02eB1Ab5079627103357BfbB8167d3BBAc6f1e",
        "npm_impl": "0xb126c5cd58d01896e6aa6025fd9e2b4c62e78a6d",
        "pool_impl": "0xfcba59d9f160bb8f26c0f1918d2aeaa74ca3e3a6",
        "proxy_admin": "0x3aa48b3127e3e05d2871576087d81d53e840b499",
        "pools_proxy_admin": "0x56035A7Ec075e45830311e550a56a261009FA2c4",
        "safe": "0x68d0818bb30b340ad99994592a88a3095e47522f",
        "protocol_fee_receiver": "0x16bfb7db0b4208dc72b918849108e56714430d58",
        "tracker_epoch": "0x8f74604c944c30c92f1f5227b1fdde05e701b1c4",
        "tracker_block": "0x3f19c2ca8ba4f2e4942cb9d937f554c7a6051580",
        "ftso_redistributor": "0x421294D3eb38c87390fc7f1442623f5b7DBc5b86",
        "wnat_registry": "0x1E3838C5Dc72B9a4f1D76E414e609652594d6096",
        "reward_manager": "0xa997E5FDd464b982d1Fbe51D8734A410744F3B7E",
        "epoch_manager": "0xDD79E5b82948103273F6d63d566d97472a16f9e8",
    },
}


def code_info(ch, a):
    c = rpc.code(ch, a)
    n = (len(c) - 2) // 2
    return {"address": a, "code_size": n,
            "sha256": hashlib.sha256(bytes.fromhex(c[2:])).hexdigest() if n else None}


def addr_call(ch, to, sel, default=None):
    try:
        r = rpc.call(ch, to, sel)
        return "0x" + r[-40:] if r and len(r) >= 42 else r
    except Exception:
        return default


def uint_call(ch, to, sel, default=None):
    try:
        return int(rpc.call(ch, to, sel), 16)
    except Exception:
        return default


out = {"read_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
       "chains": {}, "tvl": {"flare": TVL["flare"]["total_usd"], "songbird_local": TVL["songbird"]["total_usd"],
                             "total_local": TVL["total_local_usd"], "defillama_total": 6793213.10,
                             "defillama_flare": 6730974.70, "defillama_songbird": 62238.40},
       "security_tests_file": "analysis/security_tests.json",
       "source_diff_file": "analysis/source_diff_summary.json"}

for ch_s, a in ADDRS.items():
    ch = int(ch_s)
    d = {"block": rpc.block(ch), "addresses": {}}
    for k, v in a.items():
        d["addresses"][k] = code_info(ch, v)
    # EIP-1967 slots for proxies
    for proxy in ("factory_proxy", "npm_proxy"):
        p = a[proxy]
        d["addresses"][proxy]["eip1967_impl"] = "0x" + rpc.storage(ch, p, int(
            "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc", 16))[-40:]
        d["addresses"][proxy]["eip1967_admin"] = "0x" + rpc.storage(ch, p, int(
            "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103", 16))[-40:]
    d["factory_state"] = {
        "owner": addr_call(ch, a["factory_proxy"], "0x8da5cb5b"),
        "governor": addr_call(ch, a["factory_proxy"], "0x0c340a24"),
        "protocol_fee": uint_call(ch, a["factory_proxy"], "0xb0e21e8a"),
        "protocol_fee_receiver": addr_call(ch, a["factory_proxy"], "0x39a51be5"),
        "pools_count": uint_call(ch, a["factory_proxy"], "0x8c788de0"),
        "pool_implementation": addr_call(ch, a["factory_proxy"], "0xcefa7799"),
        "pools_proxy_admin": addr_call(ch, a["factory_proxy"], "0x9237f80c"),
        "history_tracker_epoch": addr_call(ch, a["factory_proxy"], "0xfe2a4acc"),
        "history_tracker_block": addr_call(ch, a["factory_proxy"], "0x2071fff8"),
        "ftso_redistributor": addr_call(ch, a["factory_proxy"], "0x35437e49"),
        "monthly_redistributor": addr_call(ch, a["factory_proxy"], "0x607081c5"),
        "wnat_registry": addr_call(ch, a["factory_proxy"], "0xd8dbda44"),
    }
    d["safe"] = {
        "address": a["safe"],
        "version": (lambda r: bytes.fromhex(r[2:]).decode(errors="replace").strip("\x00"))(
            rpc.call(ch, a["safe"], "0xffa1ad74")) if rpc.code(ch, a["safe"]) != "0x" else None,
        "threshold": uint_call(ch, a["safe"], "0xe75235b8"),
        "nonce": uint_call(ch, a["safe"], "0xaffed0e0"),
        "modules": rpc.call(ch, a["safe"], "0xb2494df3") if rpc.code(ch, a["safe"]) != "0x" else None,
    }
    # role counts on trackers
    upd = "e7d07e22cc47e0674aa5610dfc0c7c09a0a3b7491679c731a125fba46498854e"
    d["tracker_roles"] = {
        "updater_count_epoch": uint_call(ch, a["tracker_epoch"], "0xca15c873" + upd),
        "updater_count_block": uint_call(ch, a["tracker_block"], "0xca15c873" + upd),
        "has_updater_npm": uint_call(ch, a["tracker_epoch"], "0x91d14854" + upd + "0" * 24 + a["npm_proxy"][2:]),
        "current_epoch": uint_call(ch, a["tracker_epoch"], "0x941ea684"),
        "cleanup_epoch": uint_call(ch, a["tracker_epoch"], "0xb3c8f7dc"),
    }
    d["pools"] = {"count": TVL[str(ch) if str(ch) in TVL else ("flare" if ch == 14 else "songbird")]["block"] if False else None}
    out["chains"][ch_s] = d

# pool counts and tvl from files
out["chains"]["14"]["pools"] = {"count": len(TVL["flare"]["pools"]), "block": TVL["flare"]["block"],
                                 "tvl_usd": TVL["flare"]["total_usd"]}
out["chains"]["19"]["pools"] = {"count": len(TVL["songbird"]["pools"]), "block": TVL["songbird"]["block"],
                                 "tvl_usd_local": TVL["songbird"]["total_usd"]}
out["security_tests_block"] = SEC.get("block")

json.dump(out, open("final_state.json", "w"), indent=1)
print(json.dumps(out, indent=1)[:3000])
