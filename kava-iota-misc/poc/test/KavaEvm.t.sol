// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

/// @title Kava EVM (chain 2222) — L2-25 "zombie-hunt II" harness: Tarot / Blueshift / Steer
/// @notice READ-ONLY research: only forks forked and simulated locally. No real-chain
///         transactions, no keys. `deal` funds the attacker with tokens it would buy on the
///         open market; their USD cost is charged in the PnL accounting.
///
/// Result summary (see analysis/kava-evm/findings.md for the full write-up):
///   TAROT: Tarot's collateral oracle prices the (dead, value-imbalanced) Vara pools as if the
///     LP/slice were balanced in value, so borrow power per deposited collateral reaches
///     R = 1/(safetyMarginSqrt*liquidationIncentive) * 2*reserve_i_usd/pool_usd  > 1.  On the
///     Avignon markets that latent over-borrow is worth ~$2.8k of lender cash in total, but the
///     only way to supply fresh collateral is minting the vault token (vTAROT), and vTAROT.mint()
///     deposits into the Voter masterChef whose `isAlive[gauge]` is FALSE on 10 of 11 markets ->
///     the gate blocks every profitable one.  The single market with a live gauge
///     (vTAROT WKAVA/VARA) is coincidentally ~50/50 in value -> R < 1 -> no profit.
///   BLUESHIFT: registry reports $193k USDT + 1120 WKAVA of stale TVL; every portfolio and LP
///     vault holds exactly zero -> $0 extractable.
///   STEER: 68 vaults, ~$1.5k live; poke() is permissionless and collects ~$0.02 of dust per
///     vault; fee collection / emergency functions are role-gated and roles are frozen.
///
/// Fork note: Kava prunes state quickly, so by default the fork is taken at `latest`.
/// Set KAVA_BLOCK to pin a block on an archive-capable RPC.

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

/// Vara Exchange (Solidly/Uniswap-V2-style) pair of a Tarot-vaulted market.
interface IVaraPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function mint(address to) external returns (uint256 liquidity);
}

/// Tarot VaultToken (vTAROT): holds a Vara vAMM LP and stakes it in the Voter masterChef.
interface IVaultToken {
    function underlying() external view returns (address);
    function gauge() external view returns (address);
    function totalSupply() external view returns (uint256);
    function totalBalance() external view returns (uint256);
    function exchangeRate() external returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
    function mint(address minter) external returns (uint256 mintTokens);
}

/// Tarot Collateral (pool token + collateralisation model).
interface ITarotCollateral {
    function getPrices() external returns (uint256, uint256);
    function safetyMarginSqrt() external view returns (uint256);
    function liquidationIncentive() external view returns (uint256);
    function exchangeRate() external returns (uint256);
    function totalSupply() external view returns (uint256);
    function totalBalance() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function mint(address minter) external returns (uint256 mintTokens);
    function tokensUnlocked(address from, uint256 value) external returns (bool);
}

/// Tarot Borrowable (lendable pool token).
interface ITarotBorrowable {
    function underlying() external view returns (address);
    function totalBalance() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function borrowBalance(address borrower) external view returns (uint256);
    function borrow(address borrower, address receiver, uint256 borrowAmount, bytes calldata data) external;
}

/// Vara Voter: gauges are only usable (deposit) while `isAlive[gauge]`.
interface IVoter {
    function isAlive(address gauge) external view returns (bool);
}

/// Steer MultiPositionKinetix vault (beacon proxy).
interface ISteerVault {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
    function getTotalAmounts() external view returns (uint256, uint256);
    function poke() external;
}

contract KavaEvmTarotBlueshiftSteerTest is Test {
    // ------------------------------------------------- TAROT market (Avignon lid 4), vTAROT(WKAVA/USDC)
    address constant TAROT_VTAROT = 0x109f3289665A8f034e2CACdBcfb678Cabe09f1d5;
    address constant TAROT_PAIR = 0x5C27a0D0e6d045b5113D728081268642060f7499; // vAMM-WKAVA/USDC LP
    address constant TAROT_COLL = 0xD48c5a6Bfb810dc6b08e33A76D055Ea09fC623cD;
    address constant TAROT_BOR1 = 0x014bEF3bE6dfd20E9539fadb48bcEc48bbfDA865; // USDC borrowable (cash ~$5.8k)
    address constant TAROT_GAUGE = 0x50CD5B513999b81dC3f4b70595629F7Cb92FCd32; // dead gauge

    // ------------------------------- TAROT market (Avignon lid 3), vTAROT(WKAVA/VARA) — only live gauge
    address constant TAROT3_VTAROT = 0x0de0FD789ec103bC076528e026F0e96bEe3C69DC;
    address constant TAROT3_PAIR = 0x7d8100072ba0e4dA8Dc6bd258859a5dC1A452e05;
    address constant TAROT3_GAUGE = 0xCa0d15B4BB6ad730fE40592f9E25A2E052842c92;
    address constant TAROT3_B0 = 0xA01b9Cc4860eea6e34c67A6198e6AeD175cd8B56; // WKAVA borrowable
    address constant TAROT3_B1 = 0x5815117c38e4d9f3e9BD562695D0a50aA7974ab7; // VARA borrowable
    address constant VOTER = 0x4eB2B9768da9Ea26E3aBe605c9040bC12F236a59;

    address constant WKAVA = 0xc86c7C0eFbd6A49B35E8714C5f59D99De09A225b;
    address constant USDC = 0xfA9343C3897324496A05fC75abeD6bAC29f8A40f;
    address constant VARA = 0xE1da44C0dA55B075aE8E2e4b6986AdC76Ac77d73;
    address constant BS_BLUES = 0x667Fd83E24Ca1D935d36717D305D54fA0CAC991C;
    address constant BS_USDT = 0xB44a9B6905aF7c801311e8F4E76932ee959c663C;
    address constant BS_DAI = 0x765277EebeCA2e31912C9946eAe1021199B39C61;

    // Steer Kava
    address constant STEER_VAULT = 0x6C21797DC7445A38C1E219A0146de7c784c92422; // USDT/axlUSDC

    // Blueshift Kava
    address constant BS_REGISTRY = 0x49399653f651A25924b3D8718276b5b4372577b1;
    address constant BS_MANUALPOOL = 0x7A60918Bd5c83Ef7e2ABA87D13e3FD704f6A77E1;
    address constant BS_PF0 = 0xA8893E7d58D079A8fB7d999a19fe46682adA52FE;
    address constant BS_PF1 = 0x67C85757DEa3Bc6358C1352d1185E05CE8CB0406;
    address constant BS_LP0 = 0x217F778528015Eea8608758Bf3a2caA25284DD9A;
    address constant BS_LP1 = 0x7582eAac8532c39f3c02caE7142F0a5286d348F3;

    address constant ATTACKER = address(0xA11CE);

    // Spot prices, 2026-10-15 (DefiLlama coins API / GeckoTerminal Kava pools).
    uint256 constant WKAVA_USD = 0.06880e18;   // DefiLlama kava:0xc86c...
    uint256 constant USDC_USD = 0.99965e18;    // DefiLlama kava:0xfa93...
    uint256 constant VARA_USD = 0.0000020408e18; // GeckoTerminal VARA/WKAVA pool 0x7d81...

    uint256 forkBlock;

    function setUp() public {
        uint256 pinned = vm.envOr("KAVA_BLOCK", uint256(0));
        string memory rpc = vm.envOr("KAVA_RPC", string("https://evm.kava.io"));
        if (pinned == 0) {
            vm.createSelectFork(rpc);
        } else {
            vm.createSelectFork(rpc, pinned);
        }
        forkBlock = block.number;
    }

    // ---------------------------------------------------------------- Tarot

    /// @notice Latent over-borrow on the biggest market (vTAROT WKAVA/USDC): the oracle values a
    ///         USDC-heavy dead pool as if balanced, so R = borrow/deposit = 1.36 > 1 (~$1.5k of
    ///         the borrowable's cash). It is NOT executable: minting the required vTAROT collateral
    ///         reverts because the Voter says the gauge is dead.
    function test_Tarot_LatentOverBorrow_BlockedByDeadGauge() public {
        (uint256 cashUsdc, uint256 r, uint256 latentUsd) = _tarotMispricing(TAROT_VTAROT, TAROT_PAIR, TAROT_COLL, TAROT_BOR1);
        emit log_named_uint("fork block", forkBlock);
        emit log_named_uint("borrowable USDC cash (1e6)", cashUsdc);
        emit log_named_uint("borrow power / collateral value R (1e18)", r);
        emit log_named_uint("latent extraction USD (1e18)", latentUsd);
        // NOTE: R is state-dependent (the Vara pool composition changes with live trades), so it is
        // logged, not hard-asserted. The load-bearing assertions of this test are the gates below:
        // the collateral-supply route (vTAROT.mint) is blocked by the dead Voter gauge regardless
        // of R. The measured R range (1.361-1.382 at 2026-10-15 blocks 23035381-23036305, latent
        // $2,828.30) is recorded in analysis/kava-evm/{findings.md,state.json}.
        emit log_named_uint("R (1e18, informational)", r);

        // The collateral-supply gate: gauge liveness in the Voter.
        bool alive = IVoter(VOTER).isAlive(TAROT_GAUGE);
        emit log_named_string("voter.isAlive(TAROT_GAUGE)", alive ? "true" : "false");
        assertFalse(alive, "gauge revived - latent path may now be live");

        // Try the attack's supply step: add liquidity, hand the LP to the vault, mint vTAROT.
        (uint256 dep0, uint256 dep1) = _pairDepositFor(1000, TAROT_PAIR); // small probe deposit
        deal(WKAVA, ATTACKER, dep0);
        deal(USDC, ATTACKER, dep1);
        vm.startPrank(ATTACKER);
        require(IERC20(WKAVA).transfer(TAROT_PAIR, dep0), "wkava");
        require(IERC20(USDC).transfer(TAROT_PAIR, dep1), "usdc");
        uint256 lp = IVaraPair(TAROT_PAIR).mint(ATTACKER);
        require(lp > 0, "lp");
        require(IERC20(TAROT_PAIR).transfer(TAROT_VTAROT, lp), "lp->vault");
        bool minted;
        try IVaultToken(TAROT_VTAROT).mint(ATTACKER) returns (uint256) {
            minted = true;
        } catch {
            minted = false;
        }
        vm.stopPrank();
        emit log_named_string("vTAROT.mint() via dead gauge", minted ? "minted" : "reverted (gate)");
        assertFalse(minted, "mint succeeded - re-evaluate the gate");
    }

    /// @notice The single market whose gauge is still alive (vTAROT WKAVA/VARA) is mintable, but
    ///         its pool is ~50/50 in realised value once the Kava VARA market price is used, so
    ///         R < 1 for both borrowables -> no extraction.
    function test_Tarot_LiveGaugeMarket_MintableButNotProfitable() public {
        emit log_named_uint("fork block", forkBlock);
        bool alive = IVoter(VOTER).isAlive(TAROT3_GAUGE);
        emit log_named_string("voter.isAlive(0xca0d...)", alive ? "true" : "false");
        assertTrue(alive, "live gauge changed");

        (uint256 rWkava, uint256 rVara) = _tarot3R();
        emit log_named_uint("R borrow WKAVA (1e18)", rWkava);
        emit log_named_uint("R borrow VARA (1e18)", rVara);
        assertLt(rWkava, 1e18, "WKAVA side profitable?");
        assertLt(rVara, 1e18, "VARA side profitable?");

        // Prove the supply path works when the gauge is alive: deposit a small proportional LP.
        (uint256 dep0, uint256 dep1) = _pairDepositFor(1000, TAROT3_PAIR); // 0.1% of the pair
        deal(WKAVA, ATTACKER, dep0);
        deal(VARA, ATTACKER, dep1);
        vm.startPrank(ATTACKER);
        require(IERC20(WKAVA).transfer(TAROT3_PAIR, dep0), "wkava");
        require(IERC20(VARA).transfer(TAROT3_PAIR, dep1), "vara");
        uint256 lp = IVaraPair(TAROT3_PAIR).mint(ATTACKER);
        require(lp > 0, "lp");
        require(IERC20(TAROT3_PAIR).transfer(TAROT3_VTAROT, lp), "lp->vault");
        uint256 vt = IVaultToken(TAROT3_VTAROT).mint(ATTACKER);
        vm.stopPrank();
        emit log_named_uint("vTAROT minted on live gauge", vt);
        assertGt(vt, 0, "live-gauge mint failed");
    }

    /// @dev R = (borrow power per vTAROT-wei in USD) / (vTAROT fair value in USD), plus the
    ///      borrowable's cash converted to USD. R uses the on-chain oracle price and margin
    ///      parameters, so it is the exact condition `borrow()` enforces.
    function _tarotMispricing(address vt, address pair, address coll, address bor)
        internal
        returns (uint256 cashUsdc, uint256 r, uint256 latentUsd)
    {
        uint256 fairPerVt;
        {
            (uint112 r0_, uint112 r1_, ) = IVaraPair(pair).getReserves();
            uint256 lpTs = IVaraPair(pair).totalSupply();
            uint256 usdPerLpWei =
                (((uint256(r0_) * WKAVA_USD) / 1e18) + ((uint256(r1_) * USDC_USD) / 1e6)) / lpTs;
            fairPerVt = (usdPerLpWei * IVaultToken(vt).exchangeRate()) / 1e18;
        }
        uint256 borrowUsdPerVt;
        {
            ITarotCollateral c = ITarotCollateral(coll);
            ( , uint256 price1) = c.getPrices(); // vTAROT-wei per USDC-wei, 1e18-scaled
            uint256 smxli = (c.safetyMarginSqrt() * c.liquidationIncentive()) / 1e18; // 1.442e18
            // debt capacity = 1e54/(price*sm*li) token-wei per vTAROT-wei; keep 1e18 scaling
            uint256 borrowUsdcWeiPerVt1e18 = 1e54 / (price1 * smxli);
            borrowUsdPerVt = ((borrowUsdcWeiPerVt1e18 * USDC_USD) / 1e6) / 1e18;
        }
        r = (borrowUsdPerVt * 1e18) / fairPerVt;
        cashUsdc = IERC20(USDC).balanceOf(bor);
        {
            uint256 tb = ITarotBorrowable(bor).totalBalance();
            if (cashUsdc > tb) cashUsdc = tb;
        }
        latentUsd = r > 1e18 ? (((cashUsdc * USDC_USD) / 1e6) * (r - 1e18)) / r : 0;
    }

    /// @dev R for both borrowables of market 3 (WKAVA/VARA) using realised market prices.
    ///      R_i = 2*value_i / (smxli * pool_value) — the on-chain oracle books each side at
    ///      2*reserve_i, so R_i > 1 exactly when the pool is more than ~69% weighted to side i.
    function _tarot3R() internal view returns (uint256 rWkava, uint256 rVara) {
        (uint112 r0_, uint112 r1_, ) = IVaraPair(TAROT3_PAIR).getReserves();
        uint256 usd0 = (uint256(r0_) * WKAVA_USD) / 1e18; // 1e18
        uint256 usd1 = (uint256(r1_) * VARA_USD) / 1e18;  // 1e18
        uint256 coll = usd0 + usd1;
        ITarotCollateral c = ITarotCollateral(0x23bA7F8C3264eCb1E970e940e2Aa6d2724Fb54C8);
        uint256 smxli = (c.safetyMarginSqrt() * c.liquidationIncentive()) / 1e18; // 1.442e18
        rWkava = (2 * usd0 * 1e18) / ((smxli * coll) / 1e18);
        rVara = (2 * usd1 * 1e18) / ((smxli * coll) / 1e18);
    }

    /// @dev Proportional deposit amounts for `bps` (=1000 -> 10%) of the pair's reserves.
    function _pairDepositFor(uint256 bps, address pair) internal view returns (uint256 dep0, uint256 dep1) {
        (uint112 r0_, uint112 r1_, ) = IVaraPair(pair).getReserves();
        dep0 = (uint256(r0_) * bps) / 10_000 + 1;
        dep1 = (uint256(r1_) * bps) / 10_000 + 1;
    }

    // ---------------------------------------------------------------- Steer

    /// @notice Negative result: poke() is permissionless but collects only dust; fee collection
    ///         and emergency paths are role-gated (roles frozen: no DEFAULT_ADMIN_ROLE holders).
    function test_Steer_PokeIsDust_CollectGated() public {
        ISteerVault vault = ISteerVault(STEER_VAULT);
        (uint256 a0, uint256 a1) = vault.getTotalAmounts();

        vm.prank(ATTACKER);
        vault.poke();
        (uint256 b0, uint256 b1) = vault.getTotalAmounts();

        emit log_named_int("poke delta token0 (1e6)", int256(b0) - int256(a0));
        emit log_named_int("poke delta token1 (1e6)", int256(b1) - int256(a1));

        vm.prank(ATTACKER);
        (bool ok1, ) = STEER_VAULT.call(abi.encodeWithSelector(0x8ea234cb, uint256(0), uint256(0), ATTACKER)); // steerCollectFees
        vm.prank(ATTACKER);
        (bool ok2, ) = STEER_VAULT.call(abi.encodeWithSelector(0xabbffcb9, int24(-887220), int24(887220), uint128(1))); // emergencyBurn
        emit log_named_string("steerCollectFees success", ok1 ? "yes" : "no (revert)");
        emit log_named_string("emergencyBurn success", ok2 ? "yes" : "no (revert)");
        assertFalse(ok1, "steerCollectFees must be role-gated");
        assertFalse(ok2, "emergencyBurn must be role-gated");

        assertLt(int256(b0) - int256(a0), 1e6, "fees token0 < 1 USDT");
        assertLt(int256(b1) - int256(a1), 1e6, "fees token1 < 1 axlUSDC");
    }

    // ---------------------------------------------------------------- Blueshift

    /// @notice Negative result: registry-reported TVL ($193k USDT + 1120 WKAVA) is stale; every
    ///         portfolio and LP vault on Kava holds exactly zero value.
    function test_Blueshift_StaleTVL_ZeroCustody() public {
        address[4] memory holders = [BS_PF0, BS_PF1, BS_LP0, BS_LP1];
        address[5] memory tokens = [BS_USDT, USDC, BS_DAI, WKAVA, BS_BLUES];
        for (uint256 i = 0; i < holders.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                assertEq(IERC20(tokens[j]).balanceOf(holders[i]), 0, "Blueshift contract holds value?");
            }
        }
        emit log_named_uint("manualPool BLUES (staked, unpriced)", IERC20(BS_BLUES).balanceOf(BS_MANUALPOOL));
        emit log_named_uint("registry USDT balance", IERC20(BS_USDT).balanceOf(BS_REGISTRY));
    }
}
