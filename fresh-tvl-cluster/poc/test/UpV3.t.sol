// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {ForkHelper} from "../src/ForkHelper.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

interface ICLPoolMin {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function gauge() external view returns (address);
    function nft() external view returns (address);
    function liquidity() external view returns (uint128);
    function stakedLiquidity() external view returns (uint128);
    function fee() external view returns (uint24);
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

interface INPMMin {
    function collect(CollectParams calldata params) external payable returns (uint256, uint256);
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
    function ownerOf(uint256 tokenId) external view returns (address);
    function refundETH() external payable;
}

interface IVoterMin {
    function capMode() external view returns (uint8);
    function pendingCapMode() external view returns (uint8);
    function ve() external view returns (address);
    function gaugeToFees(address gauge) external view returns (address);
}

contract UpV3FlashBorrower {
    address public immutable pool;
    address public immutable tok0;
    address public immutable tok1;
    bool public repay;
    uint256 public a0;
    uint256 public a1;

    constructor(address _pool, address _t0, address _t1, bool _repay) {
        pool = _pool;
        tok0 = _t0;
        tok1 = _t1;
        repay = _repay;
    }

    function go(uint256 _a0, uint256 _a1) external {
        a0 = _a0;
        a1 = _a1;
        ICLPoolMin(pool).flash(address(this), _a0, _a1, "");
    }

    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata) external {
        require(msg.sender == pool, "not pool");
        if (repay) {
            if (a0 + fee0 > 0) IERC20(tok0).transfer(pool, a0 + fee0);
            if (a1 + fee1 > 0) IERC20(tok1).transfer(pool, a1 + fee1);
        }
    }
}

/// @title Z3-H17 · up v3 (Robinhood Chain 4663) fork tests — unauthorized paths + flash accounting
contract UpV3H17Test is ForkHelper {
    address constant FACTORY = 0x1ac9dB4a2608ba45D6127B1737949b51Bb54B7F3;
    address constant POOL_IMPL = 0x11725976BF1F38c4aB78d1F480bc5883d70D9dc3;
    address constant NPM = 0x07F44c47743A2f36414A82b9F558ECFCf0EEdCEf;
    address constant VOTER = 0x7F749fDD351C1Ceed82d76d7699CB631Eb8332a7;
    address constant VE = 0x5d321dE36F0bf98D92b291280514F3878582B7B6;
    address constant POOL = 0x4E8649Be40aE67EBbcff99C291B92eE03015917b; // CASHCAT/WETH
    address constant GAUGE = 0x34e626Eca01615a752F859DED5ac2b2779433797; // pool gauge (staked liquidity > 0)
    address constant CASHCAT_USDG_POOL = 0x3986840e83E64C113B4EbEEEd6B3223528e06Ed9; // fee source (fork impersonation)
    address constant SAFE = 0x0eEA30aBa3f07abFA20E4b544F55e0f917d9DFd8;

    address attacker = address(0xA11CE);

    function setUp() public {
        string[] memory urls = new string[](3);
        urls[0] = "https://rpc.mainnet.chain.robinhood.com";
        urls[1] = "https://robinhood-rpc.publicnode.com";
        urls[2] = "https://robinhood.drpc.org";
        string memory url = forkChain("RHO_RPC", urls);
        console2.log("fork rpc:", url);
        console2.log("block number (header space):", block.number);
        console2.log("eth_blockNumber-space height differs on this chain; see README");
        vm.deal(attacker, 10 ether);
    }

    function test_T1_structural_facts() public view {
        (bool ok, bytes memory od) = FACTORY.staticcall(abi.encodeWithSignature("owner()"));
        assertTrue(ok, "owner() readable");
        assertEq(abi.decode(od, (address)), SAFE, "factory owner");
        uint128 liq = ICLPoolMin(POOL).liquidity();
        assertGt(liq, 0, "pool has liquidity");
        assertEq(ICLPoolMin(POOL).gauge(), GAUGE, "pool gauge");
        assertEq(ICLPoolMin(POOL).nft(), NPM, "pool nft");
        uint8 cm = IVoterMin(VOTER).capMode();
        console2.log("voter.capMode:", cm);
        assertEq(IVoterMin(VOTER).ve(), VE, "voter ve");
        console2.log("pool liquidity:", liq);
        console2.log("pool stakedLiquidity:", ICLPoolMin(POOL).stakedLiquidity());
        console2.log("pool fee pips:", ICLPoolMin(POOL).fee());
        assertGt(POOL_IMPL.code.length, 0, "pool impl has code");
    }

    function test_T2_gauge_unauthorized_reverts() public {
        vm.startPrank(attacker);
        (bool ok1, bytes memory d1) = GAUGE.call(abi.encodeWithSignature("withdraw(uint256)", uint256(1)));
        assertFalse(ok1, "withdraw must revert");
        console2.logBytes(d1);
        (bool ok2, bytes memory d2) = GAUGE.call(abi.encodeWithSignature("getReward(uint256)", uint256(1)));
        assertFalse(ok2, "getReward must revert");
        console2.logBytes(d2);
        (bool ok3, bytes memory d3) = GAUGE.call(abi.encodeWithSignature("deposit(uint256)", uint256(1)));
        assertFalse(ok3, "deposit must revert (not NFT owner)");
        console2.logBytes(d3);
        vm.stopPrank();
    }

    function test_T3_npm_unauthorized_collect_reverts() public {
        uint256 foundId = 0;
        for (uint256 id = 1; id <= 200; id++) {
            (bool okPos, bytes memory data) = NPM.staticcall(abi.encodeWithSignature("positions(uint256)", id));
            if (okPos && data.length >= 64) {
                foundId = id;
                break;
            }
        }
        console2.log("existing tokenId found:", foundId);
        if (foundId == 0) {
            console2.log("no position in 1..200; structural negative only");
            return;
        }
        console2.log("position owner:", INPMMin(NPM).ownerOf(foundId));
        vm.prank(attacker);
        (bool ok, bytes memory d) = NPM.call(
            abi.encodeWithSignature(
                "collect((uint256,address,uint128,uint128))", foundId, attacker, uint128(1), uint128(1)
            )
        );
        assertFalse(ok, "foreign collect must revert");
        console2.logBytes(d);
    }

    function test_T4_pool_owner_collect_requires_nft_manager() public {
        vm.prank(attacker);
        (bool ok, bytes memory d) = POOL.call(
            abi.encodeWithSignature(
                "collect(address,int24,int24,uint128,uint128,address)",
                attacker,
                int24(-887220),
                int24(887220),
                uint128(1),
                uint128(1),
                NPM
            )
        );
        assertFalse(ok, "6-arg collect is onlyNftManager");
        console2.logBytes(d);
    }

    function test_T5_flash_without_repay_reverts() public {
        UpV3FlashBorrower b = new UpV3FlashBorrower(POOL, ICLPoolMin(POOL).token0(), ICLPoolMin(POOL).token1(), false);
        vm.prank(attacker);
        (bool ok, bytes memory d) =
            address(b).call(abi.encodeWithSignature("go(uint256,uint256)", uint256(1000), uint256(1000)));
        assertFalse(ok, "flash must revert without repayment");
        console2.logBytes(d);
    }

    /// @dev fee buffer sourced (fork-only impersonation) from a sibling pool holding the same token
    function test_T6_flash_with_repay_pool_gains_exactly_fee() public {
        address t0 = ICLPoolMin(POOL).token0();
        UpV3FlashBorrower b = new UpV3FlashBorrower(POOL, t0, ICLPoolMin(POOL).token1(), true);
        uint256 a0 = 1e15;
        uint24 feePips = ICLPoolMin(POOL).fee();
        uint256 fee0 = (a0 * uint256(feePips) + 999999) / 1e6;
        vm.prank(CASHCAT_USDG_POOL);
        IERC20(t0).transfer(address(b), fee0);
        uint256 p0 = IERC20(t0).balanceOf(POOL);
        vm.prank(attacker);
        b.go(a0, 0);
        uint256 p0a = IERC20(t0).balanceOf(POOL);
        console2.log("fee pips:", feePips);
        console2.log("pool t0 delta (must equal fee0):", p0a - p0);
        assertEq(p0a - p0, fee0, "pool gained exactly the flash fee");
        assertEq(IERC20(t0).balanceOf(address(b)), 0, "borrower repaid amount+fee");
        assertEq(attacker.balance, 10 ether, "attacker gained nothing");
    }

    function test_T7_voter_capmode_and_initialize_guard() public {
        console2.log("capMode:", IVoterMin(VOTER).capMode());
        console2.log("pendingCapMode:", IVoterMin(VOTER).pendingCapMode());
        address[] memory empty = new address[](0);
        vm.prank(attacker);
        (bool ok, bytes memory d) = VOTER.call(abi.encodeWithSignature("initialize(address[],address)", empty, attacker));
        assertFalse(ok, "voter.initialize must revert");
        console2.logBytes(d);
    }

    /// @dev M-01 probe: permissionless poke() on a decayed-lock veNFT (balanceOfNFT == 0).
    function test_T8_poke_permissionless_probe() public {
        uint256 zeroId = 0;
        for (uint256 id = 1; id <= 80; id++) {
            (bool okBal, bytes memory balData) = VE.staticcall(abi.encodeWithSignature("balanceOfNFT(uint256)", id));
            if (okBal && balData.length == 32) {
                if (abi.decode(balData, (uint256)) == 0) {
                    (bool okOwn, bytes memory ownData) = VE.staticcall(abi.encodeWithSignature("ownerOf(uint256)", id));
                    if (okOwn && abi.decode(ownData, (address)) != address(0)) {
                        zeroId = id;
                        break;
                    }
                }
            }
        }
        console2.log("first zero-weight live veNFT id:", zeroId);
        if (zeroId == 0) {
            console2.log("no zero-weight veNFT in 1..80 - M-01 trigger inert on this fork state");
            return;
        }
        vm.prank(attacker);
        (bool ok, bytes memory d) = VOTER.call(abi.encodeWithSignature("poke(uint256)", zeroId));
        console2.log("poke success by fresh attacker:", ok);
        console2.logBytes(d);
        address fees = IVoterMin(VOTER).gaugeToFees(GAUGE);
        console2.log("feeVotingReward for pool gauge:", fees);
    }

    function test_T9_npm_eth_park_is_zero() public {
        console2.log("NPM ETH balance:", NPM.balance);
        assertEq(NPM.balance, 0, "no parked ETH");
        vm.prank(attacker);
        INPMMin(NPM).refundETH();
        assertEq(NPM.balance, 0, "refundETH yields nothing");
    }
}
