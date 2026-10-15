// Pools Finance (IOTA L1) — read-only devInspect suite.
// No transactions are signed or submitted; simulations run against mainnet state.
// Usage: node devinspect-suite.mjs [outfile.json]
import { IotaClient } from '@iota/iota-sdk/client';
import { Transaction } from '@iota/iota-sdk/transactions';
import { writeFileSync } from 'node:fs';

const RPC = process.env.IOTA_RPC || 'https://api.mainnet.iota.cafe';
const PKG_OLD = '0xc0d0341970ed92ff0d72f7419b8a812d9a98708dd8078dcc6f9d26c1b9c62332'; // immutable v1
const PKG_NEW = '0x8426aee08fc77dab031bdc4d29b5d4b48464ce9ad0eb02c4bbaff9cd29f51357'; // upgradeable v4 (treasury feature)
const POOL1 = '0xcd2b276437db9612fc7a8d85fe5b3b09a6b5638c0b3ab2003f5f7b284e353d8c'; // IOTA/stIOTA ~$1.38M
const POOL1_V = 87955916;
const PAUSE = '0x37cf86558b51f63cbac2002d3d57b32ab083acf9e733ff9de2af2be72b647217';
const PAUSE_V = 87955915;
const STAKE_CFG = '0x15d3710c4d9ffe7f7b2d4b4b0a25be4c0ba804640d0f871a59c1661313fb64c9';
const STAKE_CFG_V = 87955915;
const TREASURY_CFG = '0x6f5947db3b2515e2d991984b0e91814b9f9869c80dacce2be00432b15416153c';
const TREASURY_CFG_V = 110558653;
const ADMIN = '0x3a775482f549c46317695443c0560d49cf1022289546f5d8b9844fe6dde7ff37';
const ATTACKER = '0x0000000000000000000000000000000000000000000000000000000000000abc';
const IOTA_T = '0x2::iota::IOTA';
const STIOTA_T = '0x346778989a9f57480ec3fee15f2cd68409c73a62112d40a3efd13987997be68c::cert::CERT';
const LP_T = `${PKG_OLD}::amm_swap::PoolLiquidityCoin<${IOTA_T}, ${STIOTA_T}>`;
// Admin-held coin objects used ONLY as raw material for math tests (devInspect ignores
// ownership; an attacker can source the same assets on the open market).
const IOTA_COIN = '0xe9cc83a9f4fd3ace19f2688256490b4b2a18bb7ca57f8db8126d4c258ee58a4f';
const STIOTA_COIN = '0x4f71be5c35d63b3cd816d9ef36515cc05c98a8ed80bdf788d69ee90e73de95b8';
const client = new IotaClient({ url: RPC });
const results = { rpc: RPC, block: null, tests: [] };

function le(bytes) { let v = 0n; for (let i = bytes.length - 1; i >= 0; i--) v = (v << 8n) | BigInt(bytes[i]); return v.toString(); }

async function run(id, desc, sender, build) {
  const rec = { id, desc, sender, status: null, returns: [], error: null };
  try {
    const tx = new Transaction();
    tx.setSenderIfNotSet(sender);
    build(tx);
    const bytes = await tx.build({ client, onlyTransactionKind: true });
    const params = [sender, Buffer.from(bytes).toString('base64'), null, null, { skip_checks: true }];
    const raw = await fetch(RPC, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'iota_devInspectTransactionBlock', params }) });
    const jr = await raw.json();
    if (!jr.result) { rec.error = JSON.stringify(jr.error); }
    else {
      rec.status = jr.result.effects?.status?.status ?? 'unknown';
      rec.error = jr.result.effects?.status?.error ?? null;
      for (const r of jr.result.results || []) for (const [b, t] of r.returnValues || []) rec.returns.push({ type: t, value: le(b) });
    }
  } catch (e) { rec.error = String(e).slice(0, 300); }
  results.tests.push(rec);
  console.log(`[${id}] ${rec.status ?? 'ERR'} ${rec.error ? '- ' + rec.error : ''} ${rec.returns.length ? JSON.stringify(rec.returns) : ''}`);
  return rec;
}

const poolRef = (tx) => tx.sharedObjectRef({ objectId: POOL1, initialSharedVersion: POOL1_V, mutable: true });
const pauseRef = (tx) => tx.sharedObjectRef({ objectId: PAUSE, initialSharedVersion: PAUSE_V, mutable: false });

// 0. record chain tip
try {
  const c = await fetch(RPC, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'iota_getLatestCheckpointSequenceNumber', params: [] }) });
  const cj = await c.json(); results.block = cj.result;
} catch (e) { results.block = 'unavailable'; }

// 1. T1: attacker -> stake_config admin setter (expect abort 200 = E_NOT_ADMIN)
await run('T1', 'attacker stake_config::set_treasury_admin_address(config, attacker) — expect abort 200', ATTACKER, (tx) => {
  tx.moveCall({ target: `${PKG_OLD}::stake_config::set_treasury_admin_address`, arguments: [tx.sharedObjectRef({ objectId: STAKE_CFG, initialSharedVersion: STAKE_CFG_V, mutable: true }), tx.pure.address(ATTACKER)] });
});
// 2. T2: real admin same call (expect success; proves gate semantics)
await run('T2', 'admin stake_config::set_treasury_admin_address(config, admin) — expect success', ADMIN, (tx) => {
  tx.moveCall({ target: `${PKG_OLD}::stake_config::set_treasury_admin_address`, arguments: [tx.sharedObjectRef({ objectId: STAKE_CFG, initialSharedVersion: STAKE_CFG_V, mutable: true }), tx.pure.address(ADMIN)] });
});
// 3. T3: attacker add+remove liquidity round trip (100 IOTA + 100 stIOTA desired)
await run('T3', 'attacker add_liquidity_router(100 IOTA,100 stIOTA) then remove all LP — out values must be <= in', ATTACKER, (tx) => {
  const [iotaC] = tx.splitCoins(tx.object(IOTA_COIN), [tx.pure.u64(100_000_000_000n)]);
  const [stC] = tx.splitCoins(tx.object(STIOTA_COIN), [tx.pure.u64(100_000_000_000n)]);
  const [lp] = tx.moveCall({
    target: `${PKG_OLD}::amm_router::add_liquidity_router`,
    typeArguments: [IOTA_T, STIOTA_T],
    arguments: [poolRef(tx), pauseRef(tx), iotaC, stC, tx.pure.u64(100_000_000_000n), tx.pure.u64(100_000_000_000n), tx.pure.u64(0), tx.pure.u64(0)],
  });
  const [aOut, bOut] = tx.moveCall({
    target: `${PKG_OLD}::amm_router::remove_liquidity_router`,
    typeArguments: [IOTA_T, STIOTA_T],
    arguments: [poolRef(tx), pauseRef(tx), lp, tx.pure.u64(0), tx.pure.u64(0), tx.pure.u64(0)],
  });
  tx.moveCall({ target: '0x2::coin::value', typeArguments: [IOTA_T], arguments: [aOut] });
  tx.moveCall({ target: '0x2::coin::value', typeArguments: [STIOTA_T], arguments: [bOut] });
});
// 4. T4: attacker exact-out swap consistency: compute_in vs actual paid amount
await run('T4', 'attacker swap_coinA_for_exact_coinB_router(100 IOTA coin, maxIn, exactOut=50 stIOTA) -> out value', ATTACKER, (tx) => {
  const [iotaC] = tx.splitCoins(tx.object(IOTA_COIN), [tx.pure.u64(100_000_000_000n)]);
  const [out] = tx.moveCall({
    target: `${PKG_OLD}::amm_router::swap_coinA_for_exact_coinB_router`,
    typeArguments: [IOTA_T, STIOTA_T],
    arguments: [poolRef(tx), pauseRef(tx), iotaC, tx.pure.u64(100_000_000_000n), tx.pure.u64(50_000_000_000n)],
  });
  tx.moveCall({ target: '0x2::coin::value', typeArguments: [STIOTA_T], arguments: [out] });
});
// 5. T5: attacker sweeps accumulated admin fees via NEW package claim_fee_pools (permissionless; expect success)
await run('T5', 'attacker NEW::amm_entries::claim_fee_pools(pool1, canonical treasury config) — expect success (fees go to treasury address, not caller)', ATTACKER, (tx) => {
  tx.moveCall({ target: `${PKG_NEW}::amm_entries::claim_fee_pools`, typeArguments: [IOTA_T, STIOTA_T], arguments: [poolRef(tx), tx.sharedObjectRef({ objectId: TREASURY_CFG, initialSharedVersion: TREASURY_CFG_V, mutable: false })] });
});
// 6. T6: attacker NEW::set_treasury_pools (AdminCap required; devInspect ignores ownership, so this only shows the code path exists)
await run('T6', 'attacker NEW::amm_entries::set_treasury_pools(AdminCap, cfg, attackerAddr) [ownership-enforced on-chain]', ATTACKER, (tx) => {
  tx.moveCall({ target: `${PKG_NEW}::amm_entries::set_treasury_pools`, arguments: [tx.object('0x290b0c5467b8b2eccb0286a8158c233c1908c7597b15ed5e1d87437ff434e69b'), tx.sharedObjectRef({ objectId: TREASURY_CFG, initialSharedVersion: TREASURY_CFG_V, mutable: true }), tx.pure.address(ATTACKER)] });
});

const outfile = process.argv[2] || 'devinspect-results.json';
writeFileSync(outfile, JSON.stringify(results, null, 1));
console.log(`\nwrote ${outfile} (checkpoint ${results.block})`);
