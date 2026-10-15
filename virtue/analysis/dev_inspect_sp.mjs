// Read-only dev-inspect: SP withdraw / claim / deposit + vault None-price borrow
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
const SP_PKG = '0xe50fa492446245d9dd4bc61641a4ab2e72cd1276703d6ae8e41377a046b0929b'; // current SP package
const ACCOUNT = '0x7400af41a9b9d7e4502bc77991dbd1171f90855564fd28afa172a5057beb083b';
const CLOCK = '0x6';
const VUSD = '0xd3b63e603a78786facf65ff22e79701f3e824881a12fa3268d62a75530fe904f::vusd::VUSD';
const VAULT_IOTA = '0xaf306be8419cf059642acdba3b4e79a5ae893101ae62c8331cefede779ef48d5';
const TREASURY = '0x81f525f4fa5b2d3cf58677d3e39aabc4b0a1ca25cbba605033cfe417e47b0a16';
const CDP_PKG = '0xcdeeb40cd7ffd7c3b741f40a8e11cb784a5c9b588ce993d4ab86479072386ba1';

// top SP depositor
const DEPOSITOR = '0x014366e0607ba19939890dee83912bbe824f13a26180d207096976994aacebb3';
// a fresh address with no SP position (use the attacker's, or a random one)
const FRESH = '0x0000000000000000000000000000000000000000000000000000000000000123';

async function run(name, sender, build) {
  const tx = new Transaction();
  try { build(tx); } catch (e) { console.log('='.repeat(90)); console.log('TEST:', name, '\n  BUILD ERROR:', String(e).slice(0, 300)); return; }
  tx.setSenderIfNotSet(sender);
  try {
    const res = await client.devInspectTransactionBlock({ sender, transactionBlock: tx });
    console.log('='.repeat(90));
    console.log('TEST:', name);
    console.log('  status:', JSON.stringify(res.effects?.status));
    if (res.effects?.status?.status === 'success') {
      for (const rv of res.results ?? []) console.log('  returnValues:', JSON.stringify(rv.returnValues ?? []).slice(0, 400));
      console.log('  events:', (res.events ?? []).map(e => `${e.type.split('::').pop()} ${JSON.stringify(e.parsedJson).slice(0, 200)}`).join('\n          '));
    }
  } catch (e) { console.log('='.repeat(90)); console.log('TEST:', name, '\n  THROWN:', String(e).slice(0, 400)); }
}

// W1: top depositor withdraws 1 VUSD from SP
await run('W1 SP::withdraw 1 VUSD as top depositor', DEPOSITOR, (tx) => {
  const ar = tx.moveCall({ target: `${ACCOUNT}::account::request` });
  tx.moveCall({ target: `${SP_PKG}::stability_pool::withdraw`, arguments: [tx.object(SP), tx.object(CLOCK), ar, tx.pure.u64(1000000n)] });
});

// W2: fresh address (no position) tries to withdraw 1 VUSD
await run('W2 SP::withdraw as FRESH addr (no position)', FRESH, (tx) => {
  const ar = tx.moveCall({ target: `${ACCOUNT}::account::request` });
  tx.moveCall({ target: `${SP_PKG}::stability_pool::withdraw`, arguments: [tx.object(SP), tx.object(CLOCK), ar, tx.pure.u64(1000000n)] });
});

// W3: fresh addr tries claim<IOTA> (SP coll balance)
await run('W3 SP::claim<IOTA> as FRESH addr', FRESH, (tx) => {
  const ar = tx.moveCall({ target: `${ACCOUNT}::account::request` });
  tx.moveCall({ target: `${SP_PKG}::stability_pool::claim`, typeArguments: ['0x2::iota::IOTA'], arguments: [tx.object(SP), ar] });
});

// W4: depositor claims their IOTA coll balance (if any)
await run('W4 SP::claim<IOTA> as top depositor', DEPOSITOR, (tx) => {
  const ar = tx.moveCall({ target: `${ACCOUNT}::account::request` });
  tx.moveCall({ target: `${SP_PKG}::stability_pool::claim`, typeArguments: ['0x2::iota::IOTA'], arguments: [tx.object(SP), ar] });
});

// W5: None-price borrow attempt on IOTA vault (0.1 VUSD)
await run('W5 vault::update_position with None price + borrow 0.1 VUSD', DEPOSITOR, (tx) => {
  const ar = tx.moveCall({ target: `${ACCOUNT}::account::request` });
  const zeroVusd = tx.moveCall({ target: '0x2::coin::zero', typeArguments: [VUSD] });
  const req = tx.moveCall({ target: `${CDP_PKG}::request::debtor_request`, typeArguments: ['0x2::iota::IOTA'],
    arguments: [ar, tx.object(TREASURY), tx.pure.id(VAULT_IOTA), tx.moveCall({ target: '0x2::coin::zero', typeArguments: ['0x2::iota::IOTA'] }), tx.pure.u64(100000n), zeroVusd, tx.pure.u64(0n)] });
  const none = tx.moveCall({ target: '0x1::option::none', typeArguments: [`0x7eebbee92f64ba2912bdbfba1864a362c463879fc5b3eacc735c1dcb255cc2cf::result::PriceResult<0x2::iota::IOTA>`] });
  tx.moveCall({ target: `${CDP_PKG}::vault::update_position`, typeArguments: ['0x2::iota::IOTA'],
    arguments: [tx.object(VAULT_IOTA), tx.object(TREASURY), tx.object(CLOCK), none, req] });
});
