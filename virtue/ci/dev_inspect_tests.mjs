// Virtue (IOTA L1) — read-only dev-inspect regression suite.
// Asserts the protocol's current gate states (no transactions are ever sent).
// Expected outcomes encode the 2026-10-15 audit findings:
//   - fake-price mint path CLOSED (switchboard weight 0, pyth feed-id + freshness checks)
//   - CDP FROZEN (Treasury module version removed) => no borrow/repay/deposit/withdraw
//   - SP deposit permissionless; withdraw depositor-only; claim returns 0 for non-depositors
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
const ACCOUNT = '0x7400af41a9b9d7e4502bc77991dbd1171f90855564fd28afa172a5057beb083b';
const SP = '0x6101272394511caf38ce5a6d120d3b4d009b6efabae8faac43aa9ac938cec558';
const SP_PKG = '0xe50fa492446245d9dd4bc61641a4ab2e72cd1276703d6ae8e41377a046b0929b';
const CDP_PKG = '0xcdeeb40cd7ffd7c3b741f40a8e11cb784a5c9b588ce993d4ab86479072386ba1';
const TREASURY = '0x81f525f4fa5b2d3cf58677d3e39aabc4b0a1ca25cbba605033cfe417e47b0a16';
const VAULT_IOTA = '0xaf306be8419cf059642acdba3b4e79a5ae893101ae62c8331cefede779ef48d5';
const VUSD = '0xd3b63e603a78786facf65ff22e79701f3e824881a12fa3268d62a75530fe904f::vusd::VUSD';
const TOP_DEPOSITOR = '0x014366e0607ba19939890dee83912bbe824f13a26180d207096976994aacebb3';
const FRESH = '0x0000000000000000000000000000000000000000000000000000000000000123';

let failures = 0;
async function check(name, sender, build, expect) {
  const tx = new Transaction();
  try { build(tx); } catch (e) { console.log(`CHECK ${name}: FAIL (build error: ${String(e).slice(0, 160)})`); failures++; return; }
  tx.setSenderIfNotSet(sender);
  let status, err, rv = [];
  try {
    const res = await client.devInspectTransactionBlock({ sender, transactionBlock: tx });
    status = res.effects?.status?.status;
    err = res.effects?.status?.error ?? '';
    rv = (res.results ?? []).flatMap(r => r.returnValues ?? []);
  } catch (e) { status = 'thrown'; err = String(e); }
  let ok = false;
  if (expect.kind === 'abort') ok = status === 'failure' && err.includes(expect.contains);
  if (expect.kind === 'success') ok = status === 'success';
  if (expect.kind === 'success_zero_coin') ok = status === 'success' && rv.length > 0;
  console.log(`CHECK ${name}: ${ok ? 'PASS' : 'FAIL'} [status=${status}${err ? ' err=' + String(err).slice(0, 200) : ''}]`);
  if (!ok) failures++;
}

// ---------- oracle paths (expect closed) ----------
await check('P1-pyth-stale-abort', FRESH, (tx) => {
  const c = tx.moveCall({ target: `${ORACLE}::collector::new`, typeArguments: ['0x2::iota::IOTA'] });
  tx.moveCall({ target: `${PYTH_RULE}::pyth_rule::feed`, typeArguments: ['0x2::iota::IOTA'],
    arguments: [c, tx.object(PYTH_RULE_CONFIG), tx.object(CLOCK), tx.object(PYTH_STATE), tx.object(PRICE_INFO_IOTA)] });
}, { kind: 'abort', contains: 'check_price_is_fresh' });

await check('P2-pyth-wrong-feed-abort', FRESH, (tx) => {
  const c = tx.moveCall({ target: `${ORACLE}::collector::new`, typeArguments: ['0x2::iota::IOTA'] });
  tx.moveCall({ target: `${PYTH_RULE}::pyth_rule::feed`, typeArguments: ['0x2::iota::IOTA'],
    arguments: [c, tx.object(PYTH_RULE_CONFIG), tx.object(CLOCK), tx.object(PYTH_STATE), tx.object(PRICE_INFO_IBTC)] });
}, { kind: 'abort', contains: 'err_invalid_price_info_object' });

await check('P3-switchboard-weight0-abort', FRESH, (tx) => {
  const c = tx.moveCall({ target: `${ORACLE}::collector::new`, typeArguments: ['0x2::iota::IOTA'] });
  tx.moveCall({ target: `${SB_RULE}::switchboard_rule::feed`, typeArguments: ['0x2::iota::IOTA'],
    arguments: [c, tx.object(SB_CONFIG), tx.object(CLOCK), tx.object(SB_AGG)] });
  tx.moveCall({ target: `${ORACLE}::aggregater::aggregate`, typeArguments: ['0x2::iota::IOTA'],
    arguments: [tx.object(AGG_IOTA), c] });
}, { kind: 'abort', contains: 'err_total_weight_not_enough' });

// ---------- CDP frozen ----------
await check('F1-debtor-request-frozen', FRESH, (tx) => {
  const ar = tx.moveCall({ target: `${ACCOUNT}::account::request` });
  const zeroVusd = tx.moveCall({ target: '0x2::coin::zero', typeArguments: [VUSD] });
  const zeroIota = tx.moveCall({ target: '0x2::coin::zero', typeArguments: ['0x2::iota::IOTA'] });
  tx.moveCall({ target: `${CDP_PKG}::request::debtor_request`, typeArguments: ['0x2::iota::IOTA'],
    arguments: [ar, tx.object(TREASURY), tx.pure.id(VAULT_IOTA), zeroIota, tx.pure.u64(100000n), zeroVusd, tx.pure.u64(0n)] });
}, { kind: 'abort', contains: 'err_invalid_module_version' });

// ---------- SP paths ----------
await check('W1-sp-depositor-withdraw-ok', TOP_DEPOSITOR, (tx) => {
  const ar = tx.moveCall({ target: `${ACCOUNT}::account::request` });
  tx.moveCall({ target: `${SP_PKG}::stability_pool::withdraw`, arguments: [tx.object(SP), tx.object(CLOCK), ar, tx.pure.u64(1000000n)] });
}, { kind: 'success' });

await check('W2-sp-nondepositor-withdraw-abort', FRESH, (tx) => {
  const ar = tx.moveCall({ target: `${ACCOUNT}::account::request` });
  tx.moveCall({ target: `${SP_PKG}::stability_pool::withdraw`, arguments: [tx.object(SP), tx.object(CLOCK), ar, tx.pure.u64(1000000n)] });
}, { kind: 'abort', contains: 'err_account_not_found' });

await check('W3-sp-nondepositor-claim-zero', FRESH, (tx) => {
  const ar = tx.moveCall({ target: `${ACCOUNT}::account::request` });
  tx.moveCall({ target: `${SP_PKG}::stability_pool::claim`, typeArguments: ['0x2::iota::IOTA'], arguments: [tx.object(SP), ar] });
}, { kind: 'success_zero_coin' });

await check('F3-sp-deposit-permissionless', FRESH, (tx) => {
  const ar = tx.moveCall({ target: `${ACCOUNT}::account::request` });
  const zeroVusd = tx.moveCall({ target: '0x2::coin::zero', typeArguments: [VUSD] });
  tx.moveCall({ target: `${SP_PKG}::stability_pool::deposit_and_update`, arguments: [tx.object(SP), tx.object(CLOCK), ar, zeroVusd] });
}, { kind: 'success' });

console.log(`\nSUMMARY: ${failures === 0 ? 'ALL CHECKS PASSED' : failures + ' CHECK(S) FAILED'}`);
process.exit(failures === 0 ? 0 : 1);
