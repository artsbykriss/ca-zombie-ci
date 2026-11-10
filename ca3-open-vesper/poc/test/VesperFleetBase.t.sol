// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

interface IERC20B {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IVPoolB {
    function totalSupply() external view returns (uint256);
    function totalValue() external view returns (uint256);
    function pricePerShare() external view returns (uint256);
    function token() external view returns (address);
    function poolAccountant() external view returns (address);
    function governor() external view returns (address);
    function paused() external view returns (bool);
    function stopEverything() external view returns (bool);
}

interface IAccountantB {
    function getStrategies() external view returns (address[] memory);
    function totalDebtOf(address) external view returns (uint256);
}

/// @title Vesper V2 fleet on Base — same privilege matrix, 5 pools.
contract VesperFleetBaseProbe is Test {
    address constant ATTACKER = address(0xBAD5EED);
    address constant BASE_FALLBACK = 0x4200000000000000000000000000000000000006; // unused sentinel

    struct P {
        string sym;
        address pool;
    }

    P[] internal pools;

    function _rpc() internal view returns (string memory) {
        string memory v = vm.envOr("BASE_RPC_URL", string(""));
        if (bytes(v).length == 0) v = "https://base-rpc.publicnode.com";
        return v;
    }

    function setUp() public {
        vm.createSelectFork(_rpc());
        if (block.number > 100) vm.rollFork(block.number - 32);
        pools.push(P("vacbETH", 0x3899a6090c5C178dB8A1800DA39daD0D06EeEFBE));
        pools.push(P("vaETH", 0x82562507429876486B60AF4F32390ef0947b3d13));
        pools.push(P("vamsETH", 0x913Ece180df83A2B81A4976F83cA88543a0C51b8));
        pools.push(P("vaUSDC", 0x1e41238aCd3A9fF90b0DCB9ea96Cf45F104e09Ef));
        pools.push(P("vawstETH", 0x46fb68Eb2b1Fc43654AbaE5691D39D18D933E4b4));
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

    function test_base_registry() public {
        console2.log("base fork block", block.number);
        for (uint256 i; i < pools.length; ++i) {
            IVPoolB p = IVPoolB(pools[i].pool);
            console2.log("----", pools[i].sym);
            console2.log("  totalValue ", p.totalValue());
            console2.log("  pps        ", p.pricePerShare());
            console2.log("  paused/stop", p.paused(), p.stopEverything());
            address acct = p.poolAccountant();
            address[] memory s = IAccountantB(acct).getStrategies();
            console2.log("  strategies ", s.length);
            for (uint256 j; j < s.length; ++j) {
                console2.log("    ", s[j], IAccountantB(acct).totalDebtOf(s[j]));
            }
        }
    }

    function test_base_privilege_paths_revert() public {
        for (uint256 i; i < pools.length; ++i) {
            address pool = pools[i].pool;
            _mustRevert(pool, abi.encodeWithSelector(_sel("reportEarning(uint256,uint256,uint256)"), 1, 0, 0));
            _mustRevert(pool, abi.encodeWithSelector(_sel("reportLoss(uint256)"), 1));
            _mustRevert(pool, abi.encodeWithSelector(_sel("migrateStrategy(address,address)"), ATTACKER, ATTACKER));
            _mustRevert(pool, abi.encodeWithSelector(_sel("sweepERC20(address)"), ATTACKER));
            _mustRevert(pool, abi.encodeWithSelector(_sel("pause()")));
            _mustRevert(pool, abi.encodeWithSelector(_sel("shutdown()")));
            _mustRevert(pool, abi.encodeWithSelector(_sel("transferGovernorship(address)"), ATTACKER));
            _mustRevert(pool, abi.encodeWithSelector(_sel("updateUniversalFee(uint256)"), 10_000));
            address acct = IVPoolB(pool).poolAccountant();
            address[] memory strats = IAccountantB(acct).getStrategies();
            for (uint256 j; j < strats.length; ++j) {
                address s = strats[j];
                _mustRevert(s, abi.encodeWithSelector(_sel("withdraw(uint256)"), 1));
                _mustRevert(s, abi.encodeWithSelector(_sel("rebalance(uint256,uint256)"), 0, type(uint256).max));
                _mustRevert(s, abi.encodeWithSelector(_sel("sweep(address)"), ATTACKER));
                _mustRevert(s, abi.encodeWithSelector(_sel("upgradeToAndCall(address,bytes)"), ATTACKER, ""));
            }
        }
    }
}
