'use strict';
/*
 * STON.fi V2 (TON) — bytecode-level, read-only sandbox PoC.
 *
 * The code cells used here are the outputs of building github.com/ston-fi/dex-core-v2
 * at commit af0a955cc835af9697cd383e201fefcbe1a6a87e ("bump v2.2"), dexType=constant_product,
 * defaults lp_fee=20 / protocol_fee=10 / unlocked. Their sha256 hashes equal the 256-bit
 * library hashes embedded in the live accounts' code cells (PUBLIB), i.e. they ARE the
 * deployed code:
 *   router 848d1da9f94d125219685290a670a23573a3ff671dfe3c04b7aa8832c6a4f5cc
 *   pool   a9338ecd624ca15d37e4a8d9bf677ddc9b84f0e98f05f2fb84c7afe332a281b4
 *
 * State (data) cells are the live on-chain account data, fetched from toncenter at
 * last_transaction_lt 111448125000013 (router) / ...011 (pool), 2026-10-21.
 *
 * No network writes, no keys, no broadcasts. Everything runs in @ton/sandbox.
 */
const fs = require('fs');
const path = require('path');
const { Cell, beginCell, Address, contractAddress, toNano } = require('@ton/core');
const { Blockchain, internal: rawInternal } = require('@ton/sandbox');
const internal = (p) => rawInternal({ bounce: false, ...p });

const ART = JSON.parse(fs.readFileSync(path.join(__dirname, 'artifacts', 'deployed_artifacts.json'), 'utf8'));

const OP = {
  pay_to: 0x657b54f5,
  swap: 0x6664de2a,
  transfer_notification: 0x7362d09c,
  internal_transfer: 0x178d4519,
  internal_set_fees: 0x75930d63,
  internal_update_status: 0x62752512,
  swap_refund_slippage: 0x39603190,
  swap_refund_tx_expired: 0x1ec28412,
  swap_refund_reserve_err: 0x38976e9b,
  swap_refund_no_liq: 0x5ffe1295,
  swap_refund_0_out: 0x5f954434,
  swap_ok: 0xc64370e5, // crc32("swap_ok")
};

const results = [];
function check(name, cond, detail) {
  results.push({ name, pass: !!cond, detail: detail || '' });
  console.log(`${cond ? 'PASS' : 'FAIL'}  ${name}${detail ? '  :: ' + detail : ''}`);
}
function txExit(tx) {
  const d = tx.description;
  const c = d.computePhase;
  if (!c || c.type !== 'vm') return { exit: null, aborted: true, actions: d.actionPhase };
  return { exit: c.exitCode, success: c.success, aborted: !c.success, actions: d.actionPhase };
}
function findTx(res, to) {
  return res.transactions.find((t) => t.inMessage && t.inMessage.info.dest && t.inMessage.info.dest.equals(to));
}
function outMsgs(tx) {
  return [...tx.outMessages.values()];
}

(async () => {
  const routerCode = Cell.fromBoc(Buffer.from(ART.router.code_b64, 'base64'))[0];
  const poolCode = Cell.fromBoc(Buffer.from(ART.pool.code_b64, 'base64'))[0];
  const routerData = Cell.fromBoc(Buffer.from(ART.router.data_b64, 'base64'))[0];
  const poolData = Cell.fromBoc(Buffer.from(ART.pool.data_b64, 'base64'))[0];

  // ---- 0. artifact integrity: built code == deployed code (PUBLIB library hash) ----
  check('router build hash == on-chain library hash', routerCode.hash().toString('hex') === ART.router.code_hash,
    routerCode.hash().toString('hex'));
  check('pool build hash == on-chain library hash', poolCode.hash().toString('hex') === ART.pool.code_hash,
    poolCode.hash().toString('hex'));

  // Live accounts store code as a PUBLIB library *reference* cell, which @ton/sandbox cannot
  // resolve. We therefore redeploy the byte-identical resolved code at fresh addresses, keeping
  // the live dynamic state (reserves, fees, LP supply) and only rebinding the pool's router field.
  // Rebind the router's pool_code reference from the PUBLIB cell to the resolved code cell so that
  // the address it derives for a pool equals the address the sandbox can actually execute.
  const rds = routerData.beginParse();
  const rLocked = rds.loadBit();
  const rAdmin = rds.loadAddress();
  const rTemp = rds.loadRef();
  const rStatic = rds.loadRef().beginParse();
  const rId = rStatic.loadUintBig(64);
  const rLpW = rStatic.loadRef(), _rPoolCode = rStatic.loadRef(), rLpA = rStatic.loadRef(), rVault = rStatic.loadRef();
  const rUpgrade = rds.loadRef();
  const newRStatic = beginCell().storeUint(rId, 64).storeRef(rLpW).storeRef(poolCode).storeRef(rLpA).storeRef(rVault).endCell();
  const routerData2 = beginCell().storeBit(rLocked).storeAddress(rAdmin).storeRef(rTemp).storeRef(newRStatic).storeRef(rUpgrade).endCell();
  const ROUTER = contractAddress(0, { code: routerCode, data: routerData2 });

  const ds = poolData.beginParse();
  const isLocked = ds.loadBit();
  const c0 = ds.loadCoins(), c1 = ds.loadCoins(), c2 = ds.loadCoins(), c3 = ds.loadCoins(), c4 = ds.loadCoins();
  const pfAddr = ds.loadAddress();
  const lpFee = ds.loadUint(16), pfFee = ds.loadUint(16);
  const st = ds.loadRef().beginParse();
  st.loadAddress(); // static[0] = router_address (rebound below)
  const tk0 = st.loadAddress(), tk1 = st.loadAddress();
  const lpW = st.loadRef(), lpA = st.loadRef();
  const newStatic = beginCell().storeAddress(ROUTER).storeAddress(tk0).storeAddress(tk1).storeRef(lpW).storeRef(lpA).endCell();
  const poolData2 = beginCell().storeBit(isLocked).storeCoins(c0).storeCoins(c1).storeCoins(c2)
    .storeCoins(c3).storeCoins(c4).storeAddress(pfAddr).storeUint(lpFee, 16).storeUint(pfFee, 16)
    .storeRef(newStatic).endCell();
  const POOL = contractAddress(0, { code: poolCode, data: poolData2 });
  // The canonical pool address is derived from the pool's *initial* data (default 20/10, zero reserves).
  const initialPoolData = beginCell().storeBit(false).storeCoins(0).storeCoins(0).storeCoins(0).storeCoins(0).storeCoins(0)
    .storeAddress(null).storeUint(20, 16).storeUint(10, 16).storeRef(newStatic).endCell();
  const POOL_INIT = contractAddress(0, { code: poolCode, data: initialPoolData });
  console.log(`sandbox router=${ROUTER.toString()} pool(live-state)=${POOL.toString()} pool(canonical)=${POOL_INIT.toString()}`);

  const bc = await Blockchain.create();
  bc.now = Math.floor(Date.now() / 1000);
  const deployer = await bc.treasury('deployer');
  const attacker = await bc.treasury('attacker');

  await bc.sendMessage(internal({ from: deployer.address, to: ROUTER, value: toNano('5'), stateInit: { code: routerCode, data: routerData2 }, bounce: false }));
  await bc.sendMessage(internal({ from: deployer.address, to: POOL, value: toNano('5'), stateInit: { code: poolCode, data: poolData2 }, bounce: false }));
  await bc.sendMessage(internal({ from: deployer.address, to: POOL_INIT, value: toNano('5'), stateInit: { code: poolCode, data: initialPoolData }, bounce: false }));

  const rd = (await bc.runGetMethod(ROUTER, 'get_router_data')).stackReader;
  const routerId = rd.readBigNumber();
  rd.readCell(); const locked = rd.readBigNumber(); rd.readCell(); rd.readCell();
  const poolCodeRef = rd.readCell();
  check('router deployed & live data readable', routerId > 0n, `id=${routerId} locked=${locked} pool_code_lib=${poolCodeRef.hash().toString('hex').slice(0, 12)}...`);
  const derived = (await bc.runGetMethod(ROUTER, 'get_pool_address', [{ type: 'slice', cell: beginCell().storeAddress(tk0).endCell() }, { type: 'slice', cell: beginCell().storeAddress(tk1).endCell() }])).stackReader.readAddress();
  check('router derives exactly the canonical pool address from the two jetton wallets', derived.equals(POOL_INIT), derived.toString());

  async function poolState() {
    const s = (await bc.runGetMethod(POOL, 'get_pool_data')).stackReader;
    const isLocked = s.readBigNumber();
    s.readCell(); // router
    const totalSupply = s.readBigNumber();
    const reserve0 = s.readBigNumber();
    const reserve1 = s.readBigNumber();
    const t0 = s.readCell().beginParse().loadAddress();
    const t1 = s.readCell().beginParse().loadAddress();
    const lpFee = s.readBigNumber();
    const protocolFee = s.readBigNumber();
    s.readCell(); // protocol fee address
    const collected0 = s.readBigNumber();
    const collected1 = s.readBigNumber();
    return { isLocked, totalSupply, reserve0, reserve1, t0, t1, lpFee, protocolFee, collected0, collected1 };
  }

  const st0 = await poolState();
  console.log(`pool state: locked=${st0.isLocked} lpSupply=${st0.totalSupply} r0=${st0.reserve0} r1=${st0.reserve1} lpFee=${st0.lpFee} pf=${st0.protocolFee}`);
  check('pool token0/token1 are the two live jetton wallets', !!st0.t0 && !!st0.t1 && !st0.t0.equals(st0.t1));

  const TOKEN0 = st0.t0;
  const TOKEN1 = st0.t1;

  // ---- 1. forged pay_to from an arbitrary sender must be rejected ----
  const forged = beginCell()
    .storeUint(OP.pay_to, 32).storeUint(0, 64)
    .storeAddress(attacker.address)   // to_address
    .storeAddress(attacker.address)   // excesses
    .storeAddress(attacker.address)   // original_caller
    .storeUint(0, 32)                 // exit_code
    .storeMaybeRef(null)              // custom_payload
    .storeRef(beginCell().storeCoins(0).storeCoins(0).storeAddress(TOKEN0).storeCoins(10n ** 12n).storeAddress(TOKEN1).endCell())
    .endCell();
  const rForged = await bc.sendMessage(internal({ from: attacker.address, to: ROUTER, value: toNano('0.3'), body: forged }));
  const tForged = findTx(rForged, ROUTER);
  const eForged = txExit(tForged);
  check('forged pay_to (arbitrary sender) rejected with exit 82 invalid_caller', eForged.exit === 82,
    `exit=${eForged.exit} outMsgs=${outMsgs(tForged).length}`);
  const forgedXfers = outMsgs(tForged).filter((m) => m.body && m.body.bits.length >= 32 && m.body.beginParse().preloadUint(32) === 0xf8a7ea5);
  check('forged pay_to produced no jetton transfer', forgedXfers.length === 0, `jettonTransfers=${forgedXfers.length} outMsgs=${outMsgs(tForged).length}`);

  // ---- 2. positive control: pay_to from the canonical pool address is accepted and pays out ----
  const legitBody = beginCell()
    .storeUint(OP.pay_to, 32).storeUint(0, 64)
    .storeAddress(attacker.address)
    .storeAddress(attacker.address)
    .storeAddress(attacker.address)
    .storeUint(0, 32)
    .storeMaybeRef(null)
    .storeRef(beginCell().storeCoins(0).storeCoins(0).storeAddress(TOKEN0).storeCoins(1000n).storeAddress(TOKEN1).endCell())
    .endCell();
  const rPool = await bc.sendMessage(internal({ from: POOL_INIT, to: ROUTER, value: toNano('0.3'), body: legitBody }));
  const tPool = findTx(rPool, ROUTER);
  const ePool = txExit(tPool);
  const outs = outMsgs(tPool);
  let transferOk = false, transferAmount = 0n, transferDest = null;
  for (const m of outs) {
    if (m.info.dest && m.info.dest.equals(TOKEN1) && m.body) {
      const s = m.body.beginParse();
      if (s.preloadUint(32) === 0xf8a7ea5) {
        s.loadUint(32); s.loadUint(64);
        transferAmount = s.loadCoins();
        transferDest = s.loadAddress();
        transferOk = true;
      }
    }
  }
  check('pay_to from canonical pool accepted (exit 0)', ePool.exit === 0, `exit=${ePool.exit}`);
  check('accepted pay_to emits jetton transfer of exact amount to owner', transferOk && transferAmount === 1000n && transferDest.equals(attacker.address),
    `amount=${transferAmount} dest=${transferDest && transferDest.toString()}`);

  // ---- 3. pool only accepts router messages: direct swap from arbitrary sender ----
  const before = await poolState();
  const swapBody = (amount0, minOut, deadline) => beginCell()
    .storeUint(OP.swap, 32).storeUint(0, 64)
    .storeAddress(attacker.address)   // from_user
    .storeCoins(amount0)              // left_amount  (token0 in)
    .storeCoins(0n)                   // right_amount
    .storeRef(beginCell()
      .storeUint(OP.swap, 32)         // transferred_op
      .storeAddress(TOKEN1)           // token_wallet1
      .storeAddress(attacker.address) // refund
      .storeAddress(attacker.address) // excesses
      .storeUint(deadline, 64)
      .storeRef(beginCell()
        .storeCoins(minOut)
        .storeAddress(attacker.address) // receiver
        .storeCoins(0)
        .storeMaybeRef(null)
        .storeCoins(0)
        .storeMaybeRef(null)
        .storeUint(0, 16)
        .storeAddress(null)             // ref_address = addr_none
        .endCell())
      .endCell())
    .endCell();
  const rDirect = await bc.sendMessage(internal({ from: attacker.address, to: POOL, value: toNano('0.5'), body: swapBody(10n ** 9n, 1n, Math.floor(Date.now() / 1000) + 600) }));
  const tDirect = findTx(rDirect, POOL);
  const eDirect = txExit(tDirect);
  const afterDirect = await poolState();
  check('swap sent directly to pool by non-router rejected (wrong_op 0xFFFF)', eDirect.exit === 0xffff, `exit=${eDirect.exit}`);
  check('rejected direct swap changed no reserves', afterDirect.reserve0 === before.reserve0 && afterDirect.reserve1 === before.reserve1,
    `r0 ${before.reserve0}->${afterDirect.reserve0} r1 ${before.reserve1}->${afterDirect.reserve1}`);

  // ---- 4. pool governance ops from arbitrary sender are rejected ----
  const rSetFees = await bc.sendMessage(internal({ from: attacker.address, to: POOL, value: toNano('0.3'),
    body: beginCell().storeUint(OP.internal_set_fees, 32).storeUint(0, 64).storeUint(0, 16).storeUint(0, 16).storeAddress(attacker.address).storeAddress(attacker.address).endCell() }));
  const eSetFees = txExit(findTx(rSetFees, POOL));
  check('internal_set_fees from arbitrary sender rejected (wrong_op)', eSetFees.exit === 0xffff, `exit=${eSetFees.exit}`);

  const rLock = await bc.sendMessage(internal({ from: attacker.address, to: POOL, value: toNano('0.3'),
    body: beginCell().storeUint(OP.internal_update_status, 32).storeUint(0, 64).storeAddress(attacker.address).endCell() }));
  const eLock = txExit(findTx(rLock, POOL));
  check('internal_update_status from arbitrary sender rejected (wrong_op)', eLock.exit === 0xffff, `exit=${eLock.exit}`);

  // ---- 5. "forge a jetton notification to the pool" hypothesis ----
  const rNotif = await bc.sendMessage(internal({ from: attacker.address, to: POOL, value: toNano('0.3'),
    body: beginCell().storeUint(OP.transfer_notification, 32).storeUint(0, 64).storeCoins(10n ** 15n).storeAddress(attacker.address).storeMaybeRef(null).endCell() }));
  const eNotif = txExit(findTx(rNotif, POOL));
  check('transfer_notification sent straight to pool rejected (pool has no credit handler)', eNotif.exit === 0xffff, `exit=${eNotif.exit}`);

  const rIntXfer = await bc.sendMessage(internal({ from: attacker.address, to: POOL, value: toNano('0.3'),
    body: beginCell().storeUint(OP.internal_transfer, 32).storeUint(0, 64).storeCoins(10n ** 15n).storeAddress(attacker.address).storeAddress(attacker.address).storeCoins(0).storeMaybeRef(null).endCell() }));
  const eIntXfer = txExit(findTx(rIntXfer, POOL));
  check('internal_transfer sent straight to pool rejected', eIntXfer.exit === 0xffff, `exit=${eIntXfer.exit}`);

  // ---- 5b. pay_to is bound to the exact (token0,token1) pair, not just to "a pool" ----
  const wrongPair = beginCell()
    .storeUint(OP.pay_to, 32).storeUint(0, 64)
    .storeAddress(attacker.address).storeAddress(attacker.address).storeAddress(attacker.address)
    .storeUint(0, 32).storeMaybeRef(null)
    .storeRef(beginCell().storeCoins(0).storeCoins(0).storeAddress(TOKEN0).storeCoins(1000n).storeAddress(TOKEN0).endCell())
    .endCell();
  const rWrongPair = await bc.sendMessage(internal({ from: POOL_INIT, to: ROUTER, value: toNano('0.3'), body: wrongPair }));
  const eWrongPair = txExit(findTx(rWrongPair, ROUTER));
  check('pay_to from the real pool with a substituted token pair is rejected', eWrongPair.exit === 82, `exit=${eWrongPair.exit}`);

  // ---- 5c. fake jetton wallet / fake notification cannot credit or drain a real pool ----
  const fakeJetton = await bc.treasury('fakeJetton');
  const beforeFake = await poolState();
  const fakeNotif = beginCell()
    .storeUint(OP.transfer_notification, 32).storeUint(0, 64)
    .storeCoins(10n ** 15n)                 // arbitrary "jetton_amount", no real transfer
    .storeAddress(attacker.address)         // from_address
    .storeRef(swapBody(10n ** 15n, 1n, Math.floor(Date.now() / 1000) + 600).beginParse().loadRef()) // dex payload
    .endCell();
  const rFake = await bc.sendMessage(internal({ from: fakeJetton.address, to: ROUTER, value: toNano('1'), body: fakeNotif }));
  const tFake = findTx(rFake, ROUTER);
  const outsFake = outMsgs(tFake);
  let routedTo = [];
  for (const m of outsFake) if (m.info.dest) routedTo.push(m.info.dest.toString());
  const touchedRealPool = routedTo.some((a) => Address.parse(a).equals(POOL) || Address.parse(a).equals(POOL_INIT));
  const afterFake = await poolState();
  check('fake transfer_notification is routed to a *different* (attacker-token) pool, never the real pool',
    outsFake.length > 0 && !touchedRealPool, `routedTo=${routedTo.join(',') || 'none'}`);
  check('fake notification leaves real pool reserves untouched',
    afterFake.reserve0 === beforeFake.reserve0 && afterFake.reserve1 === beforeFake.reserve1,
    `r0 ${beforeFake.reserve0}->${afterFake.reserve0} r1 ${beforeFake.reserve1}->${afterFake.reserve1}`);

  // ---- 6. legitimate router->pool swap: output matches the constant-product formula, pool-favouring rounding ----
  const b6 = await poolState();
  const amountIn = 10n ** 9n;
  const deadline = Math.floor(Date.now() / 1000) + 600;
  const rSwap = await bc.sendMessage(internal({ from: ROUTER, to: POOL, value: toNano('0.6'), body: swapBody(amountIn, 1n, deadline) }));
  const tSwap = findTx(rSwap, POOL);
  const eSwap = txExit(tSwap);
  const a6 = await poolState();
  const feeDiv = 10000n;
  const inWithFee = amountIn * (feeDiv - b6.lpFee);
  const baseOut = (inWithFee * b6.reserve1) / (b6.reserve0 * feeDiv + inWithFee);
  const pfOut = (baseOut * b6.protocolFee + feeDiv - 1n) / feeDiv; // divc rounds up
  const out1 = baseOut - pfOut;
  let payToAmt = null, payToExit = null;
  for (const m of outMsgs(tSwap)) {
    if (m.info.dest && m.info.dest.equals(ROUTER) && m.body) {
      const s = m.body.beginParse();
      if (s.preloadUint(32) === OP.pay_to) {
        s.loadUint(32); s.loadUint(64); s.loadAddress(); s.loadAddress(); s.loadAddress();
        payToExit = s.loadUint(32);
        s.loadMaybeRef();
        const ref = s.loadRef().beginParse();
        ref.loadCoins(); ref.loadCoins(); ref.loadAddress(); payToAmt = ref.loadCoins();
      }
    }
  }
  check('legit router->pool swap accepted', eSwap.exit === 0, `exit=${eSwap.exit}`);
  check('swap pay_to amount == CP-with-fee formula (floored output, ceil protocol fee)', payToAmt === out1,
    `pay_to=${payToAmt} formula=${out1} baseOut=${baseOut} pf=${pfOut}`);
  check('swap reserve0 credited exactly by amount_in', a6.reserve0 === b6.reserve0 + amountIn, `${b6.reserve0} -> ${a6.reserve0}`);
  check('swap reserve1 debited exactly by base_out (out + protocol fee)', a6.reserve1 === b6.reserve1 - baseOut, `${b6.reserve1} -> ${a6.reserve1}`);
  check('swap pay_to carries exit_code swap_ok', payToExit === 0xc64370e5, `exit_code=0x${(payToExit || 0).toString(16)}`);

  // ---- 7. slippage: min_out above achievable => refund, reserves unchanged ----
  const b7 = await poolState();
  const rSlip = await bc.sendMessage(internal({ from: ROUTER, to: POOL, value: toNano('0.6'), body: swapBody(amountIn, b7.reserve1, deadline + 100) }));
  const tSlip = findTx(rSlip, POOL);
  const eSlip = txExit(tSlip);
  const a7 = await poolState();
  let refundAmt = null, refundExit = null;
  for (const m of outMsgs(tSlip)) {
    if (m.info.dest && m.info.dest.equals(ROUTER) && m.body) {
      const s = m.body.beginParse();
      if (s.preloadUint(32) === OP.pay_to) {
        s.loadUint(32); s.loadUint(64); s.loadAddress(); s.loadAddress(); s.loadAddress();
        refundExit = s.loadUint(32);
        s.loadMaybeRef();
        const ref = s.loadRef().beginParse();
        ref.loadCoins(); refundAmt = ref.loadCoins();
      }
    }
  }
  check('min_out above achievable => swap_refund_slippage', refundExit === OP.swap_refund_slippage, `exit_code=0x${(refundExit || 0).toString(16)}`);
  check('slippage path refunds the full input (no partial fill)', refundAmt === amountIn, `refund=${refundAmt}`);
  check('slippage path leaves reserves unchanged', a7.reserve0 === b7.reserve0 && a7.reserve1 === b7.reserve1,
    `r0 ${b7.reserve0}->${a7.reserve0} r1 ${b7.reserve1}->${a7.reserve1}`);

  // ---- 8. deadline enforcement ----
  const rExp = await bc.sendMessage(internal({ from: ROUTER, to: POOL, value: toNano('0.6'), body: swapBody(amountIn, 1n, Math.floor(Date.now() / 1000) - 10) }));
  const tExp = findTx(rExp, POOL);
  let expExit = null;
  for (const m of outMsgs(tExp)) {
    if (m.info.dest && m.info.dest.equals(ROUTER) && m.body) {
      const s = m.body.beginParse();
      if (s.preloadUint(32) === OP.pay_to) { s.loadUint(32); s.loadUint(64); s.loadAddress(); s.loadAddress(); s.loadAddress(); expExit = s.loadUint(32); }
    }
  }
  check('expired tx_deadline => swap_refund_tx_expired', expExit === OP.swap_refund_tx_expired, `exit_code=0x${(expExit || 0).toString(16)}`);

  const passed = results.filter((r) => r.pass).length;
  console.log(`\n==== ${passed}/${results.length} PASS ====`);
  fs.writeFileSync(path.join(__dirname, 'results.json'), JSON.stringify({ passed, total: results.length, results }, null, 2));
  if (passed !== results.length) process.exit(1);
})().catch((e) => { console.error(e); process.exit(2); });
