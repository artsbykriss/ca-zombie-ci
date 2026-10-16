#!/usr/bin/env python3
"""Minimal Solana JSON-RPC helper (read-only, local use only).

Key hygiene: the file itself only contains KEYLESS public endpoints. If run locally,
it may read ALCHEMY_API_KEY from /home/heisenberg/CA/.env at runtime for reliability;
the keyed URL is never written to any file or printed.
In CI, set SOLANA_RPC_URL (keyless) or use the public fallbacks.
"""
import json, os, sys, time, urllib.request

PUBLIC = "https://solana-rpc.publicnode.com"
FALLBACKS = ["https://api.mainnet-beta.solana.com", "https://solana-rpc.publicnode.com"]
ENV_FILE = "/home/heisenberg/CA/.env"


def _env(name):
    try:
        with open(ENV_FILE) as f:
            for line in f:
                if line.startswith(name + "="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")
    except FileNotFoundError:
        pass
    return os.environ.get(name)


def get_url():
    """Keyless endpoints only. This file is synced to a PUBLIC repo: never add
    keyed URL construction here. For local runs, export SOLANA_RPC_URL in the shell."""
    return os.environ.get("SOLANA_RPC_URL", PUBLIC)


def rpc(method, params, retries=6, url=None):
    url = url or get_url()
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for attempt in range(retries):
        try:
            req = urllib.request.Request(
                url, data=payload,
                headers={"Content-Type": "application/json", "User-Agent": "zombie-research/1.0"})
            with urllib.request.urlopen(req, timeout=90) as r:
                out = json.loads(r.read())
            if "error" in out:
                e = out["error"]
                if e.get("code") in (429, -32005) or "rate" in str(e).lower():
                    time.sleep(1.2 * (attempt + 1)); last = e; continue
                return out
            return out
        except Exception as ex:  # noqa: BLE001
            last = str(ex); time.sleep(1.0 * (attempt + 1))
    return {"error": {"code": -1, "message": f"rpc failed: {last}"}}


def b64_to_bytes(s):
    import base64
    return base64.b64decode(s)


if __name__ == "__main__":
    method = sys.argv[1]
    params = json.loads(sys.argv[2]) if len(sys.argv) > 2 else []
    print(json.dumps(rpc(method, params), indent=1))
