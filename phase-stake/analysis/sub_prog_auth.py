#!/usr/bin/env python3
"""Upgrade authorities of all programs interacting with the Phase pool (standard RPC reads)."""
import json, sys, time, base64
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import rpc, b58encode, b58decode, on_curve

PROGS = {
    "1oopBoJG58Dg(unknown-Loopscale?)": "1oopBoJG58DgkUVKkEzKgyG9dvRmpgeEm1AVjoHkF78",
    "2rU1oCHtQ7WJ(unknown)": "2rU1oCHtQ7WJUvy15tKtFvxdYNNSc3id7AzUcjeFSddo",
    "8F2VM13kdMBa(unknown)": "8F2VM13kdMBaHtcXPHmArtLueg7rfsa3gnrgGjAy4oCu",
    "DRVSpZ2YUY(unknown)": "DRVSpZ2YUYYKgZP8XtLhAGtT1zYSCKzeHfb4DgRnrgqD",
    "DeintXmrdZFg(unknown)": "DeintXmrdZFgSKzEWcJWhK793HuqnfDydAPvHmayY5Xz",
    "FLUX6xBayG(unknown)": "FLUX6xBayGxLX9UcimVRxXFMHH6q43mAbRvDzSpCsvfK",
    "HpNfyc2Saw(pancake-clmm)": "HpNfyc2Saw7RKkQd8nEL4khUcuPhQ7WwY1B2qjx8jxFq",
    "T1TANpTeSc(unknown)": "T1TANpTeScyeqVzzgNViGDNrkQ6qHz9KrSBS4aNXvGT",
    "SPMBzs(multi stake pool)": "SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn",
    "SPoo1Ku8(spl stake pool)": "SPoo1Ku8WFXoNDMHPsrGSTSG1Y47rzgn41SLUNakuHy",
    "stkitr(sanctum router)": "stkitrT1Uoy18Dk1fTrgPw8W6MVzoCfYoAFT4MLsmhq",
    "5ocnV1qiCg(sanctum controller)": "5ocnV1qiCgaQR8Jb8xWnVbApfaygJ8tNoZfgPwsgx9kx",
    "SQDS4ep65T(squads v4)": "SQDS4ep65T869zMMBKyuUq6aD6EgTu8psMjkvj52pCf",
}

out = {}
for name, pid in PROGS.items():
    rec = {"program": pid}
    time.sleep(1.2)
    try:
        r = rpc("getAccountInfo", [pid, {"encoding": "base64"}])
        v = r["value"]
        if v is None:
            rec["exists"] = False
        else:
            rec["exists"] = True
            rec["executable"] = v["executable"]
            data = base64.b64decode(v["data"][0]) if v["data"] else b""
            rec["datalen"] = len(data)
            if len(data) >= 36 and data[0] == 2:
                pd_addr = b58encode(data[4:36])
                rec["programdata"] = pd_addr
                time.sleep(1.2)
                r2 = rpc("getAccountInfo", [pd_addr, {"encoding": "base64"}])
                v2 = r2["value"]
                if v2:
                    d2 = base64.b64decode(v2["data"][0]) if v2["data"] else b""
                    rec["pd_datalen"] = len(d2)
                    if len(d2) >= 45 and d2[0] == 3:
                        rec["last_deploy_slot"] = int.from_bytes(d2[4:12], "little")
                        has_auth = d2[12]
                        if has_auth == 1 and len(d2) >= 45:
                            auth = b58encode(d2[13:45])
                            rec["upgrade_authority"] = auth
                            rec["auth_on_curve"] = on_curve(b58decode(auth))
                        else:
                            rec["upgrade_authority"] = None
    except Exception as e:
        rec["error"] = str(e)[:160]
    out[name] = rec
    print(name, json.dumps(rec))

json.dump(out, open("/home/heisenberg/CA/phase-stake/analysis/program_authorities.json", "w"), indent=2)
