// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

interface IERC20c {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function deposit() external payable;
}

interface ISwapperC {
    function fermiSwapWithAllowances(address, address, int256, uint256, address)
        external
        returns (uint256, uint256);
}

/// Probe the engine's swap-time price band ("PB") and whether it can be walked.
contract BandProbe is Test {
    address constant SWAP2 = 0x5979458912F80B96d30D4220af8E2e4925A33320;
    address constant E4 = 0x0109AA912B58508886a2a707204B0F8C8b164CCc;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 constant LANE = 0x2eec03b8999af9793df60f1395a1b41c29e22b324ea3200ca21bc692979b9d46;
    address constant UPD = 0x14E870f0A7C764Ca71289952006D6bf130058927;
    address who = address(0xA11CE);

    function setUp() public {
        vm.createSelectFork(
            vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")))
        );
    }

    function post(uint256 price) internal {
        address[8] memory ups = [
            0x14E870f0A7C764Ca71289952006D6bf130058927,
            0xfc42bE9494F1Af6b03AdAd71811c62aDa2D6f3c3,
            0x14ffd5D4f0C48e3e79D8346B85917e092b0C52d2,
            0x47667E5C897DfdE871b4833f4Ae7DEF39526E897,
            0x842089E53568804579AD9e31296Ef723aa5DD29b,
            0xd6d3C12e9FB4838f55F9CC531c42af246de82A07,
            0x70A387e68831c67b9759Ea1bBF383802e67B08Fb,
            0x216624013844cCbE5A1d27eF0515cEC02C91BB25
        ];
        for (uint256 i = 0; i < ups.length; i++) {
            vm.prank(ups[i]);
            (bool ok,) = E4.call(abi.encodeWithSelector(0xacee8aab, LANE, price));
            if (ok) return;
        }
        revert("post failed");
    }

    function trySwap(uint256 size, string memory label) internal returns (bool) {
        vm.deal(who, size);
        vm.startPrank(who);
        IERC20c(WETH).deposit{value: size}();
        IERC20c(WETH).approve(SWAP2, size);
        try ISwapperC(SWAP2).fermiSwapWithAllowances(WETH, USDC, int256(size), 0, who) returns (
            uint256, uint256 out
        ) {
            emit log_named_string(label, "OK");
            emit log_named_uint("  out USDC", out);
            vm.stopPrank();
            return true;
        } catch (bytes memory reason) {
            emit log_named_string(label, "REVERT");
            emit log_named_bytes("  reason", reason);
            vm.stopPrank();
            return false;
        }
    }

    function test_band() public {
        uint256 base = 243671600507; // last live posted price (block 26202530)
        emit log_named_uint("base price", base);

        post(base);
        trySwap(0.1 ether, "1.00x");

        post((base * 121) / 100);
        trySwap(0.1 ether, "1.21x");

        post((base * 125) / 100);
        trySwap(0.1 ether, "1.25x");

        post((base * 130) / 100);
        trySwap(0.1 ether, "1.30x");

        post((base * 133) / 100);
        trySwap(0.1 ether, "1.33x");

        post((base * 140) / 100);
        trySwap(0.1 ether, "1.40x");

        post((base * 145) / 100);
        trySwap(0.1 ether, "1.45x");

        post((base * 149) / 100);
        trySwap(0.1 ether, "1.49x");
    }

    function test_walk_time() public {
        uint256 base = 243671600507;
        uint256 p = base;
        for (uint256 i = 0; i < 5; i++) {
            p = (p * 140) / 100; // +40% steps
            vm.warp(block.timestamp + 1 hours); // advance time 1h
            vm.roll(block.number + 300);
            post(p);
            string memory label = string.concat("time+1h +40% step ", vm.toString(i));
            bool ok = trySwap(0.1 ether, label);
            if (!ok) break;
        }
        emit log_named_uint("final price", p);
        emit log_named_uint("final multiple x100", (p * 100) / base);
    }

    function test_walk_multiblock() public {
        uint256 base = 243671600507;
        uint256 p = base;
        for (uint256 i = 0; i < 6; i++) {
            p = (p * 140) / 100; // +40% per block
            vm.roll(block.number + 1); // new block => reference refresh?
            post(p);
            string memory label = string.concat("multiblock +40% step ", vm.toString(i));
            bool ok = trySwap(0.1 ether, label);
            if (!ok) break;
        }
        emit log_named_uint("final price", p);
        emit log_named_uint("final multiple x100", (p * 100) / base);
    }

    function test_walk() public {
        uint256 base = 243671600507;
        // walk up in +20% steps, swapping at each step
        uint256 p = base;
        for (uint256 i = 0; i < 8; i++) {
            p = (p * 120) / 100; // +20% steps
            post(p);
            string memory label = string.concat("walk +20% step ", vm.toString(i));
            bool ok = trySwap(0.1 ether, label);
            if (!ok) break;
        }
        emit log_named_uint("final price", p);
        emit log_named_uint("final multiple x100", (p * 100) / base);
    }
}
