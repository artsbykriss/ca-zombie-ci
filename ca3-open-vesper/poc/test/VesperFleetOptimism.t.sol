// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20O {
    function balanceOf(address) external view returns (uint256);
}

interface IVPoolO {
    function totalSupply() external view returns (uint256);
    function totalValue() external view returns (uint256);
    function pricePerShare() external view returns (uint256);
    function tokensHere() external view returns (uint256);
    function poolAccountant() external view returns (address);
    function governor() external view returns (address);
    function paused() external view returns (bool);
    function stopEverything() external view returns (bool);
}

interface IAccountantO {
    function getStrategies() external view returns (address[] memory);
    function totalDebtOf(address) external view returns (uint256);
    function strategy(address)
        external
        view
        returns (bool, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
}

/// @title Vesper V2 fleet on Optimism — 4 pools. Same privilege matrix + the Sonne
///        liquidity probe (the one live pool with a genuine stuck-value hole).
contract VesperFleetOpProbe is Test {
    address constant ATTACKER = address(0xBAD5EED);

    struct P {
        string sym;
        address pool;
    }

    P[] internal pools;

    function _rpc() internal view returns (string memory) {
        string memory v = vm.envOr("OP_RPC_URL", string(""));
        if (bytes(v).length == 0) v = "https://optimism-rpc.publicnode.com";
        return v;
    }

    function setUp() public {
        vm.createSelectFork(_rpc());
        if (block.number > 100) vm.rollFork(block.number - 32);
        pools.push(P("vaETH", 0xCcF3d1AcF799bAe67F6e354d685295557cf64761));
        pools.push(P("vaOP", 0x19382707d5a47E74f60053b652Ab34b6e30Febad));
        pools.push(P("vaUSDC", 0x539505Dde2B9771dEBE0898a84441c5E7fDF6BC0));
        pools.push(P("vawstETH", 0xdd63ae655b388Cd782681b7821Be37fdB6d0E78d));
    }

    function _sel(string memory sig) internal pure returns (bytes4) {
        return bytes4(keccak256(bytes(sig)));
    }

    function _mustRevert(address target, bytes memory data) internal {
        vm.prank(ATTACKER, ATTACKER);
        (bool ok, bytes memory ret) = target.call(data);
        require(!ok, "UNEXPECTED SUCCESS");
        require(ret.length >= 4, "no revert data");
    }

    /// @dev legacy strategies may not implement the v6 selector; a bare revert is still closed.
    function _mustRevertLoose(address target, bytes memory data) internal {
        vm.prank(ATTACKER, ATTACKER);
        (bool ok,) = target.call(data);
        require(!ok, "UNEXPECTED SUCCESS");
    }

    function test_op_registry() public view {
        console2.log("optimism fork block", block.number);
        for (uint256 i; i < pools.length; ++i) {
            IVPoolO p = IVPoolO(pools[i].pool);
            console2.log("----", pools[i].sym, pools[i].pool);
            console2.log("  totalValue ", p.totalValue());
            console2.log("  tokensHere ", p.tokensHere());
            console2.log("  pps        ", p.pricePerShare());
            console2.log("  paused/stop", p.paused(), p.stopEverything());
            address acct = p.poolAccountant();
            address[] memory s = IAccountantO(acct).getStrategies();
            console2.log("  strategies ", s.length);
            for (uint256 j; j < s.length; ++j) {
                console2.log("    ", s[j], IAccountantO(acct).totalDebtOf(s[j]));
            }
        }
    }

    function test_op_privilege_paths_revert() public {
        for (uint256 i; i < pools.length; ++i) {
            address pool = pools[i].pool;
            _mustRevert(pool, abi.encodeWithSelector(_sel("reportEarning(uint256,uint256,uint256)"), 1, 0, 0));
            _mustRevert(pool, abi.encodeWithSelector(_sel("reportLoss(uint256)"), 1));
            _mustRevertLoose(pool, abi.encodeWithSelector(_sel("migrateStrategy(address,address)"), ATTACKER, ATTACKER));
            _mustRevertLoose(pool, abi.encodeWithSelector(_sel("sweepERC20(address)"), ATTACKER));
            _mustRevertLoose(pool, abi.encodeWithSelector(_sel("pause()")));
            _mustRevertLoose(pool, abi.encodeWithSelector(_sel("shutdown()")));
            _mustRevertLoose(pool, abi.encodeWithSelector(_sel("transferGovernorship(address)"), ATTACKER));
            _mustRevertLoose(pool, abi.encodeWithSelector(_sel("updateUniversalFee(uint256)"), 10_000));
            address acct = IVPoolO(pool).poolAccountant();
            address[] memory strats = IAccountantO(acct).getStrategies();
            for (uint256 j; j < strats.length; ++j) {
                address s = strats[j];
                _mustRevertLoose(s, abi.encodeWithSelector(_sel("withdraw(uint256)"), 1));
                _mustRevertLoose(s, abi.encodeWithSelector(_sel("rebalance(uint256,uint256)"), 0, type(uint256).max));
                _mustRevertLoose(s, abi.encodeWithSelector(_sel("sweep(address)"), ATTACKER));
                _mustRevertLoose(s, abi.encodeWithSelector(_sel("upgradeToAndCall(address,bytes)"), ATTACKER, ""));
            }
        }
    }

    /// @notice The one live stuck-value hole in the fleet: OP vaUSDC books ~$835k but its
    ///         main strategy is ~95% of a Sonne USDC market whose getCash() is 0. The
    ///         strategy's withdraw() succeeds while transferring nothing, so the pool's
    ///         pricePerShare stays inflated and exit liquidity is limited to ~$44k.
    function test_op_vaUSDC_sonne_is_illiquid() public view {
        address sonneStrat = 0x64Ef984FDaA7D13d71AaDeEe50E5826a69B33c76;
        address sUsdc = 0xEC8FEa79026FfEd168cCf5C627c7f486D77b765F;
        address usdce = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
        (bool ok, bytes memory r) = sUsdc.staticcall(abi.encodeWithSelector(_sel("getCash()")));
        require(ok, "getCash failed");
        uint256 marketCash = abi.decode(r, (uint256));
        console2.log("Sonne USDC getCash", marketCash);
        console2.log("strategy USDC.e balance", IERC20O(usdce).balanceOf(sonneStrat));
        assertEq(marketCash, 0, "Sonne market unexpectedly liquid");
        assertEq(IERC20O(usdce).balanceOf(sonneStrat), 0, "strategy unexpectedly holds idle USDC.e");
    }
}
