// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// EddyFinance AMM (ZetaChain) — fork PoC (read-only mainnet; local fork state only).
/// Chain: ZetaChain mainnet (chainId 7000). Fork at latest block via public keyless RPCs.
/// Verified sources: UniswapV2Factory/Pair (zetascan), Curve-style stableswaps (zetascan).

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IUniV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
    function swap(uint256, uint256, address, bytes calldata) external;
    function skim(address) external;
    function totalSupply() external view returns (uint256);
}

interface IStableSwap {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external payable returns (uint256);
    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);
    function balances(uint256 i) external view returns (uint256);
    function coins(uint256 i) external view returns (address);
    function lp_token() external view returns (address);
    function owner() external view returns (address);
    function fee() external view returns (uint256);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
}

interface IFarm {
    function stakingToken() external view returns (address);
    function rewardsToken() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function rewardRate() external view returns (uint256);
    function periodFinish() external view returns (uint256);
    function withdraw(uint256) external;
    function stake(uint256) external;
}

contract EddyPoC is Test {
    // ---- EddyFinance contracts (ZetaChain mainnet, verified on zetascan.com) ----
    address constant FACTORY  = 0x9fd96203f7b22bCF72d9DCb40ff98302376cE09c;
    address constant PAIR_STZ = 0x6b3Ee329B0Dc80D730D2De370BAD93cA122E75dB; // stZETA/WZETA (t0=stZETA, t1=WZETA)
    address constant POOL_STZ = 0x01A9CD602C6c3f05EA9A3A55184c2181BD43e4B8; // stZeta StableSwap (native ZETA / stZETA)
    address constant POOL_STZ2= 0xEe1629De70AFaf3aE3592A9d6d859949750AA697; // stZeta StableSwap #2 (swaps revert)
    address constant FOURPOOL = 0x448028804461e8e5a8877c228F3adFd58c3Da6B6; // USDC.BSC/USDC.ETH/USDT.ETH/USDT.BSC
    address constant STZETA   = 0x45334a5B0a01cE6C260f2B570EC941C680EA62c0;
    address constant WZETA    = 0x5F0b1a82749cb4E2278EC87F8BF6B618dC71a8bf;
    address constant FARM1    = 0x14a4Ab67b637c366AC58C4F416C297Cd3037bDb3; // staking pair 0x16ef
    address constant FARM2    = 0xB681eC7C35534bd9131e02A31fe0eb698a81843F; // staking pair 0x4e77
    address constant FARM3    = 0xFd9048fC1f26765f60272f4E8B8D1C8faC62EB89; // staking pair 0x0c0b
    address constant FARM_OWNER = 0xfCA0392567D5eb77681843b2608dE9C625F57948;
    address constant PAIR_16EF = 0x16Ef1b018026E389FDA93c1e993E987CF6E852E7; // WZETA/ETH.ETH
    address constant PAIR_4E77 = 0x4E77A430a1b8E9055540b2A4aB8364E4E31089ae; // BNB.BSC/WZETA
    address constant PAIR_0C0B = 0x0C0B35C5eF00d9caD8D2ce65b147ea2A27d526Bc; // BTC.BTC/WZETA
    // stable-coin UniV2 pairs used for the FourPool arb test
    address constant PAIR_BFFF = 0xbfFF8702C61b2AdEb03e6235b597bafc791265C9; // USDC.ETH/WZETA
    address constant PAIR_3F2F = 0x3f2F671B4286fB3014892697a23085aC5E13F228; // WZETA/USDT.ETH

    address constant ATTACKER = address(0xBEEF);

    address[42] PAIRS = [
        0x0C0B35C5eF00d9caD8D2ce65b147ea2A27d526Bc,
        0x16Ef1b018026E389FDA93c1e993E987CF6E852E7,
        0x4E77A430a1b8E9055540b2A4aB8364E4E31089ae,
        0x10B4De1dE9dC1b5B66bbce613f56CABbAfD1Ef4c,
        0xC9D3BA9e55958f316cbB81FAD70c2608810124a6,
        0xbfFF8702C61b2AdEb03e6235b597bafc791265C9,
        0x3f2F671B4286fB3014892697a23085aC5E13F228,
        0x6b3Ee329B0Dc80D730D2De370BAD93cA122E75dB,
        0x380903d73b549450a736d3eF3EcE67Fd2F5d4100,
        0x79e1664752af13EBF6F1E77D62D349eafa3F1F58,
        0x1E1320E5e5C7b0D404730B57687d969C2aD7bd8D,
        0x15F53fDA7c6f9c5895ab08727056815208959d07,
        0x7ffF1Ce917dCA287a08A00F7EB0dE245c4D91E39,
        0x848011A4EdDb3f7ac908bcaCc31B1181f5B8b30D,
        0x2f04BEEe773EaAdfC6E1576a9666253D961275e6,
        0x1E4B1Dfec171c6A7256C18EDae97454e814E5402,
        0xA39DD0fe464065a593f52AAecA295fDcF3BD13da,
        0x76D2086e8f7EF2CD5088aDf935A0FE3961d5c20F,
        0x65163F74503BF88c67271eA3cC48c3eD3a935d56,
        0x8d90DB664fed607dF87777a8Ee7fB95A73652437,
        0x2B8Afb9e2E31A912F221DbAffDE160E1Fc3772Ec,
        0xFc80D320e17635B4143C57c789309e6339d1445b,
        0x86147E4adEF20A75B304bBe8e42253470D288350,
        0x96449704d9188EC5381ba59d3A76B239a9C74Ad7,
        0xb3A45039391F1bd0537C69B890Ac6FF4CB9834ef,
        0xFe11543a7581bd9Ad3B132A66259762946974240,
        0xD373BDF7Ca4967cf6899427343Af78A4A6935069,
        0x97E2a4159484B2eF235AEF6b29A26DFEFB93C85a,
        0x867D1a9609E96e97dCb4495C235025F4458C4BAE,
        0x90990520440C5FE1a62BB7aFA9A4ccc1C32C5776,
        0xcb312fcD8b8f8F9317366E95A0524303DA5BD266,
        0xbfa6f62A1bCA554416f03c5d778b9531cB051d91,
        0xe332129105d6BC3C55CcFC16647ffcfaa75140C9,
        0xF18063e481FF920e0d3e86d80C21d4F3F556B68a,
        0xBa3dF79B6c5fc7AF76fc8552eb574DEBb228Ae0b,
        0x50Dba55950700610a9ebe43c6F9bc361552Dd6df,
        0x1b2C1503a7b40421AEBd35B1419b5486F3602cb7,
        0xf186D74C36b07468E6Acd2A73655a93c621251Ff,
        0x9B23C15E9a9295AEdaa5e9b56940Ba6C65B43018,
        0xCACA505D5FAba6b652aCC4BAC7Df202a8453FD62,
        0xCAb75b3b5A83D2cfD793999433bE93e2EFDF1155,
        0x7F7735EbD341062427c2ee2F3435A6dF74935688
    ];

    function forkIt(string memory url) external {
        vm.createSelectFork(url);
    }

    function setUp() public {
        string[4] memory urls = [
            vm.envOr("ZETA_RPC_URL", string("https://7000.rpc.thirdweb.com")),
            string("https://zeta-chain.drpc.org"),
            string("https://zetachain-evm.blockpi.network/v1/rpc/public"),
            string("https://zetachain.rpc.thirdweb.com")
        ];
        bool ok = false;
        for (uint256 i = 0; i < urls.length && !ok; i++) {
            try this.forkIt(urls[i]) { ok = true; } catch {}
        }
        require(ok, "no working ZetaChain RPC");
        emit log_named_uint("fork block", block.number);
        vm.deal(address(this), 10_000 ether);
        vm.deal(ATTACKER, 10_000 ether);
    }

    // ---------------------------------------------------------------- 1. no excess, no self-held LP
    function test_LivePairs_NoExcess_NoSelfLP() public {
        uint256 funded;
        for (uint256 i = 0; i < PAIRS.length; i++) {
            IUniV2Pair p = IUniV2Pair(PAIRS[i]);
            address t0 = p.token0();
            address t1 = p.token1();
            (uint112 r0, uint112 r1,) = p.getReserves();
            uint256 b0 = IERC20(t0).balanceOf(PAIRS[i]);
            uint256 b1 = IERC20(t1).balanceOf(PAIRS[i]);
            uint256 lpSelf = IERC20(PAIRS[i]).balanceOf(PAIRS[i]);
            require(b0 == r0, "excess token0 found");
            require(b1 == r1, "excess token1 found");
            require(lpSelf == 0, "pair holds own LP (burnable by anyone!)");
            if (r0 > 0 && r1 > 0) funded++;
            require((r0 == 0) == (r1 == 0), "zero-reserve pair with value");
        }
        emit log_named_uint("pairs with both reserves > 0", funded);
    }

    // ---------------------------------------------------------------- 2. identical vanilla bytecode
    function test_AllPairs_SameBytecode() public {
        bytes32 ref = keccak256(PAIRS[1].code);
        for (uint256 i = 0; i < PAIRS.length; i++) {
            require(keccak256(PAIRS[i].code) == ref, "pair bytecode differs");
        }
        emit log_named_bytes32("pair runtime code hash", ref);
    }

    // ---------------------------------------------------------------- 3. skim yields zero
    function test_Skim_YieldsNothing() public {
        address[4] memory top = [PAIR_16EF, PAIR_4E77, PAIR_0C0B, PAIR_STZ];
        for (uint256 i = 0; i < top.length; i++) {
            IUniV2Pair p = IUniV2Pair(top[i]);
            address t0 = p.token0();
            address t1 = p.token1();
            uint256 before0 = IERC20(t0).balanceOf(address(this));
            uint256 before1 = IERC20(t1).balanceOf(address(this));
            p.skim(address(this));
            require(IERC20(t0).balanceOf(address(this)) == before0, "skim got token0");
            require(IERC20(t1).balanceOf(address(this)) == before1, "skim got token1");
        }
    }

    // ---------------------------------------------------------------- 4. no free drain via swap
    function test_SwapWithoutInput_Reverts() public {
        IUniV2Pair p = IUniV2Pair(PAIR_16EF);
        (uint112 r0,,) = p.getReserves();
        vm.expectRevert(); // UniswapV2: INSUFFICIENT_INPUT_AMOUNT / K
        p.swap(uint256(r0) - 1, 0, address(this), "");
    }

    // ---------------------------------------------------------------- 5. farm: fresh attacker cannot take staked LP
    function test_Farm_FreshAttacker_CannotWithdraw() public {
        IFarm[3] memory farms = [IFarm(FARM1), IFarm(FARM2), IFarm(FARM3)];
        for (uint256 i = 0; i < farms.length; i++) {
            require(farms[i].balanceOf(ATTACKER) == 0, "attacker has stake?");
            require(farms[i].rewardRate() == 0, "reward rate not zero");
            require(farms[i].periodFinish() == 0, "reward period not finished");
            require(farms[i].totalSupply() > 0, "farm empty");
            uint256 rt = IERC20(farms[i].rewardsToken()).balanceOf(address(farms[i]));
            require(rt == 0, "farm holds reward tokens");
            vm.prank(ATTACKER);
            vm.expectRevert();
            farms[i].withdraw(1 ether);
            // rewards(address) getter for a fresh address must be 0
            (bool ok, bytes memory ret) = address(farms[i]).staticcall(
                abi.encodeWithSignature("rewards(address)", ATTACKER));
            if (ok && ret.length >= 32) require(abi.decode(ret, (uint256)) == 0, "attacker has rewards");
            // claim attempts from a fresh address must not pay anything
            vm.prank(ATTACKER);
            (ok,) = address(farms[i]).call(abi.encodeWithSignature("getReward()"));
            emit log_named_string("getReward() from fresh attacker ok", ok ? "yes" : "no");
            require(IERC20(farms[i].rewardsToken()).balanceOf(ATTACKER) == 0, "attacker got rewards");
            // stake without LP must revert (transferFrom fails)
            vm.prank(ATTACKER);
            vm.expectRevert();
            farms[i].stake(1 ether);
        }
        // staked LP still accounted for
        emit log_named_uint("farm1 staked LP", IFarm(FARM1).totalSupply());
    }

    // ---------------------------------------------------------------- 5b. farm admin functions are gated
    function test_Farm_AdminFunctions_OwnerGated() public {
        vm.prank(ATTACKER);
        vm.expectRevert();
        (bool ok,) = FARM1.call(abi.encodeWithSignature("setPaused(bool)", true));
        ok;
        vm.prank(ATTACKER);
        vm.expectRevert();
        (ok,) = FARM1.call(abi.encodeWithSignature("notifyRewardAmount(uint256)", 1 ether));
        ok;
        vm.prank(ATTACKER);
        vm.expectRevert();
        (ok,) = FARM1.call(abi.encodeWithSignature("setRewardsDuration(uint256)", 1));
        ok;
    }

    // ---------------------------------------------------------------- 6. farm owner cannot rug staked LP via recoverERC20
    function test_FarmOwner_RecoverERC20_CannotTakeStakingToken() public {
        address st = IFarm(FARM1).stakingToken();
        uint256 farmLp = IERC20(st).balanceOf(FARM1);
        require(farmLp > 0, "no LP staked");
        // attacker: must revert
        vm.prank(ATTACKER);
        (bool okA,) = FARM1.call(abi.encodeWithSignature("recoverERC20(address,uint256)", st, farmLp));
        require(!okA, "recoverERC20 callable by attacker");
        // owner: must not move the staking token
        vm.prank(FARM_OWNER);
        (bool okO,) = FARM1.call(abi.encodeWithSignature("recoverERC20(address,uint256)", st, farmLp));
        emit log_named_string("owner recoverERC20(stakingToken) succeeded", okO ? "yes" : "no");
        require(IERC20(st).balanceOf(FARM1) == farmLp, "owner can rug staked LP!");
    }

    // ---------------------------------------------------------------- 7. ZetaEarn stZETA trades at ~9.5% discount on Eddy pair
    //    buy stZETA (0x45334a5b) with WZETA on Eddy pair 0x6b3ee329, redeem via ZetaEarn vault
    function test_ZetaEarnStZeta_DiscountOnEddyPair() public {
        uint256 x = 1900 ether; // WZETA spent
        IUniV2Pair pair = IUniV2Pair(PAIR_STZ); // t0=stZETA(0x45334a5b), t1=WZETA
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 out = (x * 997 * uint256(r0)) / (uint256(r1) * 1000 + x * 997);
        IWETH(WZETA).deposit{value: x}(); // wrap native ZETA
        IERC20(WZETA).transfer(PAIR_STZ, x);
        uint256 before = IERC20(STZETA).balanceOf(address(this));
        pair.swap(out, 0, address(this), "");
        uint256 got = IERC20(STZETA).balanceOf(address(this)) - before;
        // redemption value via ZetaEarn vault (proxy 0x45334a5b -> impl convertStZETAToZETA)
        (bool ok, bytes memory ret) = STZETA.staticcall(
            abi.encodeWithSignature("convertStZETAToZETA(uint256)", got));
        require(ok, "convertStZETAToZETA failed");
        uint256 redeemable = abi.decode(ret, (uint256));
        emit log_named_uint("WZETA spent", x);
        emit log_named_uint("stZETA bought from Eddy pair", got);
        emit log_named_uint("redeemable ZETA via ZetaEarn vault", redeemable);
        emit log_named_uint("gross profit (ZETA)", redeemable - x);
        require(redeemable > x, "no discount vs vault redemption rate");
    }

    // ---------------------------------------------------------------- 7b. two distinct stZETA tokens (no cross-pool arb)
    function test_TwoDifferentStZetaTokens() public {
        address afStZeta = IStableSwap(POOL_STZ).coins(1);   // Accumulated Finance stZETA
        address zeStZeta = IUniV2Pair(PAIR_STZ).token0();    // ZetaEarn stZETA
        require(afStZeta != zeStZeta, "same token");
        emit log_named_address("AF stZETA (pool 0x01a9cd)", afStZeta);
        emit log_named_address("ZetaEarn stZETA (pair 0x6b3ee329)", zeStZeta);
    }

    // ---------------------------------------------------------------- 8. FourPool vs UniV2: no arb (negative)
    function test_FourPool_CrossPoolArb_NotProfitable() public {
        uint256 x = 1 ether; // WZETA
        // WZETA -> USDC.ETH on 0xbfff (t0=USDC.ETH, t1=WZETA)
        IUniV2Pair p1 = IUniV2Pair(PAIR_BFFF);
        (uint112 a0, uint112 a1,) = p1.getReserves();
        uint256 usdcEth = (x * 997 * uint256(a0)) / (uint256(a1) * 1000 + x * 997);
        IWETH(WZETA).deposit{value: x}();
        IERC20(WZETA).transfer(PAIR_BFFF, x);
        p1.swap(usdcEth, 0, address(this), "");
        // USDC.ETH -> USDT.ETH on FourPool (coin1 -> coin2)
        IERC20(IStableSwap(FOURPOOL).coins(1)).approve(FOURPOOL, usdcEth);
        uint256 usdtEth = IStableSwap(FOURPOOL).exchange(1, 2, usdcEth, 0);
        // USDT.ETH -> WZETA on 0x3f2f (t0=WZETA, t1=USDT.ETH)
        IUniV2Pair p2 = IUniV2Pair(PAIR_3F2F);
        (uint112 b0, uint112 b1,) = p2.getReserves();
        uint256 out = (usdtEth * 997 * uint256(b0)) / (uint256(b1) * 1000 + usdtEth * 997);
        IERC20(IStableSwap(FOURPOOL).coins(2)).transfer(PAIR_3F2F, usdtEth);
        p2.swap(out, 0, address(this), "");
        emit log_named_uint("WZETA in", x);
        emit log_named_uint("WZETA out", out);
        require(out <= x, "unexpected arb profit");
    }

    // ---------------------------------------------------------------- 9. borked stZETA pool #2
    function test_StZeta_Pool2_SwapsBricked() public {
        vm.expectRevert();
        IStableSwap(POOL_STZ2).get_dy(0, 1, 1 ether);
    }

    // ---------------------------------------------------------------- 10. stableswap owner-gated admin
    function test_Stableswap_AdminIsOwnerGated() public {
        address[2] memory pools = [POOL_STZ, FOURPOOL];
        for (uint256 i = 0; i < pools.length; i++) {
            address owner = IStableSwap(pools[i]).owner();
            emit log_named_address("pool owner", owner);
            require(owner != address(0), "no owner");
            vm.prank(ATTACKER);
            vm.expectRevert();
            (bool ok,) = pools[i].call(abi.encodeWithSignature("withdraw_admin_fees()"));
            ok; // silence
        }
    }
}
