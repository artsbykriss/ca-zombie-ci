#!/usr/bin/env bash
# ci/run.sh — heavy job for the primus-fhe finding.
# Runs on the GitHub Actions runner (public repo). Writes evidence to ci-out/ (uploaded as artifacts).
# READ-ONLY: only eth_call / eth_getCode / eth_getStorageAt against BSC. No tx is ever sent.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
RPC="${BSC_RPC_URL:-https://bsc-dataseed.binance.org}"
BLK=$(cast block-number --rpc-url "$RPC" 2>/dev/null || echo 0)
echo "BSC fork/read RPC block: $BLK" | tee ci-out/evidence.txt

call() { cast call "$1" "$2" ${3:-} --rpc-url "$RPC" 2>/dev/null || echo "ERR"; }

{
  echo "=== chain: bsc (56) block: $BLK ==="
  echo "--- FHE system ---"
  echo "ACL.owner              $(call 0x3fE3B494Ae2d54fdee94C9fe60365024a44742AE 'owner()(address)')"
  echo "ACL.paused             $(call 0x3fE3B494Ae2d54fdee94C9fe60365024a44742AE 'paused()(bool)')"
  echo "FHEExecutor.owner      $(call 0x12964221F412e3e52F5f0C9592781904266dd9B4 'owner()(address)')"
  echo "Decryption             $(call 0x12964221F412e3e52F5f0C9592781904266dd9B4 'getDecryptionAddress()(address)')"
  echo "SpaceBridgeConfig      $(call 0x12964221F412e3e52F5f0C9592781904266dd9B4 'getSpaceBridgeConfigAddress()(address)')"
  echo "pubDecThreshold        $(call 0x8914af6Bb24Cbff797Be208aBE388927C0FC0396 'getPublicDecryptionThreshold()(uint256)')"
  echo "userDecThreshold       $(call 0x8914af6Bb24Cbff797Be208aBE388927C0FC0396 'getUserDecryptionThreshold()(uint256)')"
  echo "alphatrionThreshold    $(call 0x8914af6Bb24Cbff797Be208aBE388927C0FC0396 'getAlphatrionThreshold()(uint256)')"
  echo "kmsSigners             $(call 0x8914af6Bb24Cbff797Be208aBE388927C0FC0396 'getKmsSigners()(address[])')"
  echo "--- converters (owners + backing) ---"
  echo "eU.owner               $(call 0x3EcB7d91C98ca4B4924e0CC5Eca7472b21F06800 'owner()(address)')"
  echo "eUSDT.owner            $(call 0xc2CC9419DDEb3425876091a1eb79D5C59017838c 'owner()(address)')"
  echo "esUSDu_u.owner         $(call 0x06776741b1f8bfF5ea51750E91edcf03ed8C6994 'owner()(address)')"
  echo "esUSDu_u.restricted    $(call 0x06776741b1f8bfF5ea51750E91edcf03ed8C6994 'transferRestrictionEnabled()(bool)')"
  echo "esUSDu_usdt.restricted $(call 0x75787E2aBEE0ddaa747Eee5F0f4Ff58dB142354d 'transferRestrictionEnabled()(bool)')"
  echo "USDT.bal(eUSDTconv)    $(call 0x55d398326f99059fF775485246999027B3197955 'balanceOf(address)(uint256)' 0xc2CC9419DDEb3425876091a1eb79D5C59017838c)"
  echo "sUSDu.bal(esUSDu_u)    $(call 0x385C279445581a186a4182a5503094eBb652EC71 'balanceOf(address)(uint256)' 0x06776741b1f8bfF5ea51750E91edcf03ed8C6994)"
  echo "sUSDu.bal(esUSDu_usdt) $(call 0x385C279445581a186a4182a5503094eBb652EC71 'balanceOf(address)(uint256)' 0x75787E2aBEE0ddaa747Eee5F0f4Ff58dB142354d)"
  echo "U.bal(eUconv)          $(call 0xcE24439F2D9C6a2289F741120FE202248B666666 'balanceOf(address)(uint256)' 0x3EcB7d91C98ca4B4924e0CC5Eca7472b21F06800)"
  echo "--- aggregators (gating) ---"
  echo "mint_u.keeper          $(call 0xedcDd426f7690c7Da365f8E9BE0C396353e5dd24 'keeper()(address)')"
  echo "mint_u.minAggregateAge $(call 0xedcDd426f7690c7Da365f8E9BE0C396353e5dd24 'minAggregateAge()(uint256)')"
  echo "mint_u.curId           $(call 0xedcDd426f7690c7Da365f8E9BE0C396353e5dd24 'currentAggregateId()(uint256)')"
  echo "redeem_u.keeper        $(call 0xBef1366512ffFF33cdd6C48d66e48D33c6dbCa22 'keeper()(address)')"
  echo "--- Unitas backend ---"
  echo "StakedUSDuV2.owner     $(call 0x385C279445581a186a4182a5503094eBb652EC71 'owner()(address)')"
  echo "StakedUSDuV2.totalSupply $(call 0x385C279445581a186a4182a5503094eBb652EC71 'totalSupply()(uint256)')"
  echo "StakedUSDuV2.totalAssets $(call 0x385C279445581a186a4182a5503094eBb652EC71 'totalAssets()(uint256)')"
  echo "StakedUSDuV2.cooldown  $(call 0x385C279445581a186a4182a5503094eBb652EC71 'cooldownDuration()(uint256)')"
  echo "USDT.bal(UnitasMintingV2) $(call 0x55d398326f99059fF775485246999027B3197955 'balanceOf(address)(uint256)' 0xbB984CE670100AA855f6152f88b26EE57f4EA82A)"
} | tee -a ci-out/evidence.txt

echo "[primus-fhe] evidence written to ci-out/evidence.txt"
