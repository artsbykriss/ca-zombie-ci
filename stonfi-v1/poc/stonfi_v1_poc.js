/**
 * STON.fi v1 — consolidated local-TVM PoC (READ-ONLY, in-memory sandbox only).
 *
 * Deploys the DEPLOYED mainnet code (fetched live, keyless endpoints) into @ton/sandbox
 * and runs adversarial probes. No mainnet transactions are ever sent.
 *
 * Tests:
 *  T1  Router pay_to gate: non-pool sender rejected; valid-pool sender accepted.
 *  T2  pTON wallet: every permissionless op reverts; owner ops work.
 *  T3  pTON wallet wrap-path: credited amount is capped by the attached TON
 *      (no fake credit possible).
 *  T4  Getter handlers do not drain contract TON (raw_reserve(0,4) protection).
 *  T5  Fake-notifier pool: a forged transfer_notification credits only the forger's
 *      own side; payout of the real side is bounded by that pool's real reserve.
 */
const { Blockchain, internal } = require("@ton/sandbox");
const { Cell, Address, beginCell, toNano, contractAddress } = require("@ton/core");
const https = require("https");
const fs = require("fs");

const ROUTER = "0:779dcc815138d9500e449c5291e7f12738c23d575b5310000f6a253bd607384e";
const PTON_WALLET = "0:1150b518b2626ad51899f98887f8824b70065456455f7fe2813f012699a4061f";
const USDT_WALLET = "0:4eec921b9d4d56a0d94676016d49c26b39b1d7901a7e153e66033f146a0886f4";
const POOL_ADDR = "0:fc4c9f311160754a99d113877cf583b78e5d16d048819cd4b820168769499d7e";

function fetchJsonOnce(url) {
  return new Promise((res, rej) => https.get(url, { headers: { "User-Agent": "zombie-hunt-research/1.0" } }, (r) => {
    let d = ""; r.on("data", (c) => (d += c)); r.on("end", () => { try { res(JSON.parse(d)); } catch (e) { rej(new Error("bad json")); } });
  }).on("error", rej));
}
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function fetchJson(url, tries = 8) {
  let last;
  for (let i = 0; i < tries; i++) {
    try {
      const j = await fetchJsonOnce(url);
      if (j && (j.accounts || j.last)) return j;
      last = new Error("unexpected body: " + JSON.stringify(j).slice(0, 120));
    } catch (e) { last = e; }
    await sleep(2000 * (i + 1));
  }
  throw last;
}
async function load(addr) {
  const j = await fetchJson(`https://toncenter.com/api/v3/accountStates?address=${addr}&include_boc=true`);
  const a = j.accounts[0];
  return { code: Cell.fromBoc(Buffer.from(a.code_boc, "base64"))[0], data: Cell.fromBoc(Buffer.from(a.data_boc, "base64"))[0], balance: a.balance, code_hash: a.code_hash, data_hash: a.data_hash };
}

const OUT = { head: null, tests: [] };
function record(t, name, data) { t.tests.push({ name, ...data }); }

(async () => {
  const head = await fetchJson("https://toncenter.com/api/v3/masterchainInfo");
  OUT.head = { seqno: head.last.seqno, gen_utime: head.last.gen_utime };

  const bc = await Blockchain.create();
  bc.verbosity = { logs: false, vmLogs: "none", debugLogs: false, blockchainLogs: false };
  const attacker = await bc.treasury("attacker", { balance: toNano("5000000") });
  const A = attacker.address;

  // ---- load live code/data ----
  const routerAcc = await load(ROUTER);
  const ptonAcc = await load(PTON_WALLET);
  const poolAcc = await load(POOL_ADDR);
  OUT.code_hashes = {
    router: routerAcc.code_hash, router_data: routerAcc.data_hash,
    pton_wallet: ptonAcc.code_hash, pton_data: ptonAcc.data_hash,
    pool: poolAcc.code_hash, pool_data: poolAcc.data_hash,
  };

  // ============ T1: router pay_to gate ============
  {
    const t = { router_addr: null, checks: [] };
    const routerAddr = contractAddress(0, { code: routerAcc.code, data: routerAcc.data });
    t.router_addr = routerAddr.toString();
    await attacker.send({ to: routerAddr, value: toNano("4000"), init: { code: routerAcc.code, data: routerAcc.data }, body: beginCell().endCell(), bounce: false });

    const payToBody = (amount0, tok0, amount1, tok1, owner) =>
      beginCell().storeUint(0xf93bb43f, 32).storeUint(0, 64).storeAddress(owner).storeUint(0, 32)
        .storeBit(1)
        .storeRef(beginCell().storeCoins(amount0).storeAddress(tok0).storeCoins(amount1).storeAddress(tok1).endCell())
        .endCell();

    // (a) from attacker (not a pool)
    {
      const r = await bc.sendMessage(internal({ from: A, to: routerAddr, value: toNano("1"),
        body: payToBody(1000n, Address.parseRaw(USDT_WALLET), 0n, Address.parseRaw(PTON_WALLET), A) }));
      const tx = r.transactions.find((x) => x.inMessage?.info?.dest?.equals(routerAddr));
      const c = tx.description.computePhase;
      t.checks.push({ case: "pay_to from non-pool (attacker)", exit: c.type === "vm" ? c.exitCode : c.type, aborted: c.type === "vm" ? !c.success : false, out_msgs: tx.outMessages.size });
    }
    // (b) from the real pool address (pool(token0,token1) computed by the router itself)
    {
      const gm = await bc.runGetMethod(routerAddr, "get_pool_address", [
        { type: "slice", cell: beginCell().storeAddress(Address.parseRaw(USDT_WALLET)).endCell() },
        { type: "slice", cell: beginCell().storeAddress(Address.parseRaw(PTON_WALLET)).endCell() },
      ]);
      const poolAddr = gm.stack[0].cell.beginParse().loadAddress();
      t.computed_pool_for_usdt_pton = poolAddr.toString();
      t.computed_pool_matches_deployed = poolAddr.equals(Address.parseRaw(POOL_ADDR));
      const r = await bc.sendMessage(internal({ from: poolAddr, to: routerAddr, value: toNano("1"),
        body: payToBody(1000n, Address.parseRaw(USDT_WALLET), 0n, Address.parseRaw(PTON_WALLET), A) }));
      const tx = r.transactions.find((x) => x.inMessage?.info?.dest?.equals(routerAddr));
      const c = tx.description.computePhase;
      const outs = [];
      for (const m of tx.outMessages.values()) {
        let dest = null, val = null, op = null;
        try { dest = m.info.dest?.toString(); } catch (e) {}
        try { val = m.info.value.coins.toString(); } catch (e) {}
        try { op = m.body ? "0x" + m.body.beginParse().loadUint(32).toString(16) : null; } catch (e) {}
        outs.push({ dest, value: val, op });
      }
      t.checks.push({ case: "pay_to from valid pool address", exit: c.type === "vm" ? c.exitCode : c.type, aborted: c.type === "vm" ? !c.success : false, out_msgs: tx.outMessages.size, outs });
    }
    record(OUT, "T1_router_pay_to_gate", t);
  }

  // ============ T2/T3: pTON wallet ============
  {
    const t = { wallet_addr: null, permissionless: [], wrap: [] };
    const wAddr = contractAddress(0, { code: ptonAcc.code, data: ptonAcc.data });
    t.wallet_addr = wAddr.toString();
    await attacker.send({ to: wAddr, value: toNano("3900000"), init: { code: ptonAcc.code, data: ptonAcc.data }, body: beginCell().endCell(), bounce: false });
    const R = Address.parseRaw(ROUTER);

    const probe = async (body, value, from) => {
      const r = await bc.sendMessage(internal({ from: from || A, to: wAddr, value, body }));
      const tx = r.transactions.find((x) => x.inMessage?.info?.dest?.equals(wAddr));
      const c = tx.description.computePhase;
      return { exit: c.type === "vm" ? c.exitCode : c.type, aborted: c.type === "vm" ? !c.success : false, out_msgs: tx.outMessages.size };
    };
    // permissionless ops
    const ops = [
      ["ft_transfer 0xf8a7ea5", beginCell().storeUint(0xf8a7ea5, 32).storeUint(0, 64).storeCoins(toNano("1")).storeAddress(A).storeAddress(A).storeBit(0).storeCoins(0).storeBit(0).endCell()],
      ["transfer_notification 0x7362d09c", beginCell().storeUint(0x7362d09c, 32).storeUint(0, 64).storeCoins(toNano("1")).storeAddress(A).storeBit(0).endCell()],
      ["deploy_wallet 0x6cc43573", beginCell().storeUint(0x6cc43573, 32).storeUint(0, 64).storeAddress(A).endCell()],
      ["reset_gas 0x42a0fb43", beginCell().storeUint(0x42a0fb43, 32).storeUint(0, 64).endCell()],
      ["internal_transfer 0x178d4519", beginCell().storeUint(0x178d4519, 32).storeUint(0, 64).storeCoins(toNano("1")).storeAddress(A).storeAddress(A).storeCoins(0).storeBit(0).endCell()],
      ["burn 0x595f07bc", beginCell().storeUint(0x595f07bc, 32).storeUint(0, 64).storeCoins(toNano("1")).storeAddress(A).storeBit(0).endCell()],
      ["unknown 0xdeadbeef", beginCell().storeUint(0xdeadbeef, 32).storeUint(0, 64).endCell()],
    ];
    for (const [name, body] of ops) {
      const res = await probe(body, toNano("1"));
      t.permissionless.push({ op: name, ...res, sent_value_to_attacker: 0 });
    }
    // wrap-path credit formula
    const swapPayload = beginCell().storeUint(0x25938561, 32).storeAddress(Address.parseRaw(USDT_WALLET)).storeCoins(1).storeAddress(A).storeBit(0).endCell();
    const mk = (amt, fwd) => beginCell().storeUint(0xf8a7ea5, 32).storeUint(0, 64).storeCoins(amt).storeAddress(R).storeAddress(A).storeBit(0).storeCoins(fwd).storeBit(1).storeRef(swapPayload).endCell();
    const stored = async () => (await bc.runGetMethod(wAddr, "get_wallet_data")).stack[0].value;
    for (const [claim, value, fwd] of [[toNano("50"), toNano("50.1"), toNano("0.1")], [toNano("50"), toNano("5"), toNano("0.1")], [toNano("1000000"), toNano("0.2"), toNano("0.1")], [toNano("1"), toNano("2"), toNano("0.1")]]) {
      const before = await stored();
      let notifAmt = null, exit = null;
      const r = await bc.sendMessage(internal({ from: A, to: wAddr, value, body: mk(claim, fwd) }));
      for (const tx of r.transactions) {
        if (tx.inMessage?.info?.dest?.equals(wAddr)) { const c = tx.description.computePhase; exit = c.type === "vm" ? c.exitCode : c.type; }
        for (const m of tx.outMessages.values()) {
          if (m.info.dest?.equals(R)) {
            try {
              const s = m.body.beginParse();
              const op = s.loadUint(32);
              notifAmt = { op: "0x" + op.toString(16), body_bits: m.body.bits.length, body_refs: m.body.refs.length };
              if (op === 0x7362d09c) { s.loadUint(64); notifAmt.amount = s.loadCoins().toString(); }
            } catch (e) { notifAmt = "parse_error"; }
          }
        }
      }
      const after = await stored();
      t.wrap.push({ claim: claim.toString(), value: value.toString(), fwd: fwd.toString(), exit, credited: (after - before).toString(), notif_amount: notifAmt === null ? null : notifAmt.toString(), capped_by_value_minus_fwd: notifAmt !== null && notifAmt === (value - fwd < claim ? value - fwd : claim) });
    }
    record(OUT, "T2_T3_pton_wallet", t);
  }

  // ============ T4: getters do not drain ============
  {
    const t = { checks: [] };
    const cases = [
      ["router getter_pool_address 0xd1db969b", routerAcc, beginCell().storeUint(0xd1db969b, 32).storeUint(1, 64).storeAddress(Address.parseRaw(USDT_WALLET)).storeAddress(Address.parseRaw(PTON_WALLET)).endCell(), toNano("4000")],
      ["pool getter_expected_liquidity 0x8751801f", poolAcc, beginCell().storeUint(0x8751801f, 32).storeUint(1, 64).storeCoins(toNano("1")).endCell(), toNano("5300")],
    ];
    for (const [name, acc, body, fund] of cases) {
      const addr = contractAddress(0, { code: acc.code, data: acc.data });
      await attacker.send({ to: addr, value: fund, init: { code: acc.code, data: acc.data }, body: beginCell().endCell(), bounce: false });
      const before = (await bc.getContract(addr)).balance;
      const r = await bc.sendMessage(internal({ from: A, to: addr, value: toNano("1"), body }));
      const after = (await bc.getContract(addr)).balance;
      const tx = r.transactions.find((x) => x.inMessage?.info?.dest?.equals(addr));
      const outs = [];
      for (const m of tx.outMessages.values()) { let v = null, dest = null; try { v = m.info.value.coins.toString(); } catch (e) {} try { dest = m.info.dest?.toString(); } catch (e) {} outs.push({ dest, value: v }); }
      t.checks.push({ name, contract_balance_before: before.toString(), contract_balance_after: after.toString(), balance_change: (after - before).toString(), reply_msgs: outs });
    }
    record(OUT, "T4_getters_no_drain", t);
  }

  // ============ T5: fake-notifier credit only lands on forger's side ============
  {
    const t = { pool_addr: null, checks: [] };
    const FAKE = Address.parseRaw("0:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
    // compute the pool address for (FAKE, USDT_wallet) via the router's getter (real router instance)
    const routerAddr = contractAddress(0, { code: routerAcc.code, data: routerAcc.data });
    const gm = await bc.runGetMethod(routerAddr, "get_pool_address", [
      { type: "slice", cell: beginCell().storeAddress(FAKE).endCell() },
      { type: "slice", cell: beginCell().storeAddress(Address.parseRaw(USDT_WALLET)).endCell() },
    ]);
    const fakePoolAddr = gm.stack[0].cell.beginParse().loadAddress();
    t.pool_addr = fakePoolAddr.toString();
    // deploy the REAL pool code at that address (state init with zero reserves, as the router expects)
    // build the pool state init exactly like pack_pool_data does
    const rd = await bc.runGetMethod(routerAddr, "get_router_data");
    const poolCode = rd.stack[3].cell;
    const lpWalletCode = rd.stack[4].cell;
    const lpAccountCode = rd.stack[5].cell;
    // NOTE: deploying via init requires the exact state init; we instead deploy the pool by sending
    // a message with the state init built the same way the router builds it.
    // pack_pool_data(token0=maxhash, token1=minhash, ...)
    const packPool = (t0, t1) => {
      const b = beginCell();
      b.storeAddress(routerAddr); b.storeUint(20, 8); b.storeUint(10, 8); b.storeUint(10, 8);
      b.storeAddress(t0); b.storeAddress(t1); b.storeCoins(0);
      const inner = beginCell();
      inner.storeCoins(0); inner.storeCoins(0);
      inner.storeAddress(Address.parseRaw("0:0000000000000000000000000000000000000000000000000000000000000000"));
      inner.storeCoins(0); inner.storeCoins(0);
      b.storeRef(inner.endCell()); b.storeRef(lpWalletCode); b.storeRef(lpAccountCode);
      return b.endCell();
    };
    const si = (code, data) => beginCell().storeBit(0).storeBit(0).storeMaybeRef(code).storeMaybeRef(data).storeBit(0).endCell();
    const h0 = BigInt("0x" + FAKE.hash.toString("hex"));
    const h1 = BigInt("0x" + Address.parseRaw(USDT_WALLET).hash.toString("hex"));
    const [t0, t1] = h0 > h1 ? [FAKE, Address.parseRaw(USDT_WALLET)] : [Address.parseRaw(USDT_WALLET), FAKE];
    const poolData = packPool(t0, t1);
    const poolInit = si(poolCode, poolData);
    t.state_init_matches_router_computed_pool = poolInit.hash().equals(fakePoolAddr.hash);
    await attacker.send({ to: fakePoolAddr, value: toNano("100"), init: { code: poolCode, data: poolData }, body: beginCell().endCell(), bounce: false });
    t.pool_deployed = true;
    // forged transfer_notification from FAKE claiming a huge amount, swap payload for USDT out
    const payload = beginCell().storeUint(0x25938561, 32).storeAddress(Address.parseRaw(USDT_WALLET)).storeCoins(1).storeAddress(A).storeBit(0).endCell();
    const notif = beginCell().storeUint(0x7362d09c, 32).storeUint(1, 64).storeCoins(10n ** 18n).storeAddress(A).storeBit(1).storeRef(payload).endCell();
    const r = await bc.sendMessage(internal({ from: FAKE, to: routerAddr, value: toNano("1"), body: notif }));
    const txR = r.transactions.find((x) => x.inMessage?.info?.dest?.equals(routerAddr));
    const txP = r.transactions.find((x) => x.inMessage?.info?.dest?.equals(fakePoolAddr));
    t.checks.push({ router_exit: txR ? (txR.description.computePhase.type === "vm" ? txR.description.computePhase.exitCode : txR.description.computePhase.type) : "no-tx",
      router_out_msgs: txR ? txR.outMessages.size : 0,
      pool_exit: txP ? (txP.description.computePhase.type === "vm" ? txP.description.computePhase.exitCode : txP.description.computePhase.type) : "no-tx" });
    // decode the pool's outgoing pay_to: which token address did the forged amount land on?
    if (txP) {
      for (const m of txP.outMessages.values()) {
        try {
          const s = m.body.beginParse();
          const op = s.loadUint(32);
          if (op === 0xf93bb43f) {
            s.loadUint(64);
            const owner = s.loadAddress();
            s.loadUint(32);
            s.loadBit();
            const ref = s.loadRef().beginParse();
            const a0 = ref.loadCoins(); const t0a = ref.loadAddress(); const a1 = ref.loadCoins(); const t1a = ref.loadAddress();
            t.checks.push({ pool_pay_to: { owner: owner.toString(), amount0_out: a0.toString(), token0_address: t0a.toString(),
              amount1_out: a1.toString(), token1_address: t1a.toString(),
              fake_side_credited: (t0a.equals(FAKE) && a0 > 0n) || (t1a.equals(FAKE) && a1 > 0n),
              usdt_side_credited: (t0a.equals(Address.parseRaw(USDT_WALLET)) && a0 > 0n) || (t1a.equals(Address.parseRaw(USDT_WALLET)) && a1 > 0n) } });
          }
        } catch (e) { /* ignore */ }
      }
    }
    // read the pool's reserves before/after
    const pd = await bc.runGetMethod(fakePoolAddr, "get_pool_data");
    t.pool_data_after = pd.stack.map((x) => (x.value && x.value.toString ? x.value.toString() : String(x.value))).slice(0, 2);
    record(OUT, "T5_fake_notifier_pool", t);
  }

  const outPath = process.env.POC_OUT || "./ci-out/stonfi_v1_poc.json";
  fs.mkdirSync(require("path").dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, JSON.stringify(OUT, null, 1));
  console.log(JSON.stringify(OUT, null, 1));
})().catch((e) => { console.error("FATAL", e && e.stack ? e.stack : e); process.exit(1); });
