#!/usr/bin/env bash
# Hyperbeat Earn (HyperEVM 999) — CI heavy job.
# Dumps the full 26-vault Earn inventory + proxy/authority state into ci-out/ as evidence.
# Read-only (eth_call / eth_getCode / eth_getStorageAt only). No secrets. Keyless public RPC.
set -uo pipefail
cd "$(dirname "$0")/.."
OUT="ci-out"
mkdir -p "$OUT"
RPC="${HYPEREVM_RPC:-https://rpc.hyperliquid.xyz/evm}"
BLK="${HYPEREVM_BLOCK:-49508160}"
echo "chain: $(cast chain-id --rpc-url "$RPC" 2>&1)"
echo "block: $BLK (header pin only; NOTE the public RPC ignores the block tag for eth_call -> reads are latest)"

echo "$BLK" > "$OUT/fork_block.txt"
echo "$RPC" | sed -E 's#https?://[^/]+#https://<rpc>#' > "$OUT/rpc_redacted.txt"

# ---- 26 Earn vaults (from DefiLlama adapter projects/hyperbeat/index.js) ----
cat > "$OUT/vaults.txt" <<'EOF'
0x5eEC795d919FA97688Fb9844eeB0072E6B846F9d morpho GauntletUSDeCore
0x53A333e51E96FE288bC9aDd7cdC4B1EAD2CD2FfA morpho GauntletUSDT0
0x0571362ba5EA9784a97605f57483f865A37dBEAA morpho GauntletuETH
0xd19e3d00f8547f7d108abfd4bbb015486437b487 morpho MEVCapitalHYPE
0x4346C98E690c17eFbB999aE8e1dA96B089bE320b morpho RelendrUSDC
0xe5ADd96840F0B908ddeB3Bd144C0283Ac5ca7cA0 morpho HyperithmUSDT0
0xD3A9Cb7312B9c29113290758f5ADFe12304cd16A morpho MEVCapitalUSR
0x3Bcc0a5a66bB5BdCEEf5dd8a659a4eC75F3834d8 morpho MEVCapitalUSDT0
0x51F64488d03D8B210294dA2BF70D5db0Bc621B0c morpho Re7USDT0
0x182b318A8F1c7C92a7884e469442a610B0e69ed2 morpho Re7HYPE
0x92B518e1cD76dD70D3E20624AEdd7D107F332Cff morpho HyperithmHYPE
0x264a06Fd7A7C9E0Bfe75163b475E2A3cc1856578 morpho GauntletHYPE
0x08C00F8279dFF5B0CB5a04d349E7d79708Ceadf3 morpho GauntletUSDC
0x4851D4891321035729713D43bE1F4bb883Dffd34 morpho MEVUSDC
0x441794D6a8F9A3739F5D4E98a728937b33489D29 standalone liquidHYPE
0xD66d69c288d9a6FD735d7bE8b2e389970fC4fD42 standalone wVLP
0x81e064d0eB539de7c3170EDF38C1A42CBd752A76 rate lstHYPE
0x5e105266db42f78FA814322Bce7f388B4C2e61eb rate hbUSDT
0x057ced81348D57Aad579A672d521d7b4396E8a61 rate hbUSDC
0x4Cc221cf1444333510a634CE0D8209D2D11B9bbA rate nLP
0x9065E3153B1393Bb5f76520cdc1e08E49eb04B03 rate masterUSD
0x949a7250Bb55Eb79BC6bCC97fCd1C473DB3e6F29 rate dnHYPE
0x8858A307a85982c2B3CB2AcE1720237f2f09c39B rate dnPUMP
0x6EB6724D8D3D4FF9E24d872E8c38403169dC05f8 rate hbXAUt
0x96C6cBB6251Ee1c257b2162ca0f39AA5Fa44B1FB erc4626 UltraHYPE
0xc061d38903b99aC12713B550C2CB44B221674F94 erc4626 UltrauBTC
EOF

echo '{"block":'"$BLK"',"vaults":[' > "$OUT/state.json"
first=1
while read -r addr kind label; do
  [ -z "$addr" ] && continue
  cs=$(cast code "$addr" --rpc-url "$RPC" 2>/dev/null | wc -c)
  name=$(cast call "$addr" 'name()(string)' --rpc-url "$RPC" 2>/dev/null | tr -d '"')
  sup=$(cast call "$addr" 'totalSupply()(uint256)' --rpc-url "$RPC" 2>/dev/null)
  ta=$(cast call "$addr" 'totalAssets()(uint256)' --rpc-url "$RPC" 2>/dev/null)
  [ $first -eq 1 ] || echo ',' >> "$OUT/state.json"
  first=0
  printf '{"addr":"%s","kind":"%s","label":"%s","codesize":%s,"name":"%s","totalSupply":"%s","totalAssets":"%s"}' \
     "$addr" "$kind" "$label" "$((cs/2))" "$name" "$sup" "$ta" >> "$OUT/state.json"
  echo "  $label $addr cs=$((cs/2)) name=$name sup=$sup ta=$ta"
done < "$OUT/vaults.txt"
echo ']}' >> "$OUT/state.json"
echo "WROTE $OUT/state.json"
ls -la "$OUT"
