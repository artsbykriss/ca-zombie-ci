#!/usr/bin/env bash
# zkLink Nova — live pause / payout-gate verification (read-only).
# Public RPC only; no keys, no broadcasts.
set -uo pipefail
R="${ETH_RPC:-https://eth.drpc.org}"
ZK=0x5fd9f73286b7e8683bab45019c94553b93e015cf
ARB=0x1ee09a2caa0813a5183f90f5a6d0e4871f4c6002
BP=0xad16edcf7deb7e90096a259c81269d811544b6b6
RELAYER=0x0fdc28e64772a70109d10fd068f859cfa7dea2c6
GATEWAY=0x83bc7394738a7a084081af22eec0051908c0055c
IMP_SLOT=0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc

B=$(cast block-number --rpc-url "$R")
echo "block=$B"
echo "paused=$(cast call $ZK 'paused()(bool)' --block "$B" --rpc-url "$R")"
echo "owner=$(cast call $ZK 'owner()(address)' --block "$B" --rpc-url "$R")"
echo "zk_balance_wei=$(cast balance $ZK --block "$B" --rpc-url "$R")"
echo "bridge_balance_wei=$(cast balance $BP --block "$B" --rpc-url "$R")"
echo "fee_total=$(cast call $ZK 'totalValidatorForwardFee()(uint256)' --block "$B" --rpc-url "$R" | awk '{print $1}')"
echo "fee_withdrawn=$(cast call $ZK 'totalValidatorForwardFeeWithdrawn()(uint256)' --block "$B" --rpc-url "$R" | awk '{print $1}')"
echo "fee_allocator=$(cast call $ZK 'forwardFeeAllocator()(address)' --block "$B" --rpc-url "$R")"
echo "arb_impl=$(cast storage $ARB $IMP_SLOT --block "$B" --rpc-url "$R")"
echo "relayer_active=$(cast call $ARB 'relayers(address)(bool)' $RELAYER --block "$B" --rpc-url "$R")"
echo "secondary_gateway_active=$(cast call $ARB 'secondaryChainGateways(address)(bool)' $GATEWAY --block "$B" --rpc-url "$R")"
echo -n "proveL2MessageInclusion="
cast call $ZK 'proveL2MessageInclusion(uint256,uint256,(uint16,address,bytes),bytes32[])' 0 0 '(0,0x000000000000000000000000000000000000dEaD,0x)' '[]' --from 0x000000000000000000000000000000000000dEaD --block "$B" --rpc-url "$R" 2>&1 | head -1
echo -n "requestL2Transaction="
cast call $ZK 'requestL2Transaction(address,uint256,bytes,uint256,uint256,bytes[],address)' 0x000000000000000000000000000000000000dEaD 0 0x 100000 800 '[]' 0x000000000000000000000000000000000000dEaD --from 0x000000000000000000000000000000000000dEaD --block "$B" --rpc-url "$R" 2>&1 | head -1
echo -n "withdrawForwardFee_sim="
FEE_DELTA=$(python3 -c "print($(cast call $ZK 'totalValidatorForwardFee()(uint256)' --block "$B" --rpc-url "$R" | awk '{print $1}') - $(cast call $ZK 'totalValidatorForwardFeeWithdrawn()(uint256)' --block "$B" --rpc-url "$R" | awk '{print $1}'))")
cast call $ZK 'withdrawForwardFee(address,uint256)' 0xdb4D755E3b8735314147b9bB146327C269701E2D "$FEE_DELTA" --from 0xdb4D755E3b8735314147b9bB146327C269701E2D --block "$B" --rpc-url "$R" 2>&1 | head -1
echo "fee_delta_wei=$FEE_DELTA"
