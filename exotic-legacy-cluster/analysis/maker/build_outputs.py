import json
from datetime import datetime, timezone

BN = 26217462
TS = 1792302587
ETH_USD = 2412.122829474341
KNC_USD = 0.12070595336652383
ATTACK_MODULE = "0xf09a13072Ed939B79Bc25B66AA3a836ea6DCC170"

scan = json.load(open("bids_scan.json"))
clean = json.load(open("flippers_clean.json"))
cat = json.load(open("cat_flips.json"))
guys_state = json.load(open("guys_vat_state.json"))
owner_state = json.load(open("owner_vat_state.json"))

# ---------- flippers.json ----------
catmap = {x["ilk"]: x.get("flip") for x in cat}
ilks = []
for x in cat:
    ilks.append({"ilk": x["ilk"], "cat_flip": x.get("flip")})

flagged = []
for r in scan["flagged"]:
    ilk = r["ilk"]
    lot = r["lot"] / 1e18
    if ilk == "KNC-A":
        usd = lot * KNC_USD
        unit = "KNC"
    else:
        usd = lot * ETH_USD
        unit = "ETH"
    g = r["guy"]
    gs = guys_state.get(g, {"dai": 0, "gem": {}, "can": None})
    flagged.append({
        "ilk": ilk,
        "flipper": r["flip"],
        "id": r["id"],
        "bid_dai": r["bid"] / 1e45,
        "lot": lot,
        "unit": unit,
        "tab_dai": r["tab"] / 1e45,
        "guy": g,
        "usr": r["usr"],
        "gal": r["gal"],
        "tic": r["tic"],
        "end": r["end"],
        "end_utc": datetime.fromtimestamp(r["end"], timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC"),
        "age_days": r["age_days"],
        "expired": r["expired"],
        "dealable": True,
        "deal_sim": "OK (eth_call at block)",
        "usd_at_2026_10_18": round(usd, 2),
        "guy_type": "contract" if g.lower() == "0xfb04641a1ab744254706c5e0680a1dd533170a0b" else "EOA",
        "guy_vat_gem": {k: v / 1e18 for k, v in gs.get("gem", {}).items()},
        "guy_vat_dai": gs.get("dai", 0) / 1e45,
        "guy_vat_can_attacker_module": gs.get("can", 0),
        "guy_family_match": False,
    })

by_ilk = {}
for x in flagged:
    d = by_ilk.setdefault(x["ilk"], {"count": 0, "lot": 0.0, "usd": 0.0, "unit": x["unit"]})
    d["count"] += 1
    d["lot"] += x["lot"]
    d["usd"] += x["usd_at_2026_10_18"]
for d in by_ilk.values():
    d["lot"] = round(d["lot"], 8)
    d["usd"] = round(d["usd"], 2)

flippers_json = {
    "target": "MakerDAO legacy auction-keeper family / all legacy Flippers",
    "chain": "ethereum",
    "chain_id": 1,
    "block": BN,
    "timestamp": TS,
    "timestamp_utc": datetime.fromtimestamp(TS, timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC"),
    "ilk_count": len(ilks),
    "cat_flip_count": sum(1 for x in cat if x.get("flip")),
    "flipper_count": len(clean),
    "active_flippers_kicks_gt_0": sum(1 for x in clean if x["kicks"] > 0),
    "bids_scanned": sum(x["kicks"] for x in clean),
    "undealt_count": len(scan["undealt"]),
    "flagged_count": len(flagged),
    "dealable_count": len(flagged),
    "totals_by_ilk": by_ilk,
    "flippers": [
        {"ilk": x["ilk"], "flip": x["flip"], "kicks": x["kicks"], "has_code": True,
         "vat": x.get("vat")}
        for x in clean
    ],
    "ilks": ilks,
    "flagged_bids": flagged,
    "notes": [
        "Ilk universe = 78 unique ilks ever initialized in MCD_VAT (Vat init LogNote scan, blocks 8,920,000-26,217,462).",
        "IlkRegistry at the prompt address 0x5a464C28D19848f44199D003BeF5ecc87cD57CFF has no code; chainlog ILK_REGISTRY = 0x5a464C28D19848f44199D003BeF5ecc87d090F87 (count()=35 current ilks).",
        "Cat.ilks(ilk) returns a non-zero legacy Flipper for 33 of the 78 ilks; a further 10 Flippers are older/newer generations found in the FlipperFab creation graph (2 FlipperFab contracts).",
        "All 6,737 bids (ids 1..kicks() for all 27 Flippers with kicks>0) were read at block 26,217,462; bids 1457-1460 (the Oct-6 incident lots) are deleted and show lot=0.",
        "Flagged = lot>0 AND guy!=0 AND end<now. All 8 flagged lots are dealable; deal() pays the lot to guy, not the caller.",
        "Values use ETH $2,412.122829 and KNC $0.120705953 at 2026-10-18 06:23-06:35 UTC (DefiLlama).",
    ],
}
json.dump(flippers_json, open("flippers.json", "w"), indent=1)

# ---------- keepers.json ----------
claims = {}
for x in flagged:
    claims.setdefault(x["guy"], []).append(x)

bidder_meta = {
    "0x04bb161c4e7583cdaadee93a8b8e6125fd661e57": {
        "type": "EOA", "code_size": 0, "codehash": None,
        "eth": 0.013445879066022876, "weth": 2.15044853204e-06, "dai": 0.0, "knc": 0.0,
        "note": "2020 ETH-A bidder. Holds 0.67 DAI in Vat; no contract, no drain path. Claim = ETH-A 4885/4886.",
    },
    "0x4d27e99aeacc3bda29a91c9dbc73afc80bc24782": {
        "type": "EOA", "code_size": 0, "codehash": None,
        "eth": 0.007926271940283867, "weth": 0.0, "dai": 0.0, "knc": 0.0,
        "note": "2020 ETH-A bidder. Holds 11.230357630243322739 ETH-A gem in Vat (from other dealt auctions); no contract, no drain path. Claim = ETH-A 3190.",
    },
    "0xc2f61a6eeec48d686901d325cde9233b81c793f3": {
        "type": "EOA", "code_size": 0, "codehash": None,
        "eth": 3.531824143489948, "weth": 4.698268765590779, "dai": 0.005454935315533706, "knc": 0.0,
        "note": "2020 ETH-A bidder. Holds 1.34 ETH-A gem + 3.95 DAI in Vat; no contract, no drain path. Claim = ETH-A 3563/3753/4459.",
    },
    "0xfb04641a1ab744254706c5e0680a1dd533170a0b": {
        "type": "contract", "code_size": 12955,
        "codehash": "0x8af17f370fd5aa2223595749702f8ee689fe0c6da7968d1a1666eff532945752",
        "eth": 0.0, "weth": 0.0, "dai": 0.0, "knc": 0.0,
        "note": "2021 KNC-A bidder contract (creator 0xb00b6d69822da235a99d2242376066507c9a97b7, block 10,876,436). Maker keeper with cat/vow/jug/flap/flop/flips/gemJoins/managers; managers(creator)=1. NOT the 0x8804d1de family (selector absent); vat.gem WBTC-A 8.8e-9 and vat.dai 1.0 DAI dust. Claim = KNC-A 23/24 (4,910.48 KNC, $592.72); no unprivileged extraction path identified.",
    },
}

bidders = []
for g, cl in claims.items():
    m = bidder_meta[g]
    gs = guys_state.get(g, {"dai": 0, "gem": {}, "can": None})
    cusd = sum(x["usd_at_2026_10_18"] for x in cl)
    bidders.append({
        "address": g,
        "type": m["type"],
        "code_size": m["code_size"],
        "codehash": m["codehash"],
        "claims": [{"ilk": x["ilk"], "flipper": x["flipper"], "id": x["id"],
                    "lot": x["lot"], "unit": x["unit"], "usd": x["usd_at_2026_10_18"]} for x in cl],
        "claim_total_usd": round(cusd, 2),
        "vat_gem": {k: v / 1e18 for k, v in gs.get("gem", {}).items()},
        "vat_dai": gs.get("dai", 0) / 1e45,
        "vat_can_attacker_module": gs.get("can", 0),
        "eth": m["eth"], "weth": m["weth"], "dai": m["dai"], "knc": m["knc"],
        "family_match": False,
        "drain_callable": False if m["type"] == "EOA" else "n/a (no 0x8804d1de)",
        "note": m["note"],
    })

family = [
    {
        "name": "victim_proxy", "address": "0x9c05a05893Ada984FC20D0DA0c046De5Cc0e8273",
        "role": "EIP-1967 AdminUpgradeabilityProxy (the incident victim)",
        "code_size": 2240, "codehash": "0x0edc21cfc95adaaaf6c14b1520a187816134c21c3963e6ba7308ee5faf5ebdcc",
        "impl": "0x68399ed8aa33C5b43F863EE6782de492006A5546",
        "admin": "0x5b492f7483da1778c450b9b18f5df9d95cab8efe",
        "proxy_admin_owner": "0x52ce67ba2cd112ed7b34ae935407c215ac7b32d3",
        "implementation_owner": "0xaDC374E77b89Af0B8B39F7c47E8e0A37B6DaF073",
        "drain_selector": True,
        "drain_callable": True,
        "drain_evidence": "Real Oct-6 tx 0xbb6940... succeeded from fresh attacker; eth_call drain(worker=0xf09a...,0) reverts only at worker.join with Flipper/not-finished, i.e. auth passed; Vat Hope log in tx.",
        "vat_gem": {}, "vat_dai": 0.0, "eth": 0.0, "weth": 0.0, "dai": 0.0,
        "vat_can_attacker_module": 1,
        "note": "Drained Oct 6; $0 now. Attacker module still holds standing vat.hope.",
    },
    {
        "name": "impl_v2", "address": "0x68399ed8aa33C5b43F863EE6782de492006A5546",
        "role": "v2 implementation (unverified), deployed by operator at block 9,565,920",
        "code_size": 10185, "codehash": "0x8449fde7e5cfb4412396ffcf81f266acb465dff1b705dd5cc27dcaacd62172f1",
        "drain_selector": True, "drain_callable": True,
        "drain_evidence": "eth_call from 0x2222... to 0x8804d1de with worker=attacker module reaches worker.join (revert Flipper/not-finished); no auth revert.",
        "vat_gem": {}, "vat_dai": 0.0, "eth": 0.0, "weth": 0.0, "dai": 0.0,
        "vat_can_attacker_module": 0,
        "note": "Bytecode has 0x8804d1de twice (dispatcher offset 21, handler 0x02e3); body at 0x1223 starts with worker.drip() and never reads owner/authority.",
    },
    {
        "name": "clone_v2", "address": "0xa7a6d04dfa4e2646489a361b74e2b317c2a53608",
        "role": "standalone copy byte-identical to impl_v2, deployed by operator at block 9,565,856",
        "code_size": 10185, "codehash": "0x8449fde7e5cfb4412396ffcf81f266acb465dff1b705dd5cc27dcaacd62172f1",
        "drain_selector": True, "drain_callable": True,
        "drain_evidence": "eth_call drain(worker=attacker module,0) reaches worker.join (Flipper/not-finished); no auth revert.",
        "vat_gem": {}, "vat_dai": 0.0, "eth": 0.0, "weth": 0.0, "dai": 0.0,
        "vat_can_attacker_module": 0,
        "note": "$0; same bytecode as the exploited implementation.",
    },
    {
        "name": "impl_v1", "address": "0x721dc69893cf62c532ef566e7ff2c0532343148b",
        "role": "v1 implementation, deployed by dealer at block 9,437,625",
        "code_size": 10184, "codehash": "0xd9b1d1c95cf2c965fa582f37d1675d1ad27d09c9e01ba098172451fb1b0c5418",
        "drain_selector": True, "drain_callable": True,
        "drain_evidence": "eth_call drain(worker=attacker module,0) reaches worker.join (Flipper/not-finished); no auth revert.",
        "vat_gem": {}, "vat_dai": 0.0, "eth": 0.0, "weth": 0.0, "dai": 0.0,
        "vat_can_attacker_module": 0,
        "note": "Initial implementation of the victim proxy; replaced at block 9,566,071. $0.",
    },
    {
        "name": "v1_copy", "address": "0xcf7e34f9ac4d91d3430f7c34251bda02fac13440",
        "role": "standalone copy byte-identical to impl_v1, deployed by dealer at block 9,437,617",
        "code_size": 10184, "codehash": "0xd9b1d1c95cf2c965fa582f37d1675d1ad27d09c9e01ba098172451fb1b0c5418",
        "drain_selector": True, "drain_callable": True,
        "drain_evidence": "eth_call drain(worker=attacker module,0) reaches worker.join (Flipper/not-finished); no auth revert.",
        "vat_gem": {}, "vat_dai": 0.0, "eth": 0.0, "weth": 0.0, "dai": 0.0,
        "vat_can_attacker_module": 0,
        "note": "$0.",
    },
    {
        "name": "v0_keeper", "address": "0xdaa93d669a5b06b607a675a418ce2c804e21bb7b",
        "role": "v0 keeper (14,962 bytes), deployed by dealer at block 9,437,332",
        "code_size": 14962, "codehash": "0x8fea9c6a5a1426112e88bc5884a31c615a056438ea430854c62e61ae43ecd559",
        "drain_selector": True, "drain_callable": True,
        "drain_evidence": "eth_call drain(worker=attacker module,0) reaches worker.join (Flipper/not-finished); no auth revert.",
        "vat_gem": {}, "vat_dai": 0.0, "eth": 0.0, "weth": 0.0, "dai": 0.0,
        "vat_can_attacker_module": 0,
        "note": "$0; older/other keeper codebase but same 0x8804d1de selector and same ungated behavior.",
    },
    {
        "name": "proxyadmin_5b49", "address": "0x5b492f7483da1778c450b9b18f5df9d95cab8efe",
        "role": "ProxyAdmin for the victim; owner = dealer EOA 0x52ce67ba...",
        "code_size": 2844, "codehash": "0xc908d46338f71e7e7ad2283fa0077c78da9c3f99035ce9faf2c8e2b6c22b939e",
        "drain_selector": False, "drain_callable": False,
        "vat_gem": {}, "vat_dai": 0.0, "eth": 0.0, "weth": 0.0, "dai": 0.0,
        "note": "Privileged: owner can upgrade the victim. Only upgrade calls target the victim (blocks 9,566,001/49/63 failed/attempted, 9,566,071 succeeded).",
    },
    {
        "name": "proxyadmin_777e", "address": "0x777e07b5549eb830fcbd118431d948c2f6b584fe",
        "role": "second ProxyAdmin copy; owner = dealer EOA; no upgrade transactions",
        "code_size": 2844, "codehash": "0xc908d46338f71e7e7ad2283fa0077c78da9c3f99035ce9faf2c8e2b6c22b939e",
        "drain_selector": False, "drain_callable": False,
        "vat_gem": {}, "vat_dai": 0.0, "eth": 0.0, "weth": 0.0, "dai": 0.0,
        "note": "Unused in the covered history.",
    },
]

drain_calls = [
    {"target": x["address"], "name": x["name"], "result": "revert at worker.join: Flipper/not-finished",
     "interpretation": "Passed all access control; reached vat.hope(worker) and worker.join(0). Ungated."}
    for x in family if x.get("drain_callable")
]

sibling_search = {
    "dealer_eoa": "0x52ce67ba2cd112ed7b34ae935407c215ac7b32d3",
    "dealer_is_contract": False,
    "dealer_created": [
        {"block": 9437332, "address": "0xdaa93d669a5b06b607a675a418ce2c804e21bb7b", "role": "v0 keeper, $0"},
        {"block": 9437384, "address": "0x777e07b5549eb830fcbd118431d948c2f6b584fe", "role": "ProxyAdmin, unused, $0"},
        {"block": 9437617, "address": "0xcf7e34f9ac4d91d3430f7c34251bda02fac13440", "role": "v1 keeper byte-identical copy, $0"},
        {"block": 9437625, "address": "0x721dc69893cf62c532ef566e7ff2c0532343148b", "role": "v1 implementation, $0"},
        {"block": 9437641, "address": "0x5b492f7483da1778c450b9b18f5df9d95cab8efe", "role": "ProxyAdmin for victim, $0"},
        {"block": 9437648, "address": "0x9c05a05893Ada984FC20D0DA0c046De5Cc0e8273", "role": "victim proxy, drained, $0"},
    ],
    "operator_eoa": "0xaDC374E77b89Af0B8B39F7c47E8e0A37B6DaF073",
    "operator_is_contract": False,
    "operator_created": [
        {"block": 9565856, "address": "0xa7a6d04dfa4e2646489a361b74e2b317c2a53608", "role": "v2 byte-identical clone, $0"},
        {"block": 9565920, "address": "0x68399ed8aa33C5b43F863EE6782de492006A5546", "role": "v2 implementation, $0"},
    ],
    "upgraded_logs": {
        "impl_0x68399": ["0x9c05a05893Ada984FC20D0DA0c046De5Cc0e8273 (block 9566071)"],
        "impl_0x721dc698": [],
        "clone_0xa7a6d04": [],
    },
    "proxy_count": 1,
    "sibling_proxy_count": 0,
    "sibling_implementation_count": 5,
    "sibling_keepers_with_value": 0,
    "caveat": "A proxy deployed by an unrelated EOA with this unverified impl and no Upgraded event cannot be excluded by public-RPC reads alone; all deployer/upgrade paths of the family are covered (dealer EOA, operator EOA, both ProxyAdmins, all Upgraded logs).",
}

post_state = {
    "victim": {
        "address": "0x9c05a05893Ada984FC20D0DA0c046De5Cc0e8273",
        "eth": 0.0, "weth": 0.0, "dai": 0.0,
        "vat_gem_all_ilks": {}, "vat_dai": 0.0,
        "vat_can_attacker_module": 1,
        "vat_can_attacker_eoa": 0, "vat_can_helper": 0,
        "note": "Standing hope persists; $0 now.",
    },
    "attacker_module": {
        "address": "0xf09a13072Ed939B79Bc25B66AA3a836ea6DCC170",
        "eth": 0.0, "weth": 0.0, "dai": 0.0,
        "vat_gem_all_ilks": {}, "vat_dai": 0.0,
        "note": "$0; still holds vat.can over victim.",
    },
    "attacker_eoa": {"address": "0x01EB957E5C7DcDDD60F3C875956cCc6fb9BdA5FA", "eth": 0.0700914982495694},
    "helper": {"address": "0xEc997d2aD033277913d6002277353368E8321dcF", "eth": 0.0},
    "realized_attack": {
        "tx": "0xbb6940f7c2a1e68cafbae7bb9b94d09af9af06ec3a114f6996f2cab993f3a88c",
        "block": 26131471,
        "timestamp": 1791267191,
        "timestamp_utc": "2026-10-06 06:13:11 UTC",
        "profit_eth": 200.0,
        "profit_usd_at_incident": 538000,
        "certik_figure_usd": 542982,
        "note": "Receipt status 1; 4 Flipper deal logs (ids 1457-1460), Vat Hope(worker), 200 WETH transfer/withdraw.",
    },
}

other_holders = {
    "operator": {
        "address": "0xaDC374E77b89Af0B8B39F7c47E8e0A37B6DaF073",
        "eth": 0.06245173608560041,
        "vat_gem": {"ETH-A": 0.3684476967915587},
        "vat_dai": 2.9630512199914896e-19,
        "can_to_family": {},
        "note": "Owner of victim; holds 0.368 ETH-A gem. No hope granted to any family contract.",
    },
    "dealer": {
        "address": "0x52ce67ba2cd112ed7b34ae935407c215ac7b32d3",
        "eth": 0.003091779673977709,
        "vat_gem": {"ETH-A": 7.99e-07},
        "vat_dai": 3.29544876,
        "can_to_family": {},
        "note": "ProxyAdmin owner; 3.295 DAI. No hope granted to any family contract.",
    },
}

third_party = {
    "existing_vat_gem_eth_bidders": 12.570357630243322739,
    "existing_vat_gem_usd_bidders": 30321.246614566893,
    "existing_vat_dai_bidders": 5.625372905029706,
    "undealt_lots_usd": 4973.88,
    "h_o_total_usd": 35300.75,
    "owner_side_vat_usd": 892.04,
    "total_observed_usd": 36192.79,
    "at_risk_from_0x8804d1de_usd": 0,
    "note": "H-O = four bidders only (three EOAs + one non-family keeper contract): 12.570 ETH-A gem + 5.625 DAI in Vat + 8 undealt lots. None has granted vat.can to any family contract; not attacker-extractable via this bug. Operator/dealer hold a further ~$892, shown separately.",
}

keepers_json = {
    "target": "MakerDAO legacy auction-keeper family / bidder keepers",
    "chain": "ethereum",
    "block": BN,
    "timestamp": TS,
    "timestamp_utc": datetime.fromtimestamp(TS, timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC"),
    "bidders": bidders,
    "family_contracts": family,
    "drain_callability": drain_calls,
    "sibling_search": sibling_search,
    "post_state": post_state,
    "other_holders": other_holders,
    "third_party_value": third_party,
}
json.dump(keepers_json, open("keepers.json", "w"), indent=1)

# ---------- summary.json ----------
summary = {
    "target": "0x9c05a05893Ada984FC20D0DA0c046De5Cc0e8273",
    "chain": "ethereum",
    "chain_id": 1,
    "block": BN,
    "timestamp": TS,
    "timestamp_utc": datetime.fromtimestamp(TS, timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC"),
    "flipper_count": len(clean),
    "active_flippers": sum(1 for x in clean if x["kicks"] > 0),
    "bids_scanned": sum(x["kicks"] for x in clean),
    "flagged_bids": len(flagged),
    "sibling_keepers": 5,
    "sibling_keepers_with_value": 0,
    "other_keeper_contracts": 1,
    "eu_usd": 0,
    "eu_conditional_usd": 0,
    "ho_usd": 35300.75,
    "ho_at_risk_usd": 0,
    "owner_side_vat_usd": 892.04,
    "total_observed_usd": 36192.79,
    "p_usd": 0,
    "s_usd": 0,
    "realized_loss_usd": 538000,
    "confidence": 0.9,
    "evidence_files": ["flippers.json", "keepers.json", "report.md", "bids_scan.json",
                        "vat_state.json", "guys_vat_state.json", "owner_vat_state.json",
                        "attack_receipt.json"],
    "notes": [
        "E-U $0: no unprivileged extraction from any of the 6 family contracts; all hold $0.",
        "E-U-conditional $0: the victim proxy's drain remains ungated and the attacker module still has vat.can over it, so any future Vat credit to the victim is drainable by anyone; none now.",
        "H-O $35,300.75 observed third-party Vat collateral/claims (4 bidders); $0 of it is exposed to the 0x8804d1de drain (owners are EOAs or a non-family keeper with no family hope grants). A further ~$892 is held by the operator/dealer and is not H-O.",
        "P $0 current privileged extraction; dealer EOA owns the ProxyAdmin and could upgrade the victim, but the victim is $0.",
        "S $0 stranded in the family contracts/attacker module.",
        "Realized Oct-6 loss 200 ETH (~$538k); not a current balance.",
    ],
}
json.dump(summary, open("summary.json", "w"), indent=1)
print("wrote flippers.json keepers.json summary.json")
