// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

struct PoolKey {
    address currency0;
    address currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

interface IPoolManager {
    struct SwapParams {
        bool zeroForOne;
        int256 amountSpecified;
        uint160 sqrtPriceLimitX96;
    }

    function unlock(bytes calldata data) external returns (bytes memory);
    function swap(PoolKey memory key, SwapParams memory params, bytes calldata hookData)
        external
        returns (int256);
    function take(address currency, address to, uint256 amount) external;
    function settle() external payable returns (uint256);
    function sync(address currency) external;
    function balanceOf(address owner, uint256 id) external view returns (uint256);
    function getSlot0(bytes32 id) external view returns (uint160, int24, uint24, uint24);
    function getLiquidity(bytes32 id) external view returns (uint128);
}

/// @notice Minimal Uniswap v4 swap harness (read-only fork use). Settles its own deltas.
contract SwapHarness {
    IPoolManager public immutable pm;

    constructor(IPoolManager _pm) {
        pm = _pm;
    }

    receive() external payable {}

    function swap(PoolKey memory key, IPoolManager.SwapParams memory p)
        external
        returns (int256 delta)
    {
        delta = abi.decode(pm.unlock(abi.encode(key, p)), (int256));
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        require(msg.sender == address(pm), "only pm");
        (PoolKey memory key, IPoolManager.SwapParams memory p) =
            abi.decode(data, (PoolKey, IPoolManager.SwapParams));
        int256 d = pm.swap(key, p, "");
        // v4 BalanceDelta packing: amount0 = high 128 bits, amount1 = low 128 bits
        int128 a0 = int128(d >> 128);
        int128 a1 = int128(d);
        if (a0 < 0) {
            _pay(key.currency0, uint256(uint128(-a0)));
        } else if (a0 > 0) {
            pm.take(key.currency0, address(this), uint256(uint128(a0)));
        }
        if (a1 < 0) {
            _pay(key.currency1, uint256(uint128(-a1)));
        } else if (a1 > 0) {
            pm.take(key.currency1, address(this), uint256(uint128(a1)));
        }
        return abi.encode(d);
    }

    function _pay(address c, uint256 amt) internal {
        if (c == address(0)) {
            pm.settle{value: amt}();
        } else {
            pm.sync(c);
            require(IERC20(c).transfer(address(pm), amt), "xfer");
            pm.settle();
        }
    }
}

interface IReinvest {
    function reinvest(PoolKey calldata key) external returns (bool);
}

/// @notice Lets an unprivileged caller invoke FRLM.reinvest() from *inside* a PoolManager.unlock,
///         which forces the FRLM down its `isUnlocked` branch (direct take/burn + re-add).
contract UnlockReinvest {
    IPoolManager public immutable pm;
    address public immutable frlm;
    bool public lastOk;
    bool public reverted;

    constructor(IPoolManager _pm, address _frlm) {
        pm = _pm;
        frlm = _frlm;
    }

    receive() external payable {}

    function go(PoolKey memory key) external {
        pm.unlock(abi.encode(key));
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        require(msg.sender == address(pm), "only pm");
        PoolKey memory key = abi.decode(data, (PoolKey));
        lastOk = IReinvest(frlm).reinvest(key);
        return "";
    }
}
