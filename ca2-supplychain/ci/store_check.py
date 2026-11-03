#!/usr/bin/env python3
"""Fearless Wallet supply-chain checks (read-only).

Verifies:
  * the current Chrome Web Store CRX (manifest version, source commit,
    presence of 'tonscanner' / 'whitelist?address')
  * the remote switch file on the public GitHub branch
  * the 3.0.5 source file (tonscanner hardcoded)
  * DNS for tonscanner.org (Google DoH) and TCP reachability
  * Firefox AMO listing status
No execution of the extension, no keys, no transactions.
"""
import io, json, socket, struct, time, zipfile
import requests

S = requests.Session()
S.headers.update({"User-Agent": "ca2-supplychain-research/1.0"})

CRX_URL = ("https://clients2.google.com/service/update2/crx?"
           "response=redirect&os=linux&arch=x86_64&os_arch=x86_64&nacl_arch=x86-64"
           "&prod=chromium&prodchannel=unknown&prodversion=131.0"
           "&acceptformat=crx2,crx3&x=id%3Dnhlnehondigmgckngjomcpcefcdplmgc%26uc")
CONFIG_URL = "https://raw.githubusercontent.com/soramitsu/shared-features-utils/eth-enabled/appConfigs/web_config.json"
SRC_305 = ("https://raw.githubusercontent.com/soramitsu/fearless-wallet-web/"
           "129807f0deff4b1cd028b4152084b66d5de77f58/src/extension/background/"
           "extension-base/src/services/balance/TonBalanceService.ts")

def get(url, tries=4, timeout=45, **kw):
    last = None
    for i in range(tries):
        try:
            r = S.get(url, timeout=timeout, **kw)
            r.raise_for_status()
            return r
        except Exception as e:
            last = e
            time.sleep(2 + i * 2)
    raise last

def crx_check():
    out = {"url": CRX_URL}
    try:
        r = get(CRX_URL, timeout=120)
        b = r.content
        out["http_status"] = r.status_code
        out["bytes"] = len(b)
        if b[:4] != b"Cr24":
            out["error"] = "not a CRX"
            return out
        ver = struct.unpack("<I", b[4:8])[0]
        if ver == 3:
            hl = struct.unpack("<I", b[8:12])[0]
            off = 12 + hl
        else:
            pk = struct.unpack("<I", b[8:12])[0]
            sig = struct.unpack("<I", b[12:16])[0]
            off = 16 + pk + sig
        z = zipfile.ZipFile(io.BytesIO(b[off:]))
        m = json.loads(z.read("manifest.json"))
        out["manifest_version"] = m.get("version")
        out["manifest_name"] = m.get("name")
        hits = []
        for n in z.namelist():
            try:
                d = z.read(n)
                low = d.lower()
                if b"tonscanner" in low or b"whitelist?address" in low:
                    hits.append(n)
            except Exception:
                pass
        out["tonscanner_hits"] = hits
        try:
            meta = json.loads(z.read("extension-build-metadata.json"))
            out["sourceCommit"] = meta.get("sourceCommit")
            out["build_browser"] = meta.get("browser")
        except Exception:
            out["sourceCommit"] = None
    except Exception as e:
        out["error"] = f"{type(e).__name__}: {e}"
    return out

def config_check():
    out = {"url": CONFIG_URL}
    try:
        r = get(CONFIG_URL)
        j = r.json()
        out["http_status"] = r.status_code
        out["json"] = j
        out["ton_present"] = "ton" in j
        out["switch_on"] = bool(j.get("ton"))
    except Exception as e:
        out["error"] = f"{type(e).__name__}: {e}"
    return out

def source_check():
    out = {"url": SRC_305}
    try:
        t = get(SRC_305).text
        out["bytes"] = len(t)
        out["tonscanner_present"] = "tonscanner.org" in t
        out["whitelist_present"] = "whitelist?address" in t
    except Exception as e:
        out["error"] = f"{type(e).__name__}: {e}"
    return out

def dns_check():
    out = {"doh": "https://dns.google/resolve?name=tonscanner.org&type=A", "a_records": []}
    try:
        r = get("https://dns.google/resolve?name=tonscanner.org&type=A")
        j = r.json()
        out["status"] = j.get("Status")
        out["a_records"] = [a.get("data") for a in j.get("Answer", []) if a.get("type") == 1]
    except Exception as e:
        out["error"] = f"{type(e).__name__}: {e}"
    out["tcp_443"] = []
    for ip in out["a_records"]:
        rec = {"ip": ip, "connected": False}
        try:
            s = socket.create_connection((ip, 443), timeout=8)
            s.close()
            rec["connected"] = True
        except Exception as e:
            rec["error"] = f"{type(e).__name__}: {e}"
        out["tcp_443"].append(rec)
    return out

def amo_check():
    out = {"url": "https://addons.mozilla.org/api/v5/addons/addon/fearless-wallet/"}
    try:
        r = S.get(out["url"], timeout=30)
        out["http_status"] = r.status_code
        try:
            j = r.json()
            out["detail"] = j.get("detail")
            out["is_disabled_by_developer"] = j.get("is_disabled_by_developer")
            out["is_disabled_by_mozilla"] = j.get("is_disabled_by_mozilla")
        except Exception:
            out["body"] = r.text[:300]
    except Exception as e:
        out["error"] = f"{type(e).__name__}: {e}"
    return out

def main():
    out = {
        "checked_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "crx": crx_check(),
        "remote_switch": config_check(),
        "source_305": source_check(),
        "dns": dns_check(),
        "firefox_amo": amo_check(),
    }
    print(json.dumps(out, indent=2, sort_keys=True))

if __name__ == "__main__":
    main()
