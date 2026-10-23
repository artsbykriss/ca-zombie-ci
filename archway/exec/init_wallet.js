#!/usr/bin/env node
/* Generate the Archway operational burner account (24-word mnemonic, prefix archway).
 * Saves to exec/.archway_key.json (chmod 600, git-ignored). No network calls. */
const fs = require("fs");
const path = require("path");
const { DirectSecp256k1HdWallet } = require("@cosmjs/proto-signing");

(async () => {
  const KEY_PATH = path.join(__dirname, ".archway_key.json");
  if (fs.existsSync(KEY_PATH)) {
    const d = JSON.parse(fs.readFileSync(KEY_PATH, "utf8"));
    console.log("wallet already exists:", d.address);
    return;
  }
  const wallet = await DirectSecp256k1HdWallet.generate(24, { prefix: "archway" });
  const [account] = await wallet.getAccounts();
  fs.writeFileSync(KEY_PATH, JSON.stringify({ address: account.address, mnemonic: wallet.mnemonic }, null, 1));
  fs.chmodSync(KEY_PATH, 0o600);
  console.log("archway burner created:", account.address);
  console.log("key saved to", KEY_PATH);
})();
