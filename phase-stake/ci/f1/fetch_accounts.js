#!/usr/bin/env node
/**
 * F-1 PoC — fetch live accounts and craft the precondition for a local test validator.
 *
 * Read-only against mainnet. Writes JSON account files to ci/f1/accounts/ for
 * `solana-test-validator --account/--clone`. The ONLY modification is flipping the
 * validator-list record status byte to DeactivatingValidator (3), simulating the
 * aftermath of a staker `RemoveValidatorFromPool` (which we cannot sign for).
 */
const fs = require("fs");
const path = require("path");
const { Connection, PublicKey } = require("@solana/web3.js");

const RPCS = [
  process.env.SOL_RPC,
  "https://solana-rpc.publicnode.com",
  "https://api.mainnet-beta.solana.com",
].filter(Boolean);

const ACCTS = {
  pool: "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG",
  vlist: "phaseeExd43yGjjad2FZSigdG9UTRpMdxS4aMerx821",
  reserve: "phaseECAeXantYWXvRGkmeh7ddQsUJTf7DcywquY9Z2",
  mint: "phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG",
  mgrfee: "GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U",
  stake: "8QtQ1U34DPs2UKQiwUoRPMHnjJedsmdASZdbQHa7VHKh",
  program: "SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn",
};

const OUT = path.join(__dirname, "accounts");
fs.mkdirSync(OUT, { recursive: true });

async function connect() {
  for (const u of RPCS) {
    try {
      const c = new Connection(u, "confirmed");
      await c.getVersion();
      console.log("rpc:", u);
      return c;
    } catch (e) { /* next */ }
  }
  throw new Error("no working RPC");
}

function dataBuf(info) {
  if (Buffer.isBuffer(info.data)) return info.data;
  if (Array.isArray(info.data)) return Buffer.from(info.data[0], info.data[1] || "base64");
  if (typeof info.data === "string") return Buffer.from(info.data, "base64");
  throw new Error("unexpected account data type: " + typeof info.data);
}

function toFile(pubkey, info) {
  return {
    pubkey,
    account: {
      lamports: info.lamports,
      data: [dataBuf(info).toString("base64"), "base64"],
      owner: info.owner.toBase58 ? info.owner.toBase58() : info.owner,
      executable: info.executable,
      rentEpoch: 0, // u64::MAX is not representable as a JS number; irrelevant for cloned accounts
    },
  };
}

async function main() {
  const c = await connect();
  const files = {};
  for (const [name, addr] of Object.entries(ACCTS)) {
    const info = await c.getAccountInfo(new PublicKey(addr));
    if (!info) throw new Error("missing account " + addr);
    const f = toFile(addr, info);
    if (name === "vlist") {
      // craft the precondition: record 0 status byte (offset 9 + 40) -> 3 DeactivatingValidator
      const buf = Buffer.from(f.account.data[0], "base64");
      const before = buf[49];
      buf[49] = 3;
      f.account.data[0] = buf.toString("base64");
      console.log(`vlist record0 status byte ${before} -> ${buf[49]} (DeactivatingValidator)`);
      // sanity: record active lamports
      console.log("record0 active_lamports:", buf.readBigUInt64LE(9).toString());
    }
    const fn = path.join(OUT, name + ".json");
    fs.writeFileSync(fn, JSON.stringify(f));
    files[name] = fn;
    console.log("wrote", fn, info.lamports, info.owner.toBase58 ? info.owner.toBase58() : info.owner);
  }
  fs.writeFileSync(path.join(OUT, "manifest.json"), JSON.stringify({ files, accts: ACCTS }, null, 2));
}

main().catch((e) => { console.error("FATAL", e); process.exit(1); });
