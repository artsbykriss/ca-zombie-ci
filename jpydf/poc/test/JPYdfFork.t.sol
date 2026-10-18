// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface IVault {
    error NotRegisteredStrategy();
    error RequestNotFound();

    function deposit(uint256) external returns (uint256);
    function redeem(uint256, address) external returns (uint256, uint256);
    function claim(uint256) external returns (uint256);
    function receiveFromStrategy(uint256) external returns (uint256);
    function backstopDeposit(uint256) external returns (uint256);
    function bufferBalance() external view returns (uint256);
    function backstopBalance() external view returns (uint256);
    function totalUnderlying() external view returns (uint256);
    function actualLiabilities() external view returns (uint256);
    function backingRatio() external view returns (uint256);
    function dToken() external view returns (address);
    function underlying() external view returns (address);
    function getStrategiesCount() external view returns (uint256);
    function strategies(uint256) external view returns (address);
    function pausedDeposit() external view returns (bool);
    function pausedRedeem() external view returns (bool);
    function pausedClaim() external view returns (bool);
}

interface IStrategy {
    function estimatedTotalUnderlying() external view returns (uint256);
    function principal() external view returns (uint256);
}

/// @notice Fork checks for JPYdf CollateralVault (USDC branch).
/// Read-only against a fork; no mainnet transactions.
contract JPYdfForkTest is Test {
    uint256 constant SNAP = 26_217_683;

    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant VAULT_USDC = 0x087Ebaf3F1b094b2046912a5E5F0BaD78dF3eAa7;
    address constant VAULT_WSTETH = 0x6042755eCCa71A1Be9C7091441ca5bEaA6b520e4;

    IVault vault;
    IERC20 usdc;

    function setUp() public {
        string memory rpc = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        vm.createSelectFork(rpc, SNAP);
        vault = IVault(VAULT_USDC);
        usdc = IERC20(USDC);
    }

    function test_live_backing_and_pauses() public {
        assertFalse(vault.pausedDeposit(), "deposit paused");
        assertFalse(vault.pausedRedeem(), "redeem paused");
        assertFalse(vault.pausedClaim(), "claim paused");
        uint256 backing = vault.backingRatio();
        emit log_named_uint("backingRatio (1e18)", backing);
        emit log_named_uint("totalUnderlying", vault.totalUnderlying());
        emit log_named_uint("actualLiabilities", vault.actualLiabilities());
        assertGe(backing, 1e18, "underbacked");
    }

    /// @notice Deposit -> redeem is exactly 1:1; no share price, no first-depositor edge.
    function test_deposit_redeem_roundtrip_1to1() public {
        deal(USDC, address(this), 10_000e6);
        usdc.approve(VAULT_USDC, type(uint256).max);
        uint256 before = usdc.balanceOf(address(this));

        uint256 dMinted = vault.deposit(1000e6);
        address dToken = vault.dToken();
        assertEq(dMinted, 1000e18, "dToken minted != 1:1 (18dp)");
        assertEq(IERC20(dToken).balanceOf(address(this)), 1000e18, "dToken balance");

        (uint256 received, uint256 requestId) = vault.redeem(1000e18, address(this));
        assertEq(received, 1000e6, "underlying received");
        assertEq(requestId, 0, "unexpected queue");
        assertEq(usdc.balanceOf(address(this)), before, "round trip not 1:1");
    }

    /// @notice receiveFromStrategy is gated to registered strategies, not public.
    function test_receive_from_strategy_is_not_permissionless() public {
        vm.expectRevert(IVault.NotRegisteredStrategy.selector);
        vault.receiveFromStrategy(1e6);
    }

    /// @notice claim pays the request owner; an unknown id cannot be claimed.
    function test_claim_unknown_request_reverts() public {
        vm.expectRevert(IVault.RequestNotFound.selector);
        vault.claim(1);
    }

    /// @notice The backstop is a one-way reserve: it increases backstopBalance
    ///         but not bufferBalance, so redeem/claim cannot spend it.
    function test_backstop_is_excluded_from_buffer() public {
        uint256 bufferBefore = vault.bufferBalance();
        uint256 backstopBefore = vault.backstopBalance();
        deal(USDC, address(this), 100e6);
        usdc.approve(VAULT_USDC, type(uint256).max);
        vault.backstopDeposit(100e6);
        assertEq(vault.bufferBalance(), bufferBefore, "backstop entered buffer");
        assertEq(vault.backstopBalance(), backstopBefore + 100e6, "backstop not credited");
    }

    /// @notice A direct USDC donation raises the buffer but is not withdrawable
    ///         by a depositor beyond their 1:1 claim.
    function test_donation_is_not_extractable() public {
        uint256 bufferBefore = vault.bufferBalance();
        uint256 liabBefore = vault.actualLiabilities();
        deal(USDC, address(this), 2000e6);
        usdc.transfer(VAULT_USDC, 1000e6);
        assertEq(vault.bufferBalance(), bufferBefore + 1000e6, "donation not in buffer");
        assertEq(vault.actualLiabilities(), liabBefore, "donation changed liabilities");

        usdc.approve(VAULT_USDC, type(uint256).max);
        uint256 before = usdc.balanceOf(address(this));
        vault.deposit(1000e6);
        vault.redeem(1000e18, address(this));
        assertEq(usdc.balanceOf(address(this)), before, "depositor captured donation");
        assertEq(vault.bufferBalance(), bufferBefore + 1000e6, "donation was paid out");
    }

    /// @notice Strategy valuations really cover the liabilities at the snapshot.
    function test_strategy_values_cover_liabilities() public {
        uint256 n = vault.getStrategiesCount();
        uint256 est;
        for (uint256 i = 0; i < n; i++) {
            address s = vault.strategies(i);
            uint256 e = IStrategy(s).estimatedTotalUnderlying();
            uint256 p = IStrategy(s).principal();
            emit log_named_uint("strategy", uint256(uint160(s)));
            emit log_named_uint("  principal", p);
            emit log_named_uint("  estimated", e);
            assertGe(e, p, "strategy below principal");
            est += e;
        }
        uint256 total = vault.bufferBalance() + vault.backstopBalance() + est;
        emit log_named_uint("buffer+backstop+strategies", total);
        emit log_named_uint("liabilities", vault.actualLiabilities());
        assertGe(total, vault.actualLiabilities(), "unbacked");
    }

    /// @notice wstETH branch is idle and 1:1 backed (no strategies, no queue).
    function test_wsteth_branch_is_idle_and_1to1() public {
        IVault w = IVault(VAULT_WSTETH);
        assertEq(w.getStrategiesCount(), 0, "unexpected strategy");
        assertEq(w.totalUnderlying(), w.actualLiabilities(), "not 1:1");
    }
}
