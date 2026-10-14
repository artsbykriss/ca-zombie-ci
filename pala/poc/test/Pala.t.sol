// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
}

interface IUniV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function skim(address to) external;
    function sync() external;
}

interface IUniV2Factory {
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function allPairsLength() external view returns (uint256);
    function allPairs(uint256) external view returns (address);
}

interface IPalaToken {
    function owner() external view returns (address);
    function isMinter(address) external view returns (bool);
    function mint(uint256 amount) external;
    function mint(address to, uint256 amount) external;
}

interface IMasterChef {
    function owner() external view returns (address);
    function migrator() external view returns (address);
    function devaddr() external view returns (address);
    function migrate(uint256 pid) external;
    function dev(address) external;
    function poolLength() external view returns (uint256);
    function poolInfo(uint256) external view returns (address lpToken, uint256 totalLP, uint256 allocPoint, uint256 lastRewardBlock, uint256 accRewardPerShare);
    function pendingReward(uint256 pid, address user) external view returns (uint256);
    function harvest(uint256 pid) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function emergencyWithdraw(uint256 pid) external;
    function rewardPerBlock() external view returns (uint256);
    function BONUS_MULTIPLIER() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);
}

interface IPalaViewer {
    function tokenPrice(address token) external view returns (uint256);
    function kusdt() external view returns (address);
}

/// @title Pala (Kaia) live extraction PoC — zombie-hunt L2 Phase-2
/// @notice Read-only research: runs on a fork only; no mainnet transactions.
contract PalaTest is Test {
    string constant RPC_ENV = "KAIA_RPC_URL";
    address constant FACTORY = 0xA25ba09d8837F6319cD65B2345c0bbEa99c39Cb1;
    address constant VIEWER = 0x2B16648ddD1559fc86e0c0617213Ab5dd2Ea01B9;
    address constant PALA_FARM = 0xCFC140E8e3b1B05f9ACb4a42249b7aBB8c27576C;
    address constant ATTEN_FARM = 0x883726a307D420286086679F7851d8378bb16771;
    address constant PALA = 0x7A1CdCA99FE5995ab8E317eDE8495c07Cbf488aD;
    address constant ATTEN = 0x9160421eA3D1a24101D985B026a60cB0442322cc;
    address constant PKLAY = 0x1F2D6282D74EF26eB6c7e28b9e7048c1B42EbDa5;
    address constant ATTACKER = address(0xBEEF);

    address[] pools;

    function setUp() public {
        string memory rpc = vm.envOr(RPC_ENV, string("https://rpc.ankr.com/kaia"));
        vm.createSelectFork(rpc);
        _loadPools();
    }

    function _loadPools() internal {
        // Embedded snapshot of the factory's 89 pairs (allPairsLength verified == 89).
        // Also cross-checked against factory.allPairsLength() in test_factoryCount.
        pools.push(address(0x2d2926AC369e5b1d32e56d0fBBC7471Ee29a8bCD));
        pools.push(address(0x369E840bd79A291F2640D63fb60AC032c894f2B7));
        pools.push(address(0xc556be31D170cA00241231371E139C8e4c0fc204));
        pools.push(address(0x4755cb2bf13Cf07a00368AE4A2Ea4de2EB1Dc1a6));
        pools.push(address(0xAb47eDf354348e14cFcc1949b38BF2317d510B79));
        pools.push(address(0x2caA83Af6bBF61Dc15e7BCC5952bbb554358AD11));
        pools.push(address(0xA82d38CAC00511509390A6f25473882D3393EDAa));
        pools.push(address(0x27FfA35d4e2443C734e25b34bBb8eF217356Cf85));
        pools.push(address(0xf1B48634169018bd5B02906d77c8C9b738A87BCb));
        pools.push(address(0xDa8360D22Eb242AeF4810ad7607106cA1797b471));
        pools.push(address(0xaf56eD56CDEe9ab2D4182bBB0977F82D4E2f4961));
        pools.push(address(0xC34BD77D0593147742D82e483A4e57a58254ea4E));
        pools.push(address(0xbc25D598E2785A0565E9B8A60596aa9Bd8FD736F));
        pools.push(address(0x62901A469D39d557c9D9E64991D158DD5315312F));
        pools.push(address(0xf8f1B9bb7F06a7C60ad19260D084D9AD9C9d9a47));
        pools.push(address(0x491578980069c0d006A28F6bCb307511B777693A));
        pools.push(address(0xBDd6de24Eb9A29Cf7E03Ca1a3982CeD6716e8d00));
        pools.push(address(0x1c599095b13eF83b3236dDbe3188DED6081bc745));
        pools.push(address(0x44608c68800763d3884E25d963560b9a5aA43902));
        pools.push(address(0xb52C28131a3688cEc192546B32206d07281A3D42));
        pools.push(address(0x50870926b6cCc6280C7cc6dC0e3823Aa8626e3CE));
        pools.push(address(0x6BB2577a3bf57f5B4bCB0b90017c21EFFf0E81f2));
        pools.push(address(0x0fEC1BCC6C21a0D42A6Bc8D0922Aa7F791Fe90f9));
        pools.push(address(0xF14e27B58e283dA0375D35b6c6f4219C2DB53631));
        pools.push(address(0x026e4968a4F90957D807a79baC82093Cdc9Dcc3d));
        pools.push(address(0xF02c83854a9DE462c655Ff1402b9b86c82421912));
        pools.push(address(0xeDb1C22e9690a4e7D9F20d3ee87341233D10fabb));
        pools.push(address(0x38E3c2d31A776DFa53A894c8EAf9e42b267F896f));
        pools.push(address(0xD13Dbb8C2ACd70a8F90BBe2f706B94a8Fe7FCdfd));
        pools.push(address(0x0b8194512242cE49c5ad9B2Eb89E3A834028c38D));
        pools.push(address(0x3088D712DEFD9915C59A7c1F7Bef64eC12282895));
        pools.push(address(0x8ED733FE18a4922bC1f9d25f85d8Db422fC35CEC));
        pools.push(address(0xF24dF9A35610A67DC9EF74861aa2C6a884F8E5Cf));
        pools.push(address(0x67865e5672410C893291A81023401bB6b7A0D374));
        pools.push(address(0x79575870638176528A2cAdC812902f7A75c37A11));
        pools.push(address(0xBB9645B25Ef471e611ED6595d3934cA1ffD8aC19));
        pools.push(address(0x98FdD37399222211D7047f10bf47fa3bEdc916F4));
        pools.push(address(0x515316a0800589ccCc364D9BF48aA0F1088525c4));
        pools.push(address(0xd87ed50A6957a3D2386bE7B047f1cc52Cfa21bC2));
        pools.push(address(0x46b53487F608151aAddF320b1e77CE67Ef076589));
        pools.push(address(0xC775a12878d843c0ccF27fF905fde0D1819E0f03));
        pools.push(address(0x3E798017ed2098d8cB6Ee23B57a0b15e184556E1));
        pools.push(address(0x0e928fD8E093BA9308b40288787f104e7bD9312e));
        pools.push(address(0xafC44475F6ff89B4604236AcB366841e46eaAB0E));
        pools.push(address(0x820989464385D7A60e64A9Dc0e517999BDc5BBf6));
        pools.push(address(0x18095063c21C19a344adf09F15FF428e38A41F1c));
        pools.push(address(0xd82604613eB1856275834837B9cE7757426fF92E));
        pools.push(address(0xe78082f4809AB828FF70EBF2aBA3FC8ddC6fa3BB));
        pools.push(address(0x78A0Ad0a626E4a9A3f369F386384aABcC170f5E6));
        pools.push(address(0x25b8aDF9d4f5e6BAD370B340974fe5c338F4bd93));
        pools.push(address(0xB7b4B1Ea30Dc3c54772aD2850b5d0b6af8A512E5));
        pools.push(address(0x708a879A298340d5269dAfc19C264f871D71B854));
        pools.push(address(0x863Ad6BE9e84DF73117028c3B0B76411270DA061));
        pools.push(address(0xBFd04D20dA962fb700461fEE078d9549ebB29ed5));
        pools.push(address(0x5288D232A6d731b9A9c171Fd618f780B6410Ce97));
        pools.push(address(0x9D87F31f3F95E8173225579a49dD45BE314A05D7));
        pools.push(address(0x0eE020a5AC443157BD336D8257b01570E4eC3DC6));
        pools.push(address(0xfd14f80321E899c6023daA1B2d36a400A595beBd));
        pools.push(address(0xf7469c09a68AB6D52bDb4dF1d95D7755C80A74C5));
        pools.push(address(0x3910654BF805BFf385e58D2B0cf48ab26B8B624b));
        pools.push(address(0xD90F637a7A1362028f8ad77Eba9655C7b92BB919));
        pools.push(address(0xCd3e6778ad13c6ba6914b4d0241491047b7640D1));
        pools.push(address(0xCF673B9CDDdEce28A0820133f44A5175aE967589));
        pools.push(address(0xBb6C0A0DD21Bb3b880228C7736a7301f48B8200E));
        pools.push(address(0x98CE34c69C0C7A4f20979E9f285E45128312Eee9));
        pools.push(address(0x8115AA94d24B505ef8a47B1dad632F04c5084f5D));
        pools.push(address(0x6dbDA1f57a1080A113ef3677dB182Db4C961D185));
        pools.push(address(0x8ea2a2bDFe43F9Ab2787F00Acd20890633364C99));
        pools.push(address(0xf1f8A7C007aBaA87969D5eb26696f9108d46CddD));
        pools.push(address(0x1fe2b958586689Eb5C8aB7BBC66727f702136724));
        pools.push(address(0xFbFda9b7188757eF208f1D36b83b099a10Eb88FF));
        pools.push(address(0x51D459EaCDbFE15a6BeDbF409Ecb2d6368131880));
        pools.push(address(0x52129b3038E564281D104ae4F157cDC9C05EAb47));
        pools.push(address(0x604eFEc82acbE0A692cc5d8B1555C82ccdF0C4Ec));
        pools.push(address(0x584D207eB248213C11D41ecBeb6e914591b30eDE));
        pools.push(address(0x7BeDD8a95694AF92CD569271cC50Ca4c68fc6D01));
        pools.push(address(0xDEF45cEC5b716696BC9Ab704f3FB25e8C26C2FD6));
        pools.push(address(0x7Ac8C172aBBFBB85bbB49099adA6Ee9fb33B45d1));
        pools.push(address(0x13DCe59d0502733B0062e802Ea19dD04FC9b6D39));
        pools.push(address(0x95968f735e7C53Db1E398fDd15770b753521489d));
        pools.push(address(0xAA17FE5bAF59494c725C8078a4eC5bD6856934E0));
        pools.push(address(0x5C8AADcBF79A861bF8F7Ec69Eb2bF6FE15b75e2E));
        pools.push(address(0xD73eCb2d3D7bA3f17F0a05B0336fA42443325D7f));
        pools.push(address(0x03Cbb2Bb9aB28F265cAc4673363EF47E4C80bCDD));
        pools.push(address(0x13Ee889684e6A610f3878cE8D61B0Ba34E0Fe809));
        pools.push(address(0x99Fd702EC3B265EBC13b6176c0Fe51655FB5d4d0));
        pools.push(address(0xe5f51fA7866AB4e79265413C29604F56218A64dc));
        pools.push(address(0xDC2F16bE70d00015E1627677c2888685235b3082));
        pools.push(address(0xa97F878135dACcD900BeAB962192b1F763062330));
    }

    // ---------------------------------------------------------------- tests

    /// @notice Factory pair count must equal our embedded list (sanity of the target set).
    function test_factoryCount() public {
        uint256 n = IUniV2Factory(FACTORY).allPairsLength();
        emit log_named_uint("factory.allPairsLength", n);
        emit log_named_uint("embedded pools", pools.length);
        assertEq(n, 89, "pair count");
        assertEq(pools.length, 89, "embedded count");
        for (uint256 i = 0; i < pools.length; i++) {
            address fromFactory = IUniV2Factory(FACTORY).allPairs(i);
            bool found = false;
            for (uint256 j = 0; j < pools.length; j++) {
                if (pools[j] == fromFactory) { found = true; break; }
            }
            assertTrue(found, "every factory pair present in list");
        }
    }

    /// @notice E-U candidate: skim() excess balances from every pool. Anyone may call skim(to).
    /// Measures attacker's net token gains starting from zero.
    function test_skimExcess() public {
        uint256 forkBlock = block.number;
        uint256 gasStart = gasleft();
        uint256 calls;
        uint256 skipped;
        uint256 failed;

        string memory json = "{\"fork_block\":";
        json = string.concat(json, vm.toString(forkBlock), ",\"pools\":[");

        for (uint256 i = 0; i < pools.length; i++) {
            IUniV2Pair p = IUniV2Pair(pools[i]);
            address t0 = p.token0();
            address t1 = p.token1();
            (uint112 r0, uint112 r1,) = p.getReserves();
            uint256 b0 = IERC20(t0).balanceOf(pools[i]);
            uint256 b1 = IERC20(t1).balanceOf(pools[i]);
            uint256 ex0 = b0 > r0 ? b0 - r0 : 0;
            uint256 ex1 = b1 > r1 ? b1 - r1 : 0;
            if (ex0 == 0 && ex1 == 0) { skipped++; continue; }
            uint256 a0 = IERC20(t0).balanceOf(ATTACKER);
            uint256 a1 = IERC20(t1).balanceOf(ATTACKER);
            bool okCall = true;
            vm.prank(ATTACKER);
            try p.skim(ATTACKER) {} catch { okCall = false; }
            uint256 g0 = IERC20(t0).balanceOf(ATTACKER) - a0;
            uint256 g1 = IERC20(t1).balanceOf(ATTACKER) - a1;
            if (okCall) calls++; else failed++;
            if (calls + failed > 1) json = string.concat(json, ",");
            json = string.concat(json, "{\"pool\":\"", vm.toString(pools[i]),
                "\",\"ok\":", okCall ? "true" : "false",
                ",\"excess0\":", vm.toString(ex0), ",\"excess1\":", vm.toString(ex1),
                ",\"gain0\":", vm.toString(g0), ",\"gain1\":", vm.toString(g1),
                ",\"token0\":\"", vm.toString(t0), "\",\"token1\":\"", vm.toString(t1), "\"}");
            emit log_named_address("skim pool", pools[i]);
            emit log_named_uint("  gain0", g0);
            emit log_named_uint("  gain1", g1);
        }
        uint256 gasUsed = gasStart - gasleft();
        json = string.concat(json, "],\"skimmed_pools\":", vm.toString(calls),
            ",\"failed_pools\":", vm.toString(failed),
            ",\"pools_without_excess\":", vm.toString(skipped),
            ",\"gas_used\":", vm.toString(gasUsed), "}");
        vm.writeFile("../ci-out/skim_results.json", json);
        emit log_named_uint("fork block", forkBlock);
        emit log_named_uint("pools with excess (skimmed)", calls);
        emit log_named_uint("skim failures", failed);
        emit log_named_uint("pools without excess", skipped);
        emit log_named_uint("gas used total", gasUsed);
        emit log_string(json);
    }

    /// @notice Privileged gates must reject an unprivileged attacker.
    function test_adminGates() public {
        // factory setters
        vm.startPrank(ATTACKER);
        vm.expectRevert();
        IUniV2Factory(FACTORY).setFeeTo(ATTACKER);
        vm.expectRevert();
        IUniV2Factory(FACTORY).setFeeToSetter(ATTACKER);
        // PALA mint
        vm.expectRevert();
        IPalaToken(PALA).mint(1e18);
        vm.expectRevert();
        IPalaToken(PALA).mint(ATTACKER, 1e18);
        vm.expectRevert();
        IPalaToken(ATTEN).mint(ATTACKER, 1e18);
        // farm privileged / migrate
        vm.expectRevert();
        IMasterChef(PALA_FARM).migrate(0);
        vm.expectRevert();
        IMasterChef(PALA_FARM).dev(ATTACKER);
        vm.stopPrank();
        emit log_string("all privileged gates revert for attacker: OK");
    }

    /// @notice Farms: verify attacker cannot harvest/withdraw without stake, and farm
    ///         PALA balance equals staked principal (no loose rewards).
    function test_farmsNoFreeMoney() public {
        IMasterChef f = IMasterChef(PALA_FARM);
        uint256 pl = f.poolLength();
        emit log_named_uint("pala farm poolLength", pl);
        uint256 palaBal = IERC20(PALA).balanceOf(PALA_FARM);
        emit log_named_uint("pala farm PALA balance", palaBal);
        (address lp0, uint256 total0,,,) = f.poolInfo(0);
        emit log_named_address("farm pool0 lpToken", lp0);
        emit log_named_uint("farm pool0 totalLP", total0);
        assertEq(lp0, PALA, "pool0 is single-stake PALA");
        assertEq(palaBal, total0, "farm PALA balance == staked principal (no loose rewards)");
        // attacker pending reward must be 0
        uint256 pending = f.pendingReward(0, ATTACKER);
        assertEq(pending, 0, "attacker pending reward 0");
        // withdraw with no stake must revert
        vm.startPrank(ATTACKER);
        vm.expectRevert();
        f.withdraw(0, 1);
        // emergencyWithdraw may not revert; assert it pays nothing
        uint256 lpBefore = IERC20(lp0).balanceOf(ATTACKER);
        uint256 palaBefore = IERC20(PALA).balanceOf(ATTACKER);
        try f.emergencyWithdraw(0) {} catch {}
        assertEq(IERC20(lp0).balanceOf(ATTACKER), lpBefore, "no LP gain");
        assertEq(IERC20(PALA).balanceOf(ATTACKER), palaBefore, "no PALA gain");
        vm.stopPrank();
        // ATTEN farm: same checks
        IMasterChef af = IMasterChef(ATTEN_FARM);
        uint256 pendingA = af.pendingReward(0, ATTACKER);
        assertEq(pendingA, 0, "attacker pending atten 0");
        vm.startPrank(ATTACKER);
        uint256 aLpBefore = IERC20(PALA).balanceOf(ATTACKER);
        try af.emergencyWithdraw(0) {} catch {}
        assertEq(IERC20(PALA).balanceOf(ATTACKER), aLpBefore, "no atten-farm gain");
        vm.stopPrank();
        // migrator unset on both farms
        assertEq(f.migrator(), address(0), "pala farm migrator unset");
        assertEq(af.migrator(), address(0), "atten farm migrator unset");
        emit log_string("farms: no permissionless payout path for attacker: OK");
    }

    /// @notice pKLAY wrapper: backing == supply (1:1 KLAY), no extraction.
    function test_pklayBacking() public {
        uint256 nativeBal = PKLAY.balance;
        uint256 supply = IERC20(PKLAY).totalSupply();
        emit log_named_uint("pKLAY native balance", nativeBal);
        emit log_named_uint("pKLAY totalSupply", supply);
        assertGe(nativeBal, supply, "pKLAY fully backed 1:1");
    }

    /// @notice Viewer oracle lens: tokenPrice is denominated in oUSDT units; log key values.
    function test_viewerOracleLens() public {
        IPalaViewer v = IPalaViewer(VIEWER);
        address kusdt = v.kusdt();
        emit log_named_address("viewer.kusdt (base)", kusdt);
        address[6] memory toks = [
            0x2ff5f6dE2287CA3075232127277E53519A77947C, // WKLAY
            0xceE8FAF64bB97a73bb51E115Aa89C17FfA8dD167, // oUSDT
            0x754288077D0fF82AF7a5317C7CB8c444D421d103, // oUSDC
            0x7A1CdCA99FE5995ab8E317eDE8495c07Cbf488aD, // PALA
            0x1F2D6282D74EF26eB6c7e28b9e7048c1B42EbDa5, // pKLAY
            0x34d21b1e550D73cee41151c77F3c73359527a396  // oETH
        ];
        for (uint256 i = 0; i < toks.length; i++) {
            emit log_named_uint(string.concat("tokenPrice ", vm.toString(toks[i])), v.tokenPrice(toks[i]));
        }
        // viewer holds no tokens of value (lens only): report a few balances
        emit log_named_uint("viewer oUSDT bal", IERC20(kusdt).balanceOf(VIEWER));
        emit log_named_uint("viewer native bal", VIEWER.balance);
    }

    /// @notice Emission-function gate tests on the PALA farm (permissionless-looking calls).
    function test_farmEmissionFunctions() public {
        IMasterChef f = IMasterChef(PALA_FARM);
        uint256 rpbBefore = f.rewardPerBlock();
        emit log_named_uint("rewardPerBlock before", rpbBefore);
        // initRewardPerBlock() (0x60709b18)
        vm.prank(ATTACKER);
        (bool ok1,) = PALA_FARM.call(abi.encodeWithSelector(0x60709b18));
        emit log_named_uint("initRewardPerBlock ok", ok1 ? 1 : 0);
        emit log_named_uint("rewardPerBlock after init", f.rewardPerBlock());
        // updateRewardPerBlock() (0xdf27123a)
        vm.prank(ATTACKER);
        (bool ok2,) = PALA_FARM.call(abi.encodeWithSelector(0xdf27123a));
        emit log_named_uint("updateRewardPerBlock ok", ok2 ? 1 : 0);
        emit log_named_uint("rewardPerBlock after update", f.rewardPerBlock());
        // updateMultiplier(2) (0x5ffe6146)
        vm.prank(ATTACKER);
        (bool ok3,) = PALA_FARM.call(abi.encodeWithSelector(0x5ffe6146, uint256(2)));
        emit log_named_uint("updateMultiplier ok", ok3 ? 1 : 0);
        emit log_named_uint("BONUS_MULTIPLIER after", f.BONUS_MULTIPLIER());
        // massUpdatePools() (0x630b5ba1) — permissionless but pays caller nothing
        uint256 attBefore = IERC20(PALA).balanceOf(ATTACKER);
        vm.prank(ATTACKER);
        (bool ok4,) = PALA_FARM.call(abi.encodeWithSelector(0x630b5ba1));
        emit log_named_uint("massUpdatePools ok", ok4 ? 1 : 0);
        assertEq(IERC20(PALA).balanceOf(ATTACKER), attBefore, "massUpdatePools pays caller nothing");
    }

    /// @notice Pool-15 LP acquisition gate: REWARD/BURN tokens are owner-mintable only.
    function test_farmLpAcquisitionGate() public {
        address reward = 0x6D52751Bf79588D2Fa2A87C3b4a97C29f84A4d49;
        address burn = 0xFE9138Db20524458f6d40Df90EBfbfd1661cFDdf;
        assertEq(IERC20(reward).totalSupply(), 1e18, "REWARD supply");
        assertEq(IERC20(burn).totalSupply(), 1e18, "BURN supply");
        // attacker cannot mint the LP-acquisition tokens
        vm.startPrank(ATTACKER);
        vm.expectRevert();
        IPalaToken(reward).mint(ATTACKER, 1e18);
        vm.expectRevert();
        IPalaToken(burn).mint(ATTACKER, 1e18);
        vm.stopPrank();
        // tokens only exist inside the one dead pair; farm holds the LP
        IUniV2Pair lp = IUniV2Pair(0xf7469c09a68AB6D52bDb4dF1d95D7755C80A74C5);
        emit log_named_uint("pair REWARD reserve", IERC20(reward).balanceOf(address(lp)));
        emit log_named_uint("pair BURN reserve", IERC20(burn).balanceOf(address(lp)));
        emit log_named_uint("LP totalSupply", lp.totalSupply());
        emit log_named_uint("LP held by PALA farm", lp.balanceOf(PALA_FARM));
    }
}
