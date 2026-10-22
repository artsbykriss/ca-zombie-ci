// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// Minimal interfaces for the LIVE Burve SimplexDiamond on Berachain (chain 80094).
/// Addresses/selectors verified on-chain (see burve/analysis/facets.txt + diamond_state.py).

interface IERC20Like {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
}

interface IERC4626Like {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function convertToAssets(uint256) external view returns (uint256);
    function previewRedeem(uint256) external view returns (uint256);
    function asset() external view returns (address);
}

/// The live Diamond (multi "Omni-Pool"). Only the functions we touch.
interface IBurveDiamond {
    // SimplexGetFacet
    function getTokens() external view returns (address[] memory);
    function getNumVertices() external view returns (uint8);
    function getClosureValue(uint16 cid)
        external
        view
        returns (
            uint8 n,
            uint256 targetX128,
            uint256[16] memory balances,
            uint256 valueStaked,
            uint256 bgtValueStaked
        );
    function getClosureFees(uint16 cid)
        external
        view
        returns (
            uint256[16] memory earningsPerValueX128,
            uint256 bgtPerBgtValueX128,
            uint256[16] memory unexchangedPerBgtValueX128
        );
    function getSimplexFees() external view returns (uint128 defaultEdgeFeeX128, uint128 protocolTakeX128);
    function getEdgeFee(uint8 a, uint8 b) external view returns (uint128);
    function getIdx(address token) external view returns (uint8);
    function getAdjustor() external view returns (address);
    function owner() external view returns (address);

    // QueryValueFacet
    function queryValue(address owner, uint16 cid)
        external
        view
        returns (uint256 value, uint256 bgtValue, uint256[16] memory earnings, uint256 bgtEarnings);

    // ValueFacet
    function addValue(address recipient, uint16 cid, uint128 value, uint128 bgtValue, uint256[16] calldata limits)
        external
        returns (uint256[16] memory);
    function removeValue(address recipient, uint16 cid, uint128 value, uint128 bgtValue, uint256[16] calldata limits)
        external
        returns (uint256[16] memory);
    function collectEarnings(address recipient, uint16 cid)
        external
        returns (uint256[16] memory collectedBalances, uint256 collectedBgt);

    // ValueSingleFacet
    function addValueSingle(address recipient, uint16 cid, uint128 value, uint128 bgtValue, address token, uint128 maxRequired)
        external
        returns (uint256 requiredBalance);
    function removeValueSingle(address recipient, uint16 cid, uint128 value, uint128 bgtValue, address token, uint128 minReceive)
        external
        returns (uint256 removedBalance);

    // Add/RemoveTokenValueFacet
    function addSingleForValue(address recipient, uint16 cid, address token, uint128 amount, uint256 bgtPercentX256, uint128 minValue)
        external
        returns (uint256 valueReceived);
    function removeSingleForValue(address recipient, uint16 cid, address token, uint128 amount, uint256 bgtPercentX256, uint128 maxValue)
        external
        returns (uint256 valueGiven);

    // SwapFacet
    function swap(address recipient, address inToken, address outToken, int256 amountSpecified, uint256 amountLimit, uint16 cid)
        external
        returns (uint256 inAmount, uint256 outAmount);
    function simSwap(address inToken, address outToken, int256 amountSpecified, uint16 cid)
        external
        view
        returns (uint256 inAmount, uint256 outAmount, uint256 valueExchangedX128);

    // VaultFacet
    function viewVaults(address token) external view returns (address active, address backup);

    // LockFacet
    function isLocked(address token) external view returns (bool);
}
