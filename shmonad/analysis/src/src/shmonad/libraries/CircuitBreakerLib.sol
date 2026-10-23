// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.28 <0.9.0;

import { FixedPointMathLib as Math } from "@solady/utils/FixedPointMathLib.sol";

library CircuitBreakerLib {
    function isNonDecreasingRate(
        uint256 previousAssets,
        uint256 previousShares,
        uint256 nextAssets,
        uint256 nextShares,
        uint256 virtualShares
    )
        internal
        pure
        returns (bool)
    {
        if (previousShares == 0 || nextShares == 0) return true;

        uint256 previousVirtualAssets = previousAssets + 1;
        uint256 previousVirtualShares = previousShares + virtualShares;
        uint256 nextVirtualAssets = nextAssets + 1;
        uint256 nextVirtualShares = nextShares + virtualShares;

        // Compare the same virtual-offset rate used for ERC-4626 share pricing:
        // (assets + 1) / (shares + virtualShares). This intentionally allows tiny changes in the unvirtualized
        // equity/supply rate when the virtual pricing formula is followed.
        uint256 normalizedNextAssets = Math.mulDivUp(nextVirtualAssets, previousVirtualShares, nextVirtualShares);
        return normalizedNextAssets >= previousVirtualAssets || previousVirtualAssets - normalizedNextAssets <= 1;
    }
}
