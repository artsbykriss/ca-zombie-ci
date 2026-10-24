const RPCS = [
  "https://api.mainnet-beta.solana.com",
  "https://solana-rpc.publicnode.com",
  "https://solana.drpc.org",
];
let rpcIdx = 0;
async function raw(url, method, params) {
  const res = await fetch(url, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ jsonrpc: "2.0", id: 1, method, params }),
  });
  if (res.status !== 200) { const e = new Error("http " + res.status); e.status = res.status; throw e; }
  const j = await res.json();
  if (j.error) { const e = new Error("rpc " + JSON.stringify(j.error)); e.rpcError = j.error; throw e; }
  return j.result;
}
export async function rpc(method, params, tries = 6) {
  let lastErr;
  for (let i = 0; i < tries; i++) {
    const url = RPCS[rpcIdx % RPCS.length];
    try { return await raw(url, method, params); }
    catch (e) { lastErr = e; rpcIdx++; await new Promise(r => setTimeout(r, 300 * (i + 1))); }
  }
  throw new Error("rpc failed " + method + ": " + (lastErr?.message || lastErr));
}
// try every endpoint until a non-null result is returned
export async function rpcNotNull(method, params, tries = 9) {
  let lastErr, sawNull = false;
  for (let i = 0; i < tries; i++) {
    const url = RPCS[(rpcIdx + i) % RPCS.length];
    try {
      const r = await raw(url, method, params);
      if (r !== null && r !== undefined) return r;
      sawNull = true;
    } catch (e) { lastErr = e; }
    await new Promise(r => setTimeout(r, 250 * (i + 1)));
  }
  if (sawNull) return null;
  throw new Error("rpcNotNull failed " + method + ": " + (lastErr?.message || lastErr));
}
export const sleep = ms => new Promise(r => setTimeout(r, ms));
