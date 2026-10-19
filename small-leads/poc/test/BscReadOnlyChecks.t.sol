// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

interface IGeniusFactory {
    function owner() external view returns (address);
    function GRADUATION_RESCUE_DELAY() external view returns (uint256);
    function forceSweptGraduation(address token) external;
    function rescueSweptGraduation(address token, address recipient) external;
    function createGraduatedPool(address token) external returns (uint256);
    function graduate(address token) external;
}

interface IFeeRouter {
    function claimDevFee(address quoteAsset, address to) external;
}

interface ITaxToken {
    function feeRate() external view returns (uint256);
    function feeAccumulated() external view returns (uint256);
    function minDispatch() external view returns (uint256);
    function pair() external view returns (address);
    function token0() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
}

/// Read-only fork checks for the two BSC leads. Nothing is signed or sent to mainnet:
/// every call runs against an anvil fork.
contract BscReadOnlyChecks is Test {
    address constant GENIUS_FACTORY = 0x37eE8AeE29C5efd3C1A7edA6dF3F510779928a37;
    address constant GENIUS_OWNER = 0xE7C7B7EE71db0f1B4F0Ff25D7cEc191268e7FD98;
    address constant FEE_ROUTER = 0x7383B244B416Db16Aa9dd0AB7C296Aa60255B9A2;
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    address constant CHIM = 0x6Eb21d1f81718420Da0f505223f7b0132d9EFFFf;
    address constant BIBI = 0x03e7F0B35e78332D3d0A3FFEAF4B4a95CADfFFFf;
    address constant SPX001 = 0x0E920821464625cf661A4dceDEb6406E1B48FFFf;
    address constant BALL4 = 0xD6423F99863e13b0a3Fa00b5e1E5597792f74F8C;

    address constant ATTACKER = 0x2222222222222222222222222222222222222222;

    function setUp() public {
        string memory rpc = vm.envOr("BSC_RPC_URL", string(""));
        if (bytes(rpc).length == 0) rpc = "https://bsc-rpc.publicnode.com";
        // Snapshot block for the report; if the RPC cannot serve it, fall back to latest.
        try vm.createSelectFork(rpc, 128_636_158) {} catch {
            vm.createSelectFork(rpc);
        }
    }

    function test_genius_force_sweep_is_owner_only() public {
        assertEq(IGeniusFactory(GENIUS_FACTORY).owner(), GENIUS_OWNER, "owner");
        assertEq(IGeniusFactory(GENIUS_FACTORY).GRADUATION_RESCUE_DELAY(), 7 days, "delay");
        assertEq(GENIUS_FACTORY.balance, 0, "factory BNB balance should be 0");

        vm.prank(ATTACKER);
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", ATTACKER)
        );
        IGeniusFactory(GENIUS_FACTORY).forceSweptGraduation(address(0x1111));

        vm.prank(ATTACKER);
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", ATTACKER)
        );
        IGeniusFactory(GENIUS_FACTORY).rescueSweptGraduation(address(0x1111), ATTACKER);

        // The owner passes the auth gate and fails on the token check instead.
        vm.prank(GENIUS_OWNER);
        vm.expectRevert(bytes4(keccak256("TokenNotFound()")));
        IGeniusFactory(GENIUS_FACTORY).forceSweptGraduation(address(0x1111));

        // Permissionless seed/graduate paths exist, but pay the caller nothing.
        vm.prank(ATTACKER);
        vm.expectRevert(bytes4(keccak256("TokenNotFound()")));
        IGeniusFactory(GENIUS_FACTORY).createGraduatedPool(address(0x1111));
    }

    function test_openfour_fee_router_is_not_caller_drainable() public {
        // FeeRouter holds partner/dev fees; claim is keyed by msg.sender.
        assertGt(IERC20(WBNB).balanceOf(FEE_ROUTER), 0, "fee router WBNB");
        vm.prank(ATTACKER);
        vm.expectRevert();
        IFeeRouter(FEE_ROUTER).claimDevFee(WBNB, ATTACKER);
    }

    function test_tax_swap_is_below_sandwich_breakeven() public {
        // 4Ball: 3% tax, 100% burn => _dispatchFee never swaps.
        assertEq(ITaxToken(BALL4).feeRate(), 300, "4Ball fee");
        // CHIM / bibi Pro / SPX001: live non-burn allocations. The accrued tax as a
        // fraction of the token reserve is < 2% (the 2x 0.25% DEX-fee break-even).
        _assertBelowBreakEven(CHIM);
        _assertBelowBreakEven(BIBI);
        _assertBelowBreakEven(SPX001);
    }

    function _assertBelowBreakEven(address token) internal {
        ITaxToken t = ITaxToken(token);
        uint256 accrued = t.feeAccumulated();
        uint256 minD = t.minDispatch();
        address pair = t.pair();
        require(pair != address(0), "no pair");
        (uint112 r0, uint112 r1,) = ITaxToken(pair).getReserves();
        address t0 = ITaxToken(pair).token0();
        uint256 tokenReserve = t0 == token ? uint256(r0) : uint256(r1);
        require(tokenReserve > 0, "no token reserve");
        // swapQuote / poolQuote = accrued / tokenReserve. Break-even is ~2% = 200 bps.
        uint256 ratioBps = accrued * 10_000 / tokenReserve;
        emit log_named_uint("accrued", accrued);
        emit log_named_uint("minDispatch", minD);
        emit log_named_uint("tokenReserve", tokenReserve);
        emit log_named_uint("swap/pool bps", ratioBps);
        assertLt(ratioBps, 200, "tax swap exceeds 2% of pool");
    }
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}
