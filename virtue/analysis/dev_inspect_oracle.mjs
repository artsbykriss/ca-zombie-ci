// Read-only dev-inspect tests of Virtue oracle paths (no tx sent, no gas spent)
// Run: node test_oracle.mjs
import { IotaClient } from '@iota/iota-sdk/client';
import { Transaction } from '@iota/iota-sdk/transactions';

// --- retry wrapper (public RPC is flaky from this host) ---
const realFetch = globalThis.fetch;
let attempts = 0;
globalThis.fetch = async (url, init) => {
  let lastErr;
  for (let i = 0; i < 8; i++) {
    try { attempts++; return await realFetch(url, init); }
    catch (e) { lastErr = e; await new Promise(r => setTimeout(r, 400 * (i + 1))); }
  }
  throw lastErr;
};

const client = new IotaClient({ url: 'https://api.mainnet.iota.cafe' });
const SENDER = '0x381d5b5fa3ae0ba5b3d0ce3421a43d48397cf6eb2a87e624d56dec5e68e7c7e9';

const ORACLE = '0x7eebbee92f64ba2912bdbfba1864a362c463879fc5b3eacc735c1dcb255cc2cf';
const PYTH_RULE = '0xed5a8dac2ca41ae9bdc1c7f778b0949d3e26c18c51ed284c4cfa4030d0bb64c2';
const SB_RULE = '0x39fb7adf0abd75b31868e17706b8600cc943bc27422fb582f6e14282029cd5f0';
const AGG_IOTA = '0x052c40b4e8f16df5238457f3a7b3b0eeaa49c6bc8acc22f6a7790ab32495b2c6';
const PYTH_RULE_CONFIG = '0xbcc4f6e3ca3d4a83eac39282ab7d1cb086924c58bef825d69c33b00fea1105b8';
const PYTH_STATE = '0x6bc33855c7675e006f55609f61eebb1c8a104d8973a698ee9efd3127c210b37f';
const PRICE_INFO_IOTA = '0xbc6d98f22b82e08add862adb7dab76cc8e18908254fc73093d53e4af14c7fac7';
const PRICE_INFO_IBTC = '0x3de713af32693d5237934d39205a0cafe1348b461b940f58dfac5ec5ce98bd31';
const SB_CONFIG = '0xa0c7b527f35476c51938d0ffd144b83cd7ee5091f516327228391b77e03afa3e';
const SB_AGG = '0x7c16ffdac553a4816db57e5e2cfbba8245337f2983b4ffb4dd944493a530c556';
const CLOCK = '0x6';

async function run(name, build) {
  const tx = new Transaction();
  try { build(tx); } catch (e) { console.log('='.repeat(90)); console.log('TEST:', name, '\n  BUILD ERROR:', String(e).slice(0, 400)); return; }
  tx.setSenderIfNotSet(SENDER);
  try {
    const res = await client.devInspectTransactionBlock({ sender: SENDER, transactionBlock: tx });
    console.log('='.repeat(90));
    console.log('TEST:', name);
    console.log('  status:', JSON.stringify(res.effects?.status));
    if (res.effects?.status?.status === 'success') {
      for (const rv of res.results ?? []) {
        console.log('  returnValues:', JSON.stringify(rv.returnValues ?? []).slice(0, 500));
      }
      console.log('  events:', (res.events ?? []).map(e => `${e.type.split('::').pop()} ${JSON.stringify(e.parsedJson).slice(0, 220)}`).join('\n          '));
    } else {
      console.log('  error:', res.effects?.status?.error);
    }
  } catch (e) {
    console.log('='.repeat(90));
    console.log('TEST:', name, '\n  THROWN:', String(e).slice(0, 500));
  }
}

// P1: pyth feed with CORRECT IOTA price info -> aggregate via registered aggregator
await run('P1 pyth feed<IOTA> with IOTA PriceInfo -> aggregate', (tx) => {
  const c = tx.moveCall({ target: `${ORACLE}::collector::new`, typeArguments: ['0x2::iota::IOTA'] });
  tx.moveCall({ target: `${PYTH_RULE}::pyth_rule::feed`, typeArguments: ['0x2::iota::IOTA'],
    arguments: [c, tx.object(PYTH_RULE_CONFIG), tx.object(CLOCK), tx.object(PYTH_STATE), tx.object(PRICE_INFO_IOTA)] });
  const r = tx.moveCall({ target: `${ORACLE}::aggregater::aggregate`, typeArguments: ['0x2::iota::IOTA'],
    arguments: [tx.object(AGG_IOTA), c] });
  tx.moveCall({ target: `${ORACLE}::result::aggregated_price`, typeArguments: ['0x2::iota::IOTA'], arguments: [r] });
});

// P2: pyth feed with WRONG (IBTC) price info -> aggregate via registered aggregator
await run('P2 pyth feed<IOTA> with IBTC PriceInfo -> aggregate (feed-id check?)', (tx) => {
  const c = tx.moveCall({ target: `${ORACLE}::collector::new`, typeArguments: ['0x2::iota::IOTA'] });
  tx.moveCall({ target: `${PYTH_RULE}::pyth_rule::feed`, typeArguments: ['0x2::iota::IOTA'],
    arguments: [c, tx.object(PYTH_RULE_CONFIG), tx.object(CLOCK), tx.object(PYTH_STATE), tx.object(PRICE_INFO_IBTC)] });
  const r = tx.moveCall({ target: `${ORACLE}::aggregater::aggregate`, typeArguments: ['0x2::iota::IOTA'],
    arguments: [tx.object(AGG_IOTA), c] });
  tx.moveCall({ target: `${ORACLE}::result::aggregated_price`, typeArguments: ['0x2::iota::IOTA'], arguments: [r] });
});

// P3: switchboard feed (real aggregator) -> aggregate via registered aggregator (weight 0 now)
await run('P3 switchboard feed<IOTA> real agg -> aggregate registered', (tx) => {
  const c = tx.moveCall({ target: `${ORACLE}::collector::new`, typeArguments: ['0x2::iota::IOTA'] });
  tx.moveCall({ target: `${SB_RULE}::switchboard_rule::feed`, typeArguments: ['0x2::iota::IOTA'],
    arguments: [c, tx.object(SB_CONFIG), tx.object(CLOCK), tx.object(SB_AGG)] });
  const r = tx.moveCall({ target: `${ORACLE}::aggregater::aggregate`, typeArguments: ['0x2::iota::IOTA'],
    arguments: [tx.object(AGG_IOTA), c] });
  tx.moveCall({ target: `${ORACLE}::result::aggregated_price`, typeArguments: ['0x2::iota::IOTA'], arguments: [r] });
});

// P4: can anyone create an aggregator? pass a shared object as first arg to reveal expected type
await run('P4 aggregater::new<IOTA>(?, 1, ctx) type probe', (tx) => {
  tx.moveCall({ target: `${ORACLE}::aggregater::new`, typeArguments: ['0x2::iota::IOTA'],
    arguments: [tx.object(SB_CONFIG), tx.pure.u64(1)] });
});
