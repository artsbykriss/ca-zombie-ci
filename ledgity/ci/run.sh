#!/usr/bin/env bash
# Custom CI job for the Ledgity Yield deep-dive.
# Light, read-only: snapshot the impl slots + live NAV to ci-out/ (uploaded as an artifact).
# Uses only public keyless RPCs so nothing sensitive is written. NEVER echo secrets.
set -uo pipefail
cd "$(dirname "$0")/.."           # -> ledgity/
mkdir -p ci-out
SLOT=0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
LYV=0x4d462f5fd60b1e4cb3057856d4fce85b48d80bd9
FTV=0x9840172a087a71499d281db985e0c44218fda116
# chain|rpc|name|proxy|expected_impl
rows=(
 "ethereum|https://ethereum-rpc.publicnode.com|lyUSD|0x3C769d0e8D21d380228dFB7918c6933bb6ecB6D4|$LYV"
 "ethereum|https://ethereum-rpc.publicnode.com|lyEUR|0x20968165B7d2cDF33aF632aAB3e0539848d44BC8|$LYV"
 "base|https://mainnet.base.org|lyUSD|0x916f179D5D9B7d8Ad815AC2f8570aabF0C6a6e38|$LYV"
 "base|https://mainnet.base.org|lyEUR|0xFaA1e3720e6Ef8cC76A800DB7B3dF8944833b134|$LYV"
 "base|https://mainnet.base.org|lyREI|0x085b292A7c54767d5371fE939a4Ad4dC9828d98f|$FTV"
 "arbitrum|https://arbitrum-one-rpc.publicnode.com|lyUSD|0x283F35b6406a0e19a786ed119869eF2c0fE157Ee|$LYV"
 "linea|https://rpc.linea.build|lyUSD|0x43b3c64dbc95F9eD83795E051fc00014059e698F|$LYV"
 "sonic|https://rpc.soniclabs.com|lyUSD|0x65f75c675Cc76474662DfBF7B6e8683764223001|$LYV"
)

{
  echo "# Ledgity Yield — CI impl-slot snapshot (public RPCs, read-only)"
  echo "# generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf "%-10s %-8s %-44s %-44s %-8s\n" chain token proxy impl status
  for r in "${rows[@]}"; do
    IFS='|' read -r chain rpc name proxy want <<< "$r"
    word=$(cast storage --rpc-url "$rpc" "$proxy" "$SLOT" 2>/dev/null)
    impl="0x${word: -40}"
    st=PREFIX_OK; [ "${impl,,}" != "${want,,}" ] && st=CHANGED
    printf "%-10s %-8s %-44s %-44s %-8s\n" "$chain" "$name" "$proxy" "$impl" "$st"
  done
} | tee ci-out/impl-slots.txt

{
  echo "# NAV (totalAssets, asset base units) — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  for r in "${rows[@]}"; do
    IFS='|' read -r chain rpc name proxy want <<< "$r"
    ta=$(cast call --rpc-url "$rpc" "$proxy" "totalAssets()(uint256)" 2>/dev/null | sed 's/ .*//')
    echo "$chain $name $proxy totalAssets=$ta"
  done
} | tee ci-out/nav.txt

# lightweight tripwire (non-fatal)
bash analysis/monitor.sh > ci-out/monitor.txt 2>&1 || true
echo "ci job done"
