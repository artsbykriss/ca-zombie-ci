// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

interface IERC20b {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function deposit() external payable;
}

interface IEngineQ {
    function quote(address, address, int256, address) external view returns (uint256, uint256);
    function unlocked(address, address) external view returns (bool);
}

/// Isolation probe: which balance (if any) feeds the quote, and how strongly?
contract DonationProbe is Test {
    address constant VAULT = 0x585d44727129B9C69791B10238Ca605932938B4F;
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
        require(_post(LANE, 242770000000), "unlock");
    }

    function _post(uint256 lane, uint256 price) internal returns (bool) {
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
            (bool ok,) = E4.call(abi.encodeWithSelector(0xacee8aab, lane, price));
            if (ok) return true;
        }
        return false;
    }

    function q() internal view returns (uint256) {
        (, uint256 out) = IEngineQ(E4).quote(WETH, USDC, int256(1 ether), who);
        return out;
    }

    function test_probe() public {
        uint256 base = q();
        emit log_named_uint("baseline out", base);
        emit log_named_uint("vault USDC bal", IERC20b(USDC).balanceOf(VAULT));
        emit log_named_uint("vault WETH bal", IERC20b(WETH).balanceOf(VAULT));

        // USDC donations (output asset)
        uint256[4] memory usdcAmts = [uint256(1e6), 10_000e6, 100_000e6, 1_000_000e6];
        for (uint256 i = 0; i < usdcAmts.length; i++) {
            deal(USDC, who, usdcAmts[i]);
            vm.prank(who);
            IERC20b(USDC).transfer(VAULT, usdcAmts[i]);
            emit log_named_uint("donated USDC", usdcAmts[i]);
            emit log_named_uint("  out", q());
        }

        // WETH donations (input asset)
        uint256[4] memory wethAmts = [uint256(0.1 ether), 1 ether, 10 ether, 100 ether];
        for (uint256 i = 0; i < wethAmts.length; i++) {
            vm.deal(who, wethAmts[i]);
            vm.startPrank(who);
            IERC20b(WETH).deposit{value: wethAmts[i]}();
            IERC20b(WETH).transfer(VAULT, wethAmts[i]);
            vm.stopPrank();
            emit log_named_uint("donated WETH", wethAmts[i]);
            emit log_named_uint("  out", q());
        }
    }
}
