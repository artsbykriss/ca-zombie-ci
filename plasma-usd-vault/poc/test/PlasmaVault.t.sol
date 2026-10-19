// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IAuthority {
    function canCall(address user, address target, bytes4 sig) external view returns (bool);
}

interface IAccountant {
    function getRate() external view returns (uint256);
    function getRateInQuoteSafe(address quote) external view returns (uint256);
    function accountantState()
        external
        view
        returns (
            address payoutAddress,
            uint96 highwaterMark,
            uint128 feesOwedInBase,
            uint128 totalSharesLastUpdate,
            uint96 exchangeRate,
            uint16 allowedExchangeRateChangeUpper,
            uint16 allowedExchangeRateChangeLower,
            uint64 lastUpdateTimestamp,
            bool isPaused,
            uint24 minimumUpdateDelayInSeconds,
            uint16 platformFee,
            uint16 performanceFee
        );
}

interface ITeller {
    function accountant() external view returns (address);
    function vault() external view returns (address);
    function isPaused() external view returns (bool);
    function shareLockPeriod() external view returns (uint64);
    function permissionedTransfers() external view returns (bool);
    function assetData(address) external view returns (bool, bool, uint16);
    function idToChains(uint32 eid) external view returns (bool, bool, uint128);
    function deposit(address asset, uint256 amount, uint256 minMint) external payable returns (uint256);
    function bulkWithdraw(address asset, uint256 shareAmount, uint256 minAssets, address to)
        external
        returns (uint256);
    function bridge(uint96 shareAmount, address to, bytes calldata wildcard, address feeToken, uint256 maxFee)
        external
        payable;
}

interface IVault {
    function totalSupply() external view returns (uint256);
}

/// @notice Read-only fork proof for the Plasma USD Vault (chain 9745) + Ethereum mirror (chain 1).
///         No mainnet transactions. Uses latest state; tolerances cover interest drift between runs.
contract PlasmaVaultTest is Test {
    address constant VAULT = 0xd1074E0AE85610dDBA0147e29eBe0D8E5873a000;
    address constant TELLER = 0x4E7d2186eB8B75fBDcA867761636637E05BaeF1E;
    address constant ACCOUNTANT = 0x737f2522d09E58a3Ea9dcCFDB127dD0dF5eB3F18;
    address constant AUTHORITY = 0xb381DE863dadFEA44738E7179f0d1Fc73b59e278;
    address constant USDT0 = 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb; // Plasma base
    address constant APLAUSDT0 = 0x5D72a9d9A9510Cd8cBdBA12aC62593A58930a948;
    address constant USDT_ETH = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant USDC_ETH = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDS_ETH = 0xdC035D45d973E3EC169d2276DDab16f1e407384F;
    address constant DAI_ETH = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant ATTACKER = address(0x1111111111111111111111111111111111111111);
    uint32 constant ETH_EID = 30101;
    uint32 constant PLASMA_EID = 30383;

    function _plasmaRpc() internal view returns (string memory) {
        return vm.envOr("PLASMA_RPC_URL", string("https://rpc.plasma.to"));
    }

    function _ethRpc() internal view returns (string memory) {
        return vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
    }

    function test_plasma_rate_and_gate() public {
        vm.createSelectFork(_plasmaRpc());
        emit log_named_uint("plasma block", block.number);
        assertEq(block.chainid, 9745);

        uint256 rate = IAccountant(ACCOUNTANT).getRate();
        emit log_named_uint("accountant rate", rate);
        assertGt(rate, 1_040_000);
        assertLt(rate, 1_060_000);
        assertEq(IAccountant(ACCOUNTANT).getRateInQuoteSafe(USDT0), rate);

        uint256 supply = IVault(VAULT).totalSupply();
        uint256 aToken = IERC20(APLAUSDT0).balanceOf(VAULT);
        uint256 idle = IERC20(USDT0).balanceOf(VAULT);
        uint256 plasmaAssets = aToken + idle;
        uint256 localNav = plasmaAssets * 1e6 / supply;
        emit log_named_uint("plasma supply", supply);
        emit log_named_uint("plasma assets (6dp)", plasmaAssets);
        emit log_named_uint("plasma local NAV (1e6)", localNav);
        assertGt(localNav, 1_000_000); // ~1.0723: local over-collateralisation vs global rate

        // Exit gate: bulkWithdraw is solver-only; vault.exit/enter/manage are not public.
        assertFalse(IAuthority(AUTHORITY).canCall(ATTACKER, TELLER, ITeller.bulkWithdraw.selector));
        assertFalse(IAuthority(AUTHORITY).canCall(ATTACKER, VAULT, bytes4(0x18457e61))); // exit
        assertFalse(IAuthority(AUTHORITY).canCall(ATTACKER, VAULT, bytes4(0x39d6ba32))); // enter
        assertFalse(IAuthority(AUTHORITY).canCall(ATTACKER, VAULT, bytes4(0xf6e715d0))); // manage

        vm.prank(ATTACKER);
        vm.expectRevert();
        ITeller(TELLER).bulkWithdraw(USDT0, 1e6, 0, ATTACKER);

        // deposit is public: auth passes, only the token transfer fails.
        vm.prank(ATTACKER);
        vm.expectRevert();
        ITeller(TELLER).deposit(USDT0, 1e6, 0);

        // bridge is public: auth passes, burns the caller's (zero) shares -> underflow.
        vm.prank(ATTACKER);
        vm.expectRevert();
        ITeller(TELLER).bridge(1e6, ATTACKER, abi.encode(ETH_EID), USDT0, 0);

        // LZ peer is configured in both directions.
        (bool from, bool to, uint128 gasLimit) = ITeller(TELLER).idToChains(ETH_EID);
        assertTrue(from);
        assertTrue(to);
        assertEq(gasLimit, 200_000);
    }

    function test_global_nav_matches_rate() public {
        // Plasma leg
        vm.createSelectFork(_plasmaRpc());
        uint256 rate = IAccountant(ACCOUNTANT).getRate();
        uint256 supplyP = IVault(VAULT).totalSupply();
        uint256 assetsP = IERC20(APLAUSDT0).balanceOf(VAULT) + IERC20(USDT0).balanceOf(VAULT);
        emit log_named_uint("plasma block", block.number);

        // Ethereum leg (same deterministic address)
        vm.createSelectFork(_ethRpc());
        emit log_named_uint("ethereum block", block.number);
        uint256 supplyE = IVault(VAULT).totalSupply();
        uint256 assetsE = IERC20(USDT_ETH).balanceOf(VAULT) + IERC20(USDC_ETH).balanceOf(VAULT)
            + IERC20(USDS_ETH).balanceOf(VAULT) / 1e12 + IERC20(DAI_ETH).balanceOf(VAULT) / 1e12;
        emit log_named_uint("eth supply", supplyE);
        emit log_named_uint("eth assets (6dp)", assetsE);

        uint256 globalNav = (assetsP + assetsE) * 1e6 / (supplyP + supplyE);
        emit log_named_uint("global NAV (1e6)", globalNav);
        emit log_named_uint("rate (1e6)", rate);
        // The accountant rate is the GLOBAL NAV, within 0.5% (interest since last update).
        assertApproxEqRel(globalNav, rate, 0.005e18);

        uint256 ethLocalNav = assetsE * 1e6 / supplyE;
        emit log_named_uint("eth local NAV (1e6)", ethLocalNav);
        assertLt(ethLocalNav, rate); // ~0.0384: local mirror is far below the global rate
        assertTrue(IAuthority(AUTHORITY).canCall(ATTACKER, TELLER, ITeller.bulkWithdraw.selector) == false);
        (bool from, bool to,) = ITeller(TELLER).idToChains(PLASMA_EID);
        assertTrue(from);
        assertTrue(to);
    }
}
