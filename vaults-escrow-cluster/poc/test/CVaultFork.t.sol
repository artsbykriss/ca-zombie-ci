// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function transfer(address, uint256) external returns (bool);
}

interface IRLP is IERC20 {
    function rlpPerLP() external view returns (uint256);
    function migratedToSushi() external view returns (bool);
    function rebase() external;
    function wrap() external;
    function SUSHI_DELTA_WETH_PAIR() external view returns (address);
}

interface IERC95 is IERC20 {
    function getTokenInfo(uint256 id) external view returns (address, uint256, uint256);
    function unwrap(uint256 amount) external;
    function skim(address to) external;
    function paused() external view returns (bool);
}

/// @notice Fork proof for the cVault Finance / Delta lineage vaults.
/// ETH mainnet only; read-only except for calls on the local fork.
contract CVaultForkTest is Test {
    // Deployed addresses recovered from the historical DefiLlama adapter (2022-08-10 commit
    // 4a10aad39e77, projects/core/index.js) and verified on-chain.
    address constant RLP   = 0xfcfC434ee5BfF924222e084a8876Eee74Ea7cfbA; // DELTA rLP (TransparentUpgradeableProxy)
    address constant DFV   = 0x9fE9Bb6B66958f2271C4B0aD23F6E8DDA8C221BE; // DELTA Deep Farming Vault (proxy)
    address constant COREDAI = 0x00a66189143279b6DB9b77294688F47959F37642; // ERC95 coreDAI
    address constant COREBTC = 0x7b5982dcAB054C377517759d0D2a3a5D02615AB8; // ERC95 cBTC
    address constant DAI   = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant WBTC  = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant WETH  = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DELTA = 0x9EA3b5b4EC044b70375236A281986106457b20EF;

    function setUp() public {
        vm.createSelectFork(vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com"))));
    }

    /// rLP holds ~99.97% of the DELTA/WETH Sushi LP and exposes no redemption path.
    function test_rlp_holds_almost_all_SLP_and_has_no_unwrap() public {
        address slp = IRLP(RLP).SUSHI_DELTA_WETH_PAIR();
        uint256 slpBal = IERC20(slp).balanceOf(RLP);
        uint256 slpSupply = IERC20(slp).totalSupply();
        uint256 rlpSupply = IERC20(RLP).totalSupply();

        emit log_named_uint("SLP in rLP", slpBal);
        emit log_named_uint("SLP totalSupply", slpSupply);
        emit log_named_uint("rLP totalSupply", rlpSupply);
        emit log_named_uint("rlpPerLP", IRLP(RLP).rlpPerLP());

        assertGt(slpBal, (slpSupply * 999) / 1000, "rLP should hold >99.9% of SLP");
        assertGt(rlpSupply, 0);

        // No unwrap/withdraw/redeem selector exists on the deployed implementation.
        (bool ok,) = RLP.call(abi.encodeWithSignature("unwrap(uint256)", uint256(1)));
        assertFalse(ok, "rLP must not expose unwrap(uint256)");
        (ok,) = RLP.call(abi.encodeWithSignature("withdraw(uint256)", uint256(1)));
        assertFalse(ok, "rLP must not expose withdraw(uint256)");
        (ok,) = RLP.call(abi.encodeWithSignature("redeem(uint256)", uint256(1)));
        assertFalse(ok, "rLP must not expose redeem(uint256)");
    }

    /// The rebase machinery (the only thing that could release LP / change the ratio) is hard-disabled.
    function test_rebase_reverts() public {
        vm.expectRevert();
        IRLP(RLP).rebase();
    }

    /// Depositing SLP today mints rLP at 0.0724 while each rLP is backed by 1.032 SLP:
    /// a new wrapper loses ~92.5% of the value it deposits. No inflation/donation profit.
    function test_wrap_is_value_destructive_not_profitable() public {
        address slp = IRLP(RLP).SUSHI_DELTA_WETH_PAIR();
        uint256 rlpSupply = IERC20(RLP).totalSupply();
        uint256 slpBal = IERC20(slp).balanceOf(RLP);
        uint256 ratio = IRLP(RLP).rlpPerLP();

        uint256 mintedPerSlp = (1e18 * ratio) / 1e18;              // rLP minted for 1 SLP
        uint256 slpPerRlp = (slpBal * 1e18) / rlpSupply;           // live backing per rLP
        uint256 slpValueOfMint = (mintedPerSlp * slpPerRlp) / 1e18;

        emit log_named_uint("rLP minted per 1 SLP (wei)", mintedPerSlp);
        emit log_named_uint("SLP backing per 1 rLP (wei)", slpPerRlp);
        emit log_named_uint("SLP value received per 1 SLP deposited", slpValueOfMint);

        assertLt(slpValueOfMint, 1e17, "wrap must return <0.1 SLP of value per SLP");
    }

    /// coreDAI is exactly 1:1 backed; skim() has no excess to pay out (no donation drain).
    function test_coredai_fully_backed_and_skim_empty() public {
        (address underlying, uint256 reserve,) = IERC95(COREDAI).getTokenInfo(0);
        uint256 bal = IERC20(underlying).balanceOf(COREDAI);
        uint256 supply = IERC20(COREDAI).totalSupply();
        assertEq(underlying, DAI);
        assertEq(bal, reserve, "reserve must equal real DAI balance");
        assertEq(bal, supply, "1 coreDAI == 1 DAI");

        uint256 before = IERC20(DAI).balanceOf(address(0xBEEF));
        IERC95(COREDAI).skim(address(0xBEEF));
        assertEq(IERC20(DAI).balanceOf(address(0xBEEF)), before, "skim pays nothing");
        assertFalse(IERC95(COREDAI).paused());
    }

    /// cBTC is exactly 1:1 backed as well.
    function test_cbtc_fully_backed() public {
        (address underlying, uint256 reserve,) = IERC95(COREBTC).getTokenInfo(0);
        uint256 bal = IERC20(underlying).balanceOf(COREBTC);
        assertEq(underlying, WBTC);
        assertEq(bal, reserve);
        assertEq(bal, IERC20(COREBTC).totalSupply());
    }

    /// DFV holds WETH/DELTA reward inventory; rewards belong to farming-power holders (H-O).
    function test_dfv_reward_inventory() public {
        uint256 weth = IERC20(WETH).balanceOf(DFV);
        uint256 delta = IERC20(DELTA).balanceOf(DFV);
        uint256 rlp = IERC20(RLP).balanceOf(DFV);
        emit log_named_uint("DFV WETH", weth);
        emit log_named_uint("DFV DELTA", delta);
        emit log_named_uint("DFV rLP", rlp);
        assertGt(weth, 0);
        assertGt(delta, 0);
        assertGt(rlp, 0);
    }
}

interface ICoreVault {
    function poolInfo(uint256 pid) external view returns (address token, uint256 allocPoint, uint256 accCorePerShare, bool withdrawable);
    function userInfo(uint256 pid, address user) external view returns (uint256 amount, uint256 rewardDebt);
    function withdrawFrom(address owner, uint256 pid, uint256 amount) external;
    function core() external view returns (address);
}

/// The original cVault staking vault (CoreVault) is a live masterchef; its CORE inventory is
/// owed to COREDAO stakers and withdrawals are per-owner.
contract CoreVaultForkTest is Test {
    address constant COREVAULT = 0xC5cacb708425961594B63eC171f4df27a9c0d8c9;
    address constant COREDAO = 0xf66Cd2f8755a21d3c8683a10269F795c0532Dd58;
    address constant CORE = 0x62359Ed7505Efc61FF1D56fEF82158CcaffA23D7;
    address constant STAKER = 0x147c90DAd8e33aE3E916Aa3CA779d56Aa3ae129e;
    address constant ATTACKER = address(0xA77ACC);

    function setUp() public {
        vm.createSelectFork(vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com"))));
    }

    function test_corevault_pool_state_and_withdraw_auth() public {
        ICoreVault v = ICoreVault(COREVAULT);
        (address token, uint256 alloc, uint256 acc, bool withdrawable) = v.poolInfo(3);
        assertEq(token, COREDAO);
        assertEq(alloc, 1000);
        assertTrue(withdrawable);
        assertGt(acc, 0);

        (uint256 staked, uint256 debt) = v.userInfo(3, STAKER);
        emit log_named_uint("staker COREDAO", staked);
        emit log_named_uint("staker rewardDebt (CORE)", debt);
        assertGt(staked, 0);

        uint256 coreBal = IERC20(CORE).balanceOf(COREVAULT);
        emit log_named_uint("CoreVault CORE inventory", coreBal);
        assertGt(coreBal, 25e18);

        // A stranger cannot pull another user's stake.
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("withdraw: insufficient allowance"));
        v.withdrawFrom(STAKER, 3, 1);
    }
}
