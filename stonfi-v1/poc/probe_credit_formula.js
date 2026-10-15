/**
 * Pin down the v1 pTON wallet wrap-path credit formula.
 * For each (claim, msg_value, fwd) combo: read stored balance before/after and decode
 * the notification amount sent to the router.
 */
const { Blockchain, internal } = require("@ton/sandbox");
const { Cell, Address, beginCell, toNano, contractAddress } = require("@ton/core");
const https = require("https");
const fs = require("fs");

const PTON_WALLET = "0:1150b518b2626ad51899f98887f8824b70065456455f7fe2813f012699a4061f";
const ROUTER = "0:779dcc815138d9500e449c5291e7f12738c23d575b5310000f6a253bd607384e";
function fetchJson(url) { return new Promise((res, rej) => https.get(url, { headers: { "User-Agent": "x" } }, (r) => { let d = ""; r.on("data", c => d += c); r.on("end", () => res(JSON.parse(d))); }).on("error", rej)); }

(async () => {
  const st = await fetchJson(`https://toncenter.com/api/v3/accountStates?address=${PTON_WALLET}&include_boc=true`);
  const acc = st.accounts[0];
  const code = Cell.fromBoc(Buffer.from(acc.code_boc, "base64"))[0];
  const data = Cell.fromBoc(Buffer.from(acc.data_boc, "base64"))[0];
  const bc = await Blockchain.create();
  bc.verbosity = { logs: false, vmLogs: "none", debugLogs: false, blockchainLogs: false };
  const attacker = await bc.treasury("attacker", { balance: toNano("4000000") });
  const walletAddr = contractAddress(0, { code, data });
  await attacker.send({ to: walletAddr, value: toNano("3900000"), init: { code, data }, body: beginCell().endCell(), bounce: false });
  const A = attacker.address;
  const R = Address.parseRaw(ROUTER);
  const USDT_WALLET = Address.parseRaw("0:4eec921b9d4d56a0d94676016d49c26b39b1d7901a7e153e66033f146a0886f4");
  const swapPayload = beginCell().storeUint(0x25938561, 32).storeAddress(USDT_WALLET).storeCoins(1).storeAddress(A).storeBit(0).endCell();

  async function storedBalance() {
    const r = await bc.runGetMethod(walletAddr, "get_wallet_data");
    return r.stack[0].value;
  }
  const mkBody = (amt, fwd) => beginCell().storeUint(0xf8a7ea5, 32).storeUint(0, 64).storeCoins(amt)
    .storeAddress(R).storeAddress(A).storeBit(0).storeCoins(fwd).storeBit(1).storeRef(swapPayload).endCell();

  const rows = [];
  const combos = [
    ["claim 50, value 50.1, fwd 0.1", toNano("50"), toNano("50.1"), toNano("0.1")],
    ["claim 50, value 5, fwd 0.1", toNano("50"), toNano("5"), toNano("0.1")],
    ["claim 50, value 5, fwd 0", toNano("50"), toNano("5"), 0n],
    ["claim 0.05, value 0.2, fwd 0.1", toNano("0.05"), toNano("0.2"), toNano("0.1")],
    ["claim 1, value 1.1, fwd 0.1", toNano("1"), toNano("1.1"), toNano("0.1")],
    ["claim 1, value 2, fwd 0.1", toNano("1"), toNano("2"), toNano("0.1")],
    ["claim 0.5, value 0.5, fwd 0", toNano("0.5"), toNano("0.5"), 0n],
  ];
  for (const [name, claim, value, fwd] of combos) {
    const before = await storedBalance();
    let notifAmt = null, exit = null;
    try {
      const r = await bc.sendMessage(internal({ from: A, to: walletAddr, value, body: mkBody(claim, fwd) }));
      for (const t of r.transactions) {
        const c = t.description.computePhase;
        if (t.inMessage?.info?.dest?.equals(walletAddr)) exit = c.type === "vm" ? c.exitCode : c.type;
        for (const m of t.outMessages.values()) {
          if (m.info.dest?.equals(R)) {
            const s = m.body.beginParse(); s.loadUint(32); s.loadUint(64); notifAmt = s.loadCoins();
          }
        }
      }
    } catch (e) { exit = "err:" + String(e).slice(0, 60); }
    const after = await storedBalance();
    rows.push({ name, claim: claim.toString(), value: value.toString(), fwd: fwd.toString(),
      exit, credited_delta: (after - before).toString(), notif_amount: notifAmt === null ? null : notifAmt.toString() });
    console.log(JSON.stringify(rows[rows.length - 1]));
  }
  fs.writeFileSync("/home/heisenberg/CA/stonfi-v1/analysis/pton_credit_formula.json", JSON.stringify({ code_hash: code.hash().toString("hex"), rows }, null, 1));
})().catch(e => { console.error("FATAL", e); process.exit(1); });
