#!/usr/bin/env node
/**
 * Phase Stake (C2-41) — read-only chain-native simulation.
 *
 * Simulates transactions against live mainnet state via `simulateTransaction`
 * (sigVerify=false, replaceRecentBlockhash=true). NOTHING IS SENT OR SIGNED FOR REAL.
 * No secrets, keyless public RPC endpoints only.
 *
 * What it proves:
 *  A) DepositSol is permissionless (no deposit-authority signature) and mints YIELD at NAV.
 *  B) DepositSol + WithdrawStake round trip is permissionless for the token holder and
 *     returns exactly NAV minus the 0.1% stake-withdrawal fee (no free value).
 *  C) WithdrawSol is gated by sol_withdraw_authority (phaseUTHS...): without its signature
 *     the instruction fails (SOL exits are permissioned).
 *  D) WithdrawStake from the reserve while validator stake exists is blocked.
 *
 * Outputs JSON + human log to ci-out/.
 */
const fs = require("fs");
const path = require("path");
const {
  Connection, PublicKey, Keypair, Transaction, TransactionInstruction,
  SystemProgram, SYSVAR_CLOCK_PUBKEY, SYSVAR_STAKE_HISTORY_PUBKEY, SYSVAR_RENT_PUBKEY,
} = require("@solana/web3.js");

// ---------------------------------------------------------------- constants
const PROG = new PublicKey("SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn");
const POOL = new PublicKey("phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG");
const WITHDRAW_AUTH = new PublicKey("9HYjrCF5evTobLmay372kpUWSNTrtmDU2NkQtqjdnHKa");
const RESERVE = new PublicKey("phaseECAeXantYWXvRGkmeh7ddQsUJTf7DcywquY9Z2");
const VLIST = new PublicKey("phaseeExd43yGjjad2FZSigdG9UTRpMdxS4aMerx821");
const MINT = new PublicKey("phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG");
const MGR_FEE = new PublicKey("GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U");
const STAKE_ACCT = new PublicKey("8QtQ1U34DPs2UKQiwUoRPMHnjJedsmdASZdbQHa7VHKh");
const SOL_WITHDRAW_AUTH = new PublicKey("phaseUTHSD78uiD8rnRQWuvbEakvY1chNSeftkpvz6d");
const STAKE_PROG = new PublicKey("Stake11111111111111111111111111111111111111");
const TOKEN_PROG = new PublicKey("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA");
const ATA_PROG = new PublicKey("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL");
const SYSTEM = SystemProgram.programId;

const RPC_LIST = [
  process.env.SOL_RPC,
  "https://solana-rpc.publicnode.com",
  "https://api.mainnet-beta.solana.com",
].filter(Boolean);

const OUT_DIR = path.join(__dirname, "..", "ci-out");
fs.mkdirSync(OUT_DIR, { recursive: true });
const out = { started: new Date().toISOString(), rpc: null, slot: null, pool: {}, sims: {}, notes: [] };

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
function log(...a) { console.log(...a); }

async function rpcRaw(url, method, params, tries = 3) {
  for (let i = 0; i < tries; i++) {
    try {
      const res = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ jsonrpc: "2.0", id: 1, method, params }),
      });
      const j = await res.json();
      if (j.error) throw new Error(JSON.stringify(j.error));
      return j.result;
    } catch (e) {
      if (i === tries - 1) throw e;
      await sleep(1500 * (i + 1));
    }
  }
}

async function pickRpc() {
  for (const u of RPC_LIST) {
    try {
      const v = await rpcRaw(u, "getVersion", []);
      if (v && v["solana-core"]) { out.rpc = u; return u; }
    } catch (e) { /* next */ }
  }
  throw new Error("no working public RPC");
}

let RPC = null;
async function rpc(method, params) { return rpcRaw(RPC, method, params, 4); }

function u64le(n) {
  const b = Buffer.alloc(8);
  b.writeBigUInt64LE(BigInt(n));
  return b;
}
function u32le(n) {
  const b = Buffer.alloc(4);
  b.writeUInt32LE(Number(n));
  return b;
}
function readU64LE(buf, off) { return buf.readBigUInt64LE(off); }

function ix(programId, keys, data) {
  return new TransactionInstruction({
    programId,
    keys: keys.map(([pubkey, isSigner, isWritable]) => ({ pubkey, isSigner, isWritable })),
    data,
  });
}

async function simulate(name, instructions, feePayer, extraAddresses = []) {
  const tx = new Transaction();
  tx.add(...instructions);
  tx.feePayer = feePayer;
  tx.recentBlockhash = "11111111111111111111111111111111"; // replaced server-side
  const b64 = tx.serialize({ requireAllSignatures: false, verifySignatures: false }).toString("base64");
  const addresses = [POOL.toString(), RESERVE.toString(), MINT.toString(), ...extraAddresses];
  const res = await rpc("simulateTransaction", [
    b64,
    { encoding: "base64", sigVerify: false, replaceRecentBlockhash: true,
      accounts: { encoding: "base64", addresses } },
  ]);
  const value = res.value;
  const accounts = {};
  for (let i = 0; i < addresses.length; i++) {
    const a = value.accounts[i];
    if (a && a.data) accounts[addresses[i]] = a.data[0];
  }
  const rec = {
    name, err: value.err, unitsConsumed: value.unitsConsumed,
    logs: (value.logs || []).filter((l) => /Program log|Program returned error|consumed/.test(l)).slice(0, 60),
    accounts,
  };
  out.sims[name] = rec;
  log(`\n=== ${name} ===`);
  log(`err: ${JSON.stringify(rec.err)} units: ${rec.unitsConsumed}`);
  for (const l of rec.logs.slice(-12)) log("  " + l);
  return rec;
}

function tokenAmount(b64) {
  if (!b64) return null;
  const buf = Buffer.from(b64, "base64");
  if (buf.length < 165) return null;
  return readU64LE(buf, 64).toString();
}
function stakeInfo(b64) {
  if (!b64) return null;
  const buf = Buffer.from(b64, "base64");
  if (buf.length < 200) return null;
  const tag = buf.readUInt32LE(0);
  const voter = new PublicKey(buf.subarray(124, 156)).toString();
  return {
    tag,
    rentExemptReserve: readU64LE(buf, 4).toString(),
    staker: new PublicKey(buf.subarray(12, 44)).toString(),
    withdrawer: new PublicKey(buf.subarray(44, 76)).toString(),
    voter, stake: readU64LE(buf, 156).toString(),
    activationEpoch: readU64LE(buf, 164).toString(),
    deactivationEpoch: readU64LE(buf, 172).toString(),
  };
}

async function main() {
  RPC = await pickRpc();
  log(`RPC: ${RPC}`);
  const slot = await rpc("getSlot", []);
  out.slot = slot;

  // ---- live pool state
  const acct = await rpc("getAccountInfo", [POOL.toString(), { encoding: "base64" }]);
  const pdata = Buffer.from(acct.value.data[0], "base64");
  const totalLamports = readU64LE(pdata, 258);
  const supply = readU64LE(pdata, 266);
  const lastUpdateEpoch = readU64LE(pdata, 274);
  const epochInfo = await rpc("getEpochInfo", []);
  out.pool = {
    totalLamports: totalLamports.toString(),
    poolTokenSupply: supply.toString(),
    navLamportsPerToken: Number(totalLamports * 1000000000n / supply) / 1e9,
    lastUpdateEpoch: lastUpdateEpoch.toString(),
    currentEpoch: epochInfo.epoch,
    fresh: lastUpdateEpoch.toString() === String(epochInfo.epoch),
    reserveLamports: (await rpc("getBalance", [RESERVE.toString()])).value,
  };
  log("pool:", JSON.stringify(out.pool));
  if (!out.pool.fresh) {
    out.notes.push("Pool state stale for current epoch; deposit/withdraw sims would revert StakeListAndPoolOutOfDate. Run again or crank UpdateValidatorListBalance+UpdateStakePoolBalance.");
  }

  // ---- funded stand-in payer (simulation only needs *some* funded fee payer; sigVerify=false)
  let payer = null, payerBal = 0;
  try {
    for (const u of RPC_LIST) {
      try {
        const largest = await rpcRaw(u, "getLargestAccounts", [{ commitment: "finalized" }]);
        payer = new PublicKey(largest.value[0].address);
        break;
      } catch (e) { /* next */ }
    }
  } catch (e) { /* fall through */ }
  if (!payer) {
    // fallback: take the fee payer of a recent real transaction touching the pool
    const sigs = await rpc("getSignaturesForAddress", [POOL.toString(), { limit: 5 }]);
    for (const s of sigs) {
      try {
        const tx = await rpc("getTransaction", [s.signature, { encoding: "json", maxSupportedTransactionVersion: 0 }]);
        const keys = tx && tx.transaction && tx.transaction.message && tx.transaction.message.accountKeys;
        if (!keys || !keys.length) continue;
        const cand = new PublicKey(keys[0].pubkey || keys[0]);
        const bal = (await rpc("getBalance", [cand.toString()])).value;
        if (bal > 3_000_000_000) { payer = cand; break; }
      } catch (e) { /* next */ }
    }
  }
  if (!payer) throw new Error("could not determine a funded stand-in payer");
  payerBal = (await rpc("getBalance", [payer.toString()])).value;
  out.payer = { address: payer.toString(), lamports: payerBal };
  log(`stand-in funded payer (no signature used): ${payer} (${payerBal / 1e9} SOL)`);

  // ---- attacker: fresh random keypair, owns destination accounts
  const attacker = Keypair.generate();
  const [attackerAta] = PublicKey.findProgramAddressSync(
    [attacker.publicKey.toBuffer(), TOKEN_PROG.toBuffer(), MINT.toBuffer()], ATA_PROG);
  out.attacker = { pubkey: attacker.publicKey.toString(), ata: attackerAta.toString() };
  log(`fresh attacker pubkey: ${attacker.publicKey}  ATA: ${attackerAta}`);

  const DEPOSIT = 2_000_000_000n; // 2 SOL
  const expectedMint = (DEPOSIT * supply) / totalLamports;
  out.expectedMint = expectedMint.toString();
  log(`deposit ${Number(DEPOSIT) / 1e9} SOL -> expected mint ${expectedMint} raw YIELD (NAV)`);

  const createAtaIx = ix(ATA_PROG, [
    [payer, true, true], [attackerAta, false, true], [attacker.publicKey, false, false],
    [MINT, false, false], [SYSTEM, false, false], [TOKEN_PROG, false, false],
  ], Buffer.alloc(0));

  const depositIx = ix(PROG, [
    [POOL, false, true], [WITHDRAW_AUTH, false, false], [RESERVE, false, true],
    [payer, true, true], [attackerAta, false, true], [MGR_FEE, false, true],
    [attackerAta, false, true], [MINT, false, true], [SYSTEM, false, false], [TOKEN_PROG, false, false],
  ], Buffer.concat([Buffer.from([14]), u64le(DEPOSIT)])); // DepositSol

  // ============ SIM A: deposit only
  const simA = await simulate("A_deposit_sol", [createAtaIx, depositIx], payer, [attackerAta.toString()]);
  out.sims.A_minted = tokenAmount(simA.accounts[attackerAta.toString()]);
  out.sims.A_mint_matches_nav = out.sims.A_minted === expectedMint.toString();
  log(`minted (post-sim ATA state): ${out.sims.A_minted} expected ${expectedMint} match=${out.sims.A_mint_matches_nav}`);

  // ============ SIM B: deposit + withdraw stake (round trip)
  const minted = BigInt(out.sims.A_minted || expectedMint);
  const stakeDest = Keypair.generate();
  const rent = await rpc("getMinimumBalanceForRentExemption", [200]);
  const createStakeDestIx = SystemProgram.createAccount({
    fromPubkey: payer, newAccountPubkey: stakeDest.publicKey,
    lamports: rent, space: 200, programId: STAKE_PROG,
  });
  const withdrawStakeIx = ix(PROG, [
    [POOL, false, true], [VLIST, false, true], [WITHDRAW_AUTH, false, false],
    [STAKE_ACCT, false, true], [stakeDest.publicKey, false, true],
    [attacker.publicKey, false, false], [attacker.publicKey, true, false],
    [attackerAta, false, true], [MGR_FEE, false, true], [MINT, false, true],
    [SYSVAR_CLOCK_PUBKEY, false, false], [TOKEN_PROG, false, false], [STAKE_PROG, false, false],
  ], Buffer.concat([Buffer.from([10]), u64le(minted)])); // WithdrawStake(all minted)
  const simB = await simulate("B_deposit_then_withdraw_stake",
    [createAtaIx, depositIx, createStakeDestIx, withdrawStakeIx], payer,
    [attackerAta.toString(), stakeDest.publicKey.toString()]);
  out.sims.B_stake_received = stakeInfo(simB.accounts[stakeDest.publicKey.toString()]);
  out.sims.B_ata_after = tokenAmount(simB.accounts[attackerAta.toString()]);
  log(`stake account after round trip: ${JSON.stringify(out.sims.B_stake_received)}`);
  log(`attacker YIELD after: ${out.sims.B_ata_after}`);

  // ============ SIM C1: deposit + withdraw SOL, authority account omitted
  const withdrawSolNoAuthIx = ix(PROG, [
    [POOL, false, true], [WITHDRAW_AUTH, false, false], [attacker.publicKey, true, false],
    [attackerAta, false, true], [RESERVE, false, true], [attacker.publicKey, false, true],
    [MGR_FEE, false, true], [MINT, false, true], [SYSVAR_CLOCK_PUBKEY, false, false],
    [SYSVAR_STAKE_HISTORY_PUBKEY, false, false], [STAKE_PROG, false, false], [TOKEN_PROG, false, false],
  ], Buffer.concat([Buffer.from([16]), u64le(minted)])); // WithdrawSol (no authority account)
  await simulate("C1_withdraw_sol_no_authority", [createAtaIx, depositIx, withdrawSolNoAuthIx], payer, [attackerAta.toString()]);

  // ============ SIM C2: deposit + withdraw SOL, authority present but NOT signer
  const withdrawSolUnsignedIx = ix(PROG, [
    [POOL, false, true], [WITHDRAW_AUTH, false, false], [attacker.publicKey, true, false],
    [attackerAta, false, true], [RESERVE, false, true], [attacker.publicKey, false, true],
    [MGR_FEE, false, true], [MINT, false, true], [SYSVAR_CLOCK_PUBKEY, false, false],
    [SYSVAR_STAKE_HISTORY_PUBKEY, false, false], [STAKE_PROG, false, false], [TOKEN_PROG, false, false],
    [SOL_WITHDRAW_AUTH, false, false], // present, non-signer
  ], Buffer.concat([Buffer.from([16]), u64le(minted)])); // WithdrawSol
  await simulate("C2_withdraw_sol_unsigned_authority", [createAtaIx, depositIx, withdrawSolUnsignedIx], payer, [attackerAta.toString()]);

  // ============ SIM D: withdraw stake sourced from the reserve
  const withdrawStakeFromReserveIx = ix(PROG, [
    [POOL, false, true], [VLIST, false, true], [WITHDRAW_AUTH, false, false],
    [RESERVE, false, true], [stakeDest.publicKey, false, true],
    [attacker.publicKey, false, false], [attacker.publicKey, true, false],
    [attackerAta, false, true], [MGR_FEE, false, true], [MINT, false, true],
    [SYSVAR_CLOCK_PUBKEY, false, false], [TOKEN_PROG, false, false], [STAKE_PROG, false, false],
  ], Buffer.concat([Buffer.from([10]), u64le(minted)])); // WithdrawStake(reserve)
  await simulate("D_withdraw_stake_from_reserve",
    [createAtaIx, depositIx, createStakeDestIx, withdrawStakeFromReserveIx], payer,
    [attackerAta.toString(), stakeDest.publicKey.toString()]);

  // ============ SIM E: attacker tries SetFee (expect WrongManager=6)
  const setFeeIx = ix(PROG, [[POOL, false, true], [attacker.publicKey, true, false]],
    Buffer.concat([Buffer.from([12, 2]), u64le(100), u64le(1)])); // SetFee{Epoch(Fee{denom:100,num:1})}
  await simulate("E_setfee_as_attacker", [setFeeIx], payer);

  // ============ SIM F: attacker tries AddValidatorToPool (expect WrongStaker=21)
  const stakeConfig = new PublicKey("StakeConfig11111111111111111111111111111111");
  const addValidatorIx = ix(PROG, [
    [POOL, false, true], [attacker.publicKey, true, false], [RESERVE, false, true],
    [WITHDRAW_AUTH, false, false], [VLIST, false, true], [RESERVE, false, true],
    [new PublicKey("CiTYUYPAPHdcri5yEfsmqVcs54J6j8X1QaiFLgYqMVe"), false, false],
    [SYSVAR_RENT_PUBKEY, false, false], [SYSVAR_CLOCK_PUBKEY, false, false],
    [SYSVAR_STAKE_HISTORY_PUBKEY, false, false], [stakeConfig, false, false],
    [SYSTEM, false, false], [STAKE_PROG, false, false],
  ], Buffer.concat([Buffer.from([1]), Buffer.alloc(4)])); // AddValidatorToPool(seed=0)
  await simulate("F_add_validator_as_attacker", [addValidatorIx], payer);

  // ============ SIM G: permissionless crank UpdateStakePoolBalance (expect success)
  const updateIx = ix(PROG, [
    [POOL, false, true], [WITHDRAW_AUTH, false, false], [VLIST, false, true],
    [RESERVE, false, false], [MGR_FEE, false, true], [MINT, false, true], [TOKEN_PROG, false, false],
  ], Buffer.from([7])); // UpdateStakePoolBalance
  await simulate("G_update_pool_balance_permissionless", [updateIx], payer);

  // ============ SIM H: fresh attacker deposits STAKE (permissionless via default deposit PDA)
  const attackerStake = Keypair.generate();
  const DEPOSIT_STAKE = 1_500_000_000n; // 1.5 SOL
  const depositPda = PublicKey.findProgramAddressSync(
    [POOL.toBuffer(), Buffer.from("deposit")], PROG)[0];
  const createDepositStakeIx = SystemProgram.createAccount({
    fromPubkey: payer, newAccountPubkey: attackerStake.publicKey,
    lamports: 1_500_000_000, space: 200, programId: STAKE_PROG,
  });
  const stakeInitIx = ix(STAKE_PROG, [[attackerStake.publicKey, false, true], [SYSVAR_RENT_PUBKEY, false, false]],
    Buffer.concat([u32le(0), attacker.publicKey.toBuffer(), depositPda.toBuffer(), Buffer.alloc(48)])); // Initialize(staker=attacker, withdrawer=deposit PDA) (bincode)
  const stakeDelegateIx = ix(STAKE_PROG, [
    [attackerStake.publicKey, false, true],
    [new PublicKey("CiTYUYPAPHdcri5yEfsmqVcs54J6j8X1QaiFLgYqMVe"), false, false],
    [SYSVAR_CLOCK_PUBKEY, false, false], [SYSVAR_STAKE_HISTORY_PUBKEY, false, false],
    [new PublicKey("StakeConfig11111111111111111111111111111111"), false, false],
    [attacker.publicKey, true, false],
  ], u32le(2)); // DelegateStake (bincode; staker signs)
  const stakeAuthorizeStakerIx = ix(STAKE_PROG, [
    [attackerStake.publicKey, false, true], [SYSVAR_CLOCK_PUBKEY, false, false],
    [attacker.publicKey, true, false],
  ], Buffer.concat([u32le(1), depositPda.toBuffer(), u32le(0)])); // Authorize(staker->deposit PDA)
  const stakeAuthorizeWithdrawerIx = ix(STAKE_PROG, [
    [attackerStake.publicKey, false, true], [SYSVAR_CLOCK_PUBKEY, false, false],
    [attacker.publicKey, true, false],
  ], Buffer.concat([u32le(1), depositPda.toBuffer(), u32le(1)])); // Authorize(withdrawer->deposit PDA)
  const depositStakeIx = ix(PROG, [
    [POOL, false, true], [VLIST, false, true], [depositPda, false, false], [WITHDRAW_AUTH, false, false],
    [attackerStake.publicKey, false, true], [STAKE_ACCT, false, true], [RESERVE, false, true],
    [attackerAta, false, true], [MGR_FEE, false, true], [attackerAta, false, true], [MINT, false, true],
    [SYSVAR_CLOCK_PUBKEY, false, false], [SYSVAR_STAKE_HISTORY_PUBKEY, false, false],
    [TOKEN_PROG, false, false], [STAKE_PROG, false, false],
  ], Buffer.from([9])); // DepositStake
  const simH = await simulate("H_deposit_stake_fresh_attacker",
    [createAtaIx, createDepositStakeIx, stakeInitIx, stakeDelegateIx, stakeAuthorizeStakerIx, depositStakeIx],
    payer, [attackerAta.toString(), attackerStake.publicKey.toString()]);
  out.sims.H_minted = tokenAmount(simH.accounts[attackerAta.toString()]);
  out.sims.H_expected_nav = ((DEPOSIT_STAKE * supply) / totalLamports).toString();
  log(`deposit stake ${Number(DEPOSIT_STAKE) / 1e9} SOL -> minted ${out.sims.H_minted} (NAV expected ~${out.sims.H_expected_nav})`);

  out.finished = new Date().toISOString();
  fs.writeFileSync(path.join(OUT_DIR, "simulation.json"), JSON.stringify(out, null, 2));
  log("\nwrote ci-out/simulation.json");
}

main().catch((e) => {
  out.error = String(e && e.stack || e);
  fs.writeFileSync(path.join(OUT_DIR, "simulation.json"), JSON.stringify(out, null, 2));
  console.error("FATAL", e);
  process.exit(1);
});
