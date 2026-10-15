/**
 * STON.fi v1 pTON wallet — local TVM sandbox behavioral probe v2 (READ-ONLY, local only).
 * Funds the deployed wallet above its stored pTON balance so reserve actions succeed.
 */
const { Blockchain, internal } = require("@ton/sandbox");
const { Cell, Address, beginCell, toNano, contractAddress } = require("@ton/core");
const https = require("https");
const fs = require("fs");

const PTON_WALLET = "0:1150b518b2626ad51899f98887f8824b70065456455f7fe2813f012699a4061f";
const ROUTER = "0:779dcc815138d9500e449c5291e7f12738c23d575b5310000f6a253bd607384e";

function fetchJson(url) {
  return new Promise((res, rej) =>
    https.get(url, { headers: { "User-Agent": "zombie-hunt-research/1.0" } }, (r) => {
      let d = ""; r.on("data", (c) => (d += c));
      r.on("end", () => { try { res(JSON.parse(d)); } catch (e) { rej(new Error("bad json")); } });
    }).on("error", rej));
}

async function main() {
  const st = await fetchJson(`https://toncenter.com/api/v3/accountStates?address=${PTON_WALLET}&include_boc=true`);
  const acc = st.accounts[0];
  const code = Cell.fromBoc(Buffer.from(acc.code_boc, "base64"))[0];
  const data = Cell.fromBoc(Buffer.from(acc.data_boc, "base64"))[0];
  console.log("code hash:", code.hash().toString("hex"), "| data hash:", data.hash().toString("hex"));

  const bc = await Blockchain.create();
  bc.verbosity = { logs: false, vmLogs: "none", debugLogs: false, blockchainLogs: false };

  const attacker = await bc.treasury("attacker", { balance: toNano("4000000") });
  const attackerAddr = attacker.address;
  const walletAddr = contractAddress(0, { code, data }); // current state-init address (state mutated since deploy)
  const routerAddr = Address.parseRaw(ROUTER);

  // deploy the real wallet with the real code+data, funded above the stored pTON balance
  await attacker.send({
    to: walletAddr, value: toNano("3900000"), init: { code, data },
    body: beginCell().endCell(), bounce: false,
  });
  const wc = await bc.getContract(walletAddr);
  console.log("wallet balance:", wc.balance.toString());
  try {
    const gw = await bc.runGetMethod(walletAddr, "get_wallet_data");
    console.log("get_wallet_data stack:", gw.stack.map(x => x.value && x.value.toString ? x.value.toString().slice(0, 80) : String(x.value)).join(" | "));
  } catch (e) { console.log("get_wallet_data failed:", String(e).slice(0, 200)); }

  const results = [];
  async function probe(name, body, opts = {}) {
    const value = opts.value || toNano("1");
    const from = opts.from || attackerAddr;
    let txs = [];
    try {
      const r = await bc.sendMessage(internal({ from, to: walletAddr, value, body, bounce: opts.bounce !== false }));
      txs = r.transactions;
    } catch (e) { results.push({ name, error: String(e).slice(0, 200) }); return; }
    const info = [];
    for (const t of txs) {
      const d = t.description;
      const compute = d.computePhase;
      const outMsgs = [];
      for (const m of t.outMessages.values()) {
        let op = null, dest = null, val = null;
        try { dest = m.info.dest ? m.info.dest.toString() : null; } catch (e) {}
        try { val = m.info.value.coins.toString(); } catch (e) {}
        try { op = m.body ? "0x" + m.body.beginParse().loadUint(32).toString(16) : null; } catch (e) { op = "noparse"; }
        outMsgs.push({ dest, value: val, op, bodyB64: m.body ? m.body.toBoc().toString("base64") : null });
      }
      info.push({
        from: t.inMessage && t.inMessage.info.src ? t.inMessage.info.src.toString() : null,
        to: t.inMessage && t.inMessage.info.dest ? t.inMessage.info.dest.toString() : null,
        exitCode: compute && compute.type === "vm" ? compute.exitCode : (compute ? compute.type : "none"),
        aborted: compute && compute.type === "vm" ? !compute.success : false,
        outMsgs,
      });
    }
    results.push({ name, value: value.toString(), txs: info });
    return txs;
  }

  // ---- probes (permissionless, from attacker) ----
  await probe("empty_body", beginCell().endCell(), { value: toNano("0.1") });

  await probe("ft_transfer_from_attacker",
    beginCell().storeUint(0xf8a7ea5, 32).storeUint(0, 64).storeCoins(toNano("1"))
      .storeAddress(attackerAddr).storeAddress(attackerAddr).storeBit(0).storeCoins(0).storeBit(0).endCell());

  await probe("transfer_notification_from_attacker",
    beginCell().storeUint(0x7362d09c, 32).storeUint(0, 64).storeCoins(toNano("1")).storeAddress(attackerAddr).storeBit(0).endCell());

  await probe("deploy_wallet_from_attacker",
    beginCell().storeUint(0x6cc43573, 32).storeUint(0, 64).storeAddress(attackerAddr).endCell());

  await probe("unknown_op", beginCell().storeUint(0xdeadbeef, 32).storeUint(0, 64).endCell());

  await probe("reset_gas_from_attacker", beginCell().storeUint(0x42a0fb43, 32).storeUint(0, 64).endCell());

  await probe("ton_transfer_tep161_from_attacker",
    beginCell().storeUint(0x1f3835d, 32).storeUint(0, 64).storeCoins(toNano("1")).storeAddress(attackerAddr).storeBit(0).endCell());

  // internal_transfer (standard jetton) from attacker
  await probe("internal_transfer_from_attacker",
    beginCell().storeUint(0x178d4519, 32).storeUint(0, 64).storeCoins(toNano("1"))
      .storeAddress(attackerAddr).storeAddress(attackerAddr).storeCoins(0).storeBit(0).endCell());

  // burn (standard jetton) from attacker
  await probe("burn_from_attacker",
    beginCell().storeUint(0x595f07bc, 32).storeUint(0, 64).storeCoins(toNano("1")).storeAddress(attackerAddr).storeBit(0).endCell());

  // ---- owner paths (from router address) ----
  await probe("ft_transfer_from_owner_router",
    beginCell().storeUint(0xf8a7ea5, 32).storeUint(0, 64).storeCoins(toNano("1"))
      .storeAddress(attackerAddr).storeAddress(attackerAddr).storeBit(0).storeCoins(0).storeBit(0).endCell(),
    { from: routerAddr, value: toNano("1") });

  await probe("reset_gas_from_owner_router", beginCell().storeUint(0x42a0fb43, 32).storeUint(0, 64).endCell(),
    { from: routerAddr, value: toNano("0.05") });

  console.log(JSON.stringify(results, null, 1));
  fs.writeFileSync("/home/heisenberg/CA/stonfi-v1/analysis/pton_wallet_probe2.json",
    JSON.stringify({ code_hash: code.hash().toString("hex"), data_hash: data.hash().toString("hex"), results }, null, 1));
}
main().catch((e) => { console.error("FATAL", e); process.exit(1); });
