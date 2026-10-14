#!/usr/bin/env bash
# PandaSwap L2 Phase-2 custom CI job: 0.5.16 verification build + full live enumeration/proofs.
set -uo pipefail
mkdir -p ci-out

echo "== [1/3] 0.5.16 verification build (poc05) =="
if [ -d poc05 ]; then
  (
    cd poc05
    forge build 2>&1 | tail -5
    forge inspect src/PandaSwapUniswapV2.sol:UniswapV2Pair deployedBytecode > ../ci-out/pair_compiled_runtime.hex
    forge inspect src/PandaSwapUniswapV2.sol:UniswapV2Factory deployedBytecode > ../ci-out/factory_compiled_runtime.hex
  ) || echo "poc05 build/inspect failed (continuing)"
fi

echo "== [2/3] enumeration + proofs =="
python3 ci/enumerate_ci.py

echo "== [3/3] done =="
