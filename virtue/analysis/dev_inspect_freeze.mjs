// Final verification tests: freeze location, vault views, SP deposit permissionlessness
import { IotaClient } from '@iota/iota-sdk/client';
import { Transaction } from '@iota/iota-sdk/transactions';

const realFetch = globalThis.fetch;
globalThis.fetch = async (url, init) => {
  let lastErr;
  for (let i = 0; i < 8; i++) {
    try { return await realFetch(url, init); }
    catch (e) { lastErr = e; await new Promise(r => setTimeout(r, 400 * (i + 1))); }
  }
  throw lastErr;
};
const client = new IotaClient({ url: 'https://api.mainnet.iota.cafe' });

const SP = '0x6101272394511caf38ce5a6d120d3b4d009b6efabae8faac43aa9ac938cec558';
const SP_PKG = '0xe50fa492446245d9dd4bc61641a4ab2e72cd1276703d6ae8e41377a046b0929b';
const ACCOUNT = '0x7400af41a9b9d7e4502bc77991dbd1171f90855564fd28afa172a5057beb083b';
const CLOCK = '0x6';
const VUSD = '0xd3b63e603a78786facf65ff22e79701f3e824881a12fa3268d62a75530fe904f::vusd::VUSD';
const VAULT_IOTA = '0xaf306be8419cf059642acdba3b4e79a5ae893101ae62c8331cefede779ef48d5';
const TREASURY = '0x81f525f4fa5b2d3cf58677d3e39aabc4b0a1ca25cbba605033cfe417e47b0a16';
const CDP_PKG = '0xcdeeb40cd7ffd7c3b741f40a8e11cb784a5c9b588ce993d4ab86479072386ba1';
const FRESH = '0x0000000000000000000000000000000000000000000000000000000000000123';

async function run(name, sender, build) {
  const tx = new Transaction();
  try { build(tx); } catch (e) { console.log('='.repeat(88)); console.log('TEST:', name, '\n  BUILD ERROR:', String(e).slice(0, 300)); return; }
  tx.setSenderIfNotSet(sender);
  try {
    const res = await client.devInspectTransactionBlock({ sender, transactionBlock: tx });
    console.log('='.repeat(88));
    console.log('TEST:', name);
    console.log('  status:', JSON.stringify(res.effects?.status));
    if (res.effects?.status?.status === 'success') {
      for (const rv of res.results ?? []) console.log('  returnValues:', JSON.stringify(rv.returnValues ?? []).slice(0, 300));
    }
  } catch (e) { console.log('='.repeat(88)); console.log('TEST:', name, '\n  THROWN:', String(e).slice(0, 300)); }
}

// F1: ONLY request::debtor_request (confirm freeze location)
await run('F1 request::debtor_request alone (deposit 0, borrow 0.1)', FRESH, (tx) => {
  const ar = tx.moveCall({ target: `${ACCOUNT}::account::request` });
  const zeroVusd = tx.moveCall({ target: '0x2::coin::zero', typeArguments: [VUSD] });
  const zeroIota = tx.moveCall({ target: '0x2::coin::zero', typeArguments: ['0x2::iota::IOTA'] });
  tx.moveCall({ target: `${CDP_PKG}::request::debtor_request`, typeArguments: ['0x2::iota::IOTA'],
    arguments: [ar, tx.object(TREASURY), tx.pure.id(VAULT_IOTA), zeroIota, tx.pure.u64(100000n), zeroVusd, tx.pure.u64(0n)] });
});

// F2: vault::get_positions view (should still work - pure read)
await run('F2 vault::get_positions<IOTA> view (read-only)', FRESH, (tx) => {
  tx.moveCall({ target: `${CDP_PKG}::vault::get_positions`, typeArguments: ['0x2::iota::IOTA'],
    arguments: [tx.object(VAULT_IOTA), tx.object(CLOCK), tx.moveCall({ target: '0x1::option::none', typeArguments: ['0x2::object::ID'] }), tx.pure.u64(3n)] });
});

// F3: SP deposit as fresh addr (permissionless deposit?) - zero VUSD
await run('F3 SP::deposit_and_update as FRESH (0 VUSD)', FRESH, (tx) => {
  const ar = tx.moveCall({ target: `${ACCOUNT}::account::request` });
  const zeroVusd = tx.moveCall({ target: '0x2::coin::zero', typeArguments: [VUSD] });
  tx.moveCall({ target: `${SP_PKG}::stability_pool::deposit_and_update`, arguments: [tx.object(SP), tx.object(CLOCK), ar, zeroVusd] });
});

// F4: vault::update_position with None price, zero borrow, zero deposit (does the vault itself check version?)
await run('F4 vault::update_position None price zero-op', FRESH, (tx) => {
  const ar = tx.moveCall({ target: `${ACCOUNT}::account::request` });
  const zeroVusd = tx.moveCall({ target: '0x2::coin::zero', typeArguments: [VUSD] });
  const zeroIota = tx.moveCall({ target: '0x2::coin::zero', typeArguments: ['0x2::iota::IOTA'] });
  const req = tx.moveCall({ target: `${CDP_PKG}::request::debtor_request`, typeArguments: ['0x2::iota::IOTA'],
    arguments: [ar, tx.object(TREASURY), tx.pure.id(VAULT_IOTA), zeroIota, tx.pure.u64(0n), zeroVusd, tx.pure.u64(0n)] });
  const none = tx.moveCall({ target: '0x1::option::none', typeArguments: [`0x7eebbee92f64ba2912bdbfba1864a362c463879fc5b3eacc735c1dcb255cc2cf::result::PriceResult<0x2::iota::IOTA>`] });
  tx.moveCall({ target: `${CDP_PKG}::vault::update_position`, typeArguments: ['0x2::iota::IOTA'],
    arguments: [tx.object(VAULT_IOTA), tx.object(TREASURY), tx.object(CLOCK), none, req] });
});
