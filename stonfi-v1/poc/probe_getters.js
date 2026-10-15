/**
 * Test the getter paths on the v1 ROUTER and the USDT-pTON POOL: do they send their
 * whole TON balance to the caller (send_payload mode 128 = CARRY_ALL_BALANCE)?
 */
const { Blockchain, internal } = require("@ton/sandbox");
const { Cell, Address, beginCell, toNano, contractAddress } = require("@ton/core");
const https = require("https");
const fs = require("fs");

const ROUTER = "EQB3ncyBUTjZUA5EnFKR5_EnOMI9V1tTEAAPaiU71gc4TiUt";
const POOL = "EQD8TJ8xEWB1SpnRE4d89YO3jl0W0EiBnNS4IBaHaUmdfizE";

function fetchJson(url) { return new Promise((res, rej) => https.get(url, { headers: { "User-Agent": "x" } }, (r) => { let d = ""; r.on("data", c => d += c); r.on("end", () => res(JSON.parse(d))); }).on("error", rej)); }
async function load(addr) {
  const j = await fetchJson(`https://toncenter.com/api/v3/accountStates?address=${addr}&include_boc=true`);
  const a = j.accounts[0];
  return { code: Cell.fromBoc(Buffer.from(a.code_boc, "base64"))[0], data: Cell.fromBoc(Buffer.from(a.data_boc, "base64"))[0], balance: a.balance };
}

(async () => {
  const bc = await Blockchain.create();
  bc.verbosity = { logs: false, vmLogs: "none", debugLogs: false, blockchainLogs: false };
  const attacker = await bc.treasury("attacker", { balance: toNano("100000") });
  const A = attacker.address;

  const out = {};
  for (const [name, addrStr, fund] of [["router", ROUTER, "4000"], ["pool", POOL, "5300"]]) {
    const { code, data, balance } = await load(addrStr);
    const target = contractAddress(0, { code, data });
    await attacker.send({ to: target, value: toNano(fund), init: { code, data }, body: beginCell().endCell(), bounce: false });
    out[name] = { address: target.toString(), deployed_balance: (await bc.getContract(target)).balance.toString(), real_balance: balance };
    // probe getters
    const probes = name === "router"
      ? [["getter_pool_address 0xd1db969b", beginCell().storeUint(0xd1db969b, 32).storeUint(1, 64)
          .storeAddress(Address.parseRaw("0:4eec921b9d4d56a0d94676016d49c26b39b1d7901a7e153e66033f146a0886f4"))
          .storeAddress(Address.parseRaw("0:1150b518b2626ad51899f98887f8824b70065456455f7fe2813f012699a4061f")).endCell()]]
      : [["getter_pool_data 0xc3c034e6", beginCell().storeUint(0xc3c034e6, 32).storeUint(1, 64).endCell()],
         ["getter_expected_liquidity 0x8751801f", beginCell().storeUint(0x8751801f, 32).storeUint(1, 64).storeCoins(1000000000).endCell()]];
    out[name].probes = [];
    for (const [pname, body] of probes) {
      const r = await bc.sendMessage(internal({ from: A, to: target, value: toNano("1"), body }));
      const info = [];
      for (const t of r.transactions) {
        const c = t.description.computePhase;
        const outs = [];
        for (const m of t.outMessages.values()) {
          let dest = null, val = null, op = null;
          try { dest = m.info.dest ? m.info.dest.toString() : null; } catch (e) {}
          try { val = m.info.value.coins.toString(); } catch (e) {}
          try { op = m.body ? "0x" + m.body.beginParse().loadUint(32).toString(16) : null; } catch (e) { op = "noparse"; }
          outs.push({ dest, value: val, op });
        }
        info.push({ src: t.inMessage?.info?.src?.toString() || null, dest: t.inMessage?.info?.dest?.toString() || null,
          exit: c.type === "vm" ? c.exitCode : c.type, aborted: c.type === "vm" ? !c.success : false, outMsgs: outs });
      }
      out[name].probes.push({ pname, info });
      // balance after
      out[name]["balance_after_" + pname] = (await bc.getContract(target)).balance.toString();
    }
  }
  console.log(JSON.stringify(out, null, 1));
  fs.writeFileSync("/home/heisenberg/CA/stonfi-v1/analysis/getter_probe.json", JSON.stringify(out, null, 1));
})().catch(e => { console.error("FATAL", e); process.exit(1); });
