#!/usr/bin/env python3
"""Keyword/address search for prior coverage across the campaign trackers.
Writes analysis/prior-coverage-matrix.csv (hit counts only, no content dump)."""
import os, glob, csv

TOKENS = {
 "Affluent": ["Affluent"], "Papertrade": ["Papertrade"], "wasmer GHSA": ["wasmer","GHSA-v2h8"],
 "CWA-2026-006": ["CWA-2026-006"], "Premia V3": ["Premia"], "UNCX": ["UNCX"], "Zodiac Roles": ["Zodiac"],
 "Secured Finance": ["Secured Finance"], "Startale 7579": ["Startale"], "TAC JettonProxy": ["TAC","JettonProxy"],
 "zkLink Nova": ["zkLink"], "Notional": ["Notional"], "AtomicQueue": ["AtomicQueue"], "BlueMove": ["BlueMove"],
 "SatoHook": ["SatoHook"], "BSC router": ["0xa331fde0"], "Aperture": ["Aperture"], "Yapeswap": ["Yapeswap"],
 "AlpsCon": ["AlpsCon"], "RNT Lend": ["RNT Lend","RNTLend"], "Neverland": ["Neverland"], "Berafarm": ["BeraFarm","Berafarm"],
 "Sodium": ["Sodium"], "Limit Break": ["Limit Break"], "FWA v2": ["FWA"], "Derive v3": ["Derive"],
 "Prop-AMM": ["BisonFi","GoonFi","AlphaQ","Scorch","Tessera V"], "Sodium 4337": ["Sodium"],
 "GoonFi": ["GoonFi"], "Rain": ["Rain"], "Aquifer": ["Aquifer"], "Raydium": ["Raydium"],
 "anchor-lang": ["anchor-lang"], "Malt": ["MALT"], "Nostra": ["Nostra"], "zkLend": ["zkLend"],
 "X100": ["X100"], "Slice": ["Slice"], "BiFi": ["BiFi"], "UniswapV4Router04": ["UniswapV4Router04"],
 "Tempo": ["Tempo"], "Kamino": ["Kamino"], "Upshift": ["Upshift"], "Onre": ["Onre"],
 "Capyfi": ["Capyfi"], "Venus": ["Venus"], "HyperLend": ["HyperLend"], "WAX": ["WAX"],
 "Troves": ["Troves"], "Polymarket": ["Polymarket"], "Mercado": ["Mercado"], "Predict Fun": ["Predict Fun"],
 "Vara": ["Vara"], "Hifi": ["Hifi"], "b14g": ["b14g"], "Coffer": ["Coffer"],
 "Few-and-Far": ["Few-and-Far"], "PulseX": ["PulseX"], "NEM": ["NEM"], "EtherVista": ["EtherVista"],
 "R25": ["R25"], "SunSwap": ["SunSwap"], "Stellar DeFi Hub": ["Stellar"], "ApolloX": ["ApolloX"],
 "Gambit": ["Gambit"], "Wanchain": ["Wanchain"], "Dano": ["Dano"], "AnetaBTC": ["AnetaBTC"],
}

files = sorted(glob.glob("../ci/*.md")) + sorted(glob.glob("../pass*/README.md"))
roots = sorted([d for d in os.listdir("..") if os.path.isdir(os.path.join("..",d))])

with open("analysis/prior-coverage-matrix.csv","w",newline="") as f:
    w=csv.writer(f); w.writerow(["candidate","tracker_hits","kept_folder_hits"])
    for name, toks in TOKENS.items():
        hits=[]
        for fn in files:
            try: txt=open(fn,errors="replace").read()
            except Exception: continue
            if any(t.lower() in txt.lower() for t in toks): hits.append(os.path.basename(fn))
        folders=[r for r in roots if any(t.lower().replace(" ","_") in r.lower() for t in toks)]
        w.writerow([name,";".join(hits[:8]),";".join(folders[:5])])
print("wrote analysis/prior-coverage-matrix.csv")
