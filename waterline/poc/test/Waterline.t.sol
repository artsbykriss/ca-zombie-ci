// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

struct MarketParams {
    address loanToken;
    address collateralToken;
    address oracle;
    address irm;
    uint256 lltv;
}

interface IMorpho {
    function idToMarketParams(bytes32) external view returns (MarketParams memory);
    function market(bytes32) external view returns (uint128, uint128, uint128, uint128, uint128, uint128);
    function position(bytes32, address) external view returns (uint256, uint128, uint128);
    function liquidate(MarketParams memory, address, uint256, uint256, bytes memory)
        external
        returns (uint256, uint256);
}

interface IOracle {
    function price() external view returns (uint256);
}

interface IAgua {
    function convertToAssets(uint256) external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function redeemEarly(uint256, address, uint256) external returns (uint256);
    function requestRedemption(uint256) external;
    function completeRedemption(address) external returns (uint256);
    function maxRedeem(address) external view returns (uint256);
    function maxWithdraw(address) external view returns (uint256);
    function earlyRedemptionFee() external view returns (uint256);
    function lockupPeriod() external view returns (uint256);
    function currentRate() external view returns (uint256);
    function cumulativeRateFactor() external view returns (uint256);
    function setRate(uint256) external;
    function adminWithdraw(address, uint256, address) external;
}

interface IVaultV2 {
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

/// @title Waterline Reservoir / Agua market — live-state and liquidation-path PoC
/// @notice Read-only mainnet fork. No transaction is signed or sent.
contract WaterlineTest is Test {
    address constant MORPHO = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    bytes32 constant ID = 0x167f1d100200e7b7348a82f81e556f4f6c0271d79532073e57630ad9781a9ec8;
    address constant BORROWER = 0x81A4470b461a6b205871298A32d761A1D66649c9;
    address constant AGUA = 0xa98b4A70E17e55045CDE4972B95Bc2E8CEC22a0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant ORACLE = 0x47c1699bcef8944DA8B6a687c0FC22dD49b143A3;
    address constant RESERVOIR = 0xBEeFF047C03714965a54b671A37C18beF6b96210;

    uint256 constant FORK_BLOCK = 26241741;

    function setUp() public {
        vm.createSelectFork(
            vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com"))),
            FORK_BLOCK
        );
    }

    function _params() internal view returns (MarketParams memory mp) {
        mp = IMorpho(MORPHO).idToMarketParams(ID);
    }

    function _debtAndCollateral() internal view returns (uint256 debt, uint256 collVal, uint256 hf, uint256 coll) {
        (,, uint128 tba, uint128 tbs,,) = IMorpho(MORPHO).market(ID);
        (, uint128 bs, uint128 col) = IMorpho(MORPHO).position(ID, BORROWER);
        uint256 price = IOracle(ORACLE).price();
        debt = uint256(bs) * (uint256(tba) + 1) / (uint256(tbs) + 1e6);
        coll = uint256(col);
        collVal = coll * price / 1e36;
        hf = collVal * _params().lltv / debt;
    }

    function test_live_hf_and_oracle() public {
        MarketParams memory mp = _params();
        (uint256 debt, uint256 collVal, uint256 hf, uint256 coll) = _debtAndCollateral();
        uint256 price = IOracle(ORACLE).price();

        console.log("block", block.number);
        console.log("oracle price (1e24)", price);
        console.log("collateral shares", coll);
        console.log("collateral USD", collVal / 1e6);
        console.log("debt USD", debt / 1e6);
        console.log("HF (1e18)", hf);
        console.log("LTV bps", debt * 10_000 / collVal);

        assertEq(mp.loanToken, USDC);
        assertEq(mp.collateralToken, AGUA);
        assertEq(mp.lltv, 915000000000000000);
        assertGt(hf, 1e18);
        assertApproxEqRel(hf, 1.006384e18, 0.002e18);
        // oracle == vault convertToAssets, 18-dec shares -> 6-dec assets, 1e36 scale
        assertApproxEqAbs(price, IAgua(AGUA).convertToAssets(1e18) * 1e18, 2e18);
        // vault itself is 13.08M; only the Agua market is at issue here
        console.log("reservoir totalAssets", IVaultV2(RESERVOIR).totalAssets());
    }

    function test_liquidation_reverts_while_healthy() public {
        MarketParams memory mp = _params();
        (, uint128 bs,) = IMorpho(MORPHO).position(ID, BORROWER);
        deal(USDC, address(this), 6_000_000e6);
        IERC20(USDC).approve(MORPHO, type(uint256).max);
        vm.expectRevert();
        IMorpho(MORPHO).liquidate(mp, BORROWER, 0, bs, "");
    }

    /// @dev Simulates the only theoretical trigger (a price write-down), proves the
    ///      liquidation then works, and proves the seized collateral cannot be exited.
    function test_hypothetical_writedown_liquidation_exit_blocked() public {
        MarketParams memory mp = _params();
        uint256 price = IOracle(ORACLE).price();
        uint256 shocked = price * 99 / 100; // -1% => HF ~0.996
        vm.mockCall(ORACLE, abi.encodeWithSelector(IOracle.price.selector), abi.encode(shocked));

        (uint256 debt0,, uint256 hfShocked,) = _debtAndCollateral();
        console.log("HF after -1% mark (1e18)", hfShocked);
        assertLt(hfShocked, 1e18);

        deal(USDC, address(this), 6_000_000e6);
        IERC20(USDC).approve(MORPHO, type(uint256).max);
        (, uint128 bs0,) = IMorpho(MORPHO).position(ID, BORROWER);

        (uint256 seized, uint256 repaid) = IMorpho(MORPHO).liquidate(mp, BORROWER, 0, bs0, "");
        console.log("seized agua shares", seized);
        console.log("repaid USDC", repaid / 1e6);
        uint256 got = IAgua(AGUA).balanceOf(address(this));
        console.log("liquidator agua balance", got);
        assertGt(got, 0);

        uint256 seizedValAtShock = got * shocked / 1e36;
        console.log("seized value at shocked mark USD", seizedValAtShock / 1e6);
        console.log("bonus USD at shocked mark", (seizedValAtShock - repaid) / 1e6);
        assertGt(seizedValAtShock, repaid);

        // 1) atomic exit through redeemEarly (5% fee)
        console.log("earlyRedemptionFee bps", IAgua(AGUA).earlyRedemptionFee());
        console.log("vault USDC balance", IERC20(USDC).balanceOf(AGUA));
        vm.expectRevert();
        IAgua(AGUA).redeemEarly(got, address(this), 0);

        // 2) queued exit (5-day lockup)
        IAgua(AGUA).requestRedemption(got);
        vm.warp(block.timestamp + IAgua(AGUA).lockupPeriod() + 1);
        vm.expectRevert();
        IAgua(AGUA).completeRedemption(address(this));

        console.log("debt before", debt0);
    }

    /// @dev NAV is totalSupply * cumulativeRateFactor; there is no setter that lowers it.
    function test_oracle_monotone() public {
        uint256 p0 = IOracle(ORACLE).price();
        vm.warp(block.timestamp + 30 days);
        uint256 p1 = IOracle(ORACLE).price();
        console.log("price +30d", p0, p1);
        assertGt(p1, p0);
    }

    function test_vault_unfunded_and_privileged_paths() public {
        console.log("agua USDC balance", IERC20(USDC).balanceOf(AGUA));
        console.log("agua totalAssets", IAgua(AGUA).totalAssets());
        console.log("agua totalSupply", IAgua(AGUA).totalSupply());
        console.log("agua currentRate", IAgua(AGUA).currentRate());
        assertEq(IAgua(AGUA).earlyRedemptionFee(), 500);
        assertEq(IAgua(AGUA).maxRedeem(address(this)), 0);
        assertEq(IAgua(AGUA).maxWithdraw(address(this)), 0);
        assertEq(IERC20(USDC).balanceOf(AGUA), 30e6); // $30.00

        vm.expectRevert();
        IAgua(AGUA).setRate(0);
        vm.expectRevert();
        IAgua(AGUA).adminWithdraw(USDC, 1, address(this));
    }
}
