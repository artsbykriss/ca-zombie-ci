// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/GeistInterfaces.sol";

/// @title Can an existing staker still claim aToken rewards? (vs a fresh staker)
contract GeistClaimProbeTest is Test {
    address constant STAKING = 0x49c93a95dbcc9A6A4D8f77E59c038ce5020e82f8;
    address constant A_DAI = 0x07E6332dD090D287d3489245038daF987955DCFB;
    address constant A_CRV = 0x690754A168B022331cAA2467207c61919b3F8A98;
    address constant A_MIM = 0xc664Fc7b8487a3E10824Cda768c1d239F2403bBe;
    address constant A_LINK = 0xBeCF29265B0cc8D33fA24446599955C7bcF7F73B;
    address constant A_WFTM = 0x39B3bd37208CBaDE74D0fcBDBb12D606295b430a;

    function _selectFork() internal returns (uint256) {
        string[6] memory urls = [
            vm.envOr("FANTOM_RPC_URL", string("")),
            "https://rpc2.fantom.network",
            "https://rpc3.fantom.network",
            "https://rpcapi.fantom.network",
            "https://fantom.drpc.org",
            "https://1rpc.io/ftm"
        ];
        for (uint256 i = 0; i < urls.length; i++) {
            if (bytes(urls[i]).length == 0) continue;
            try vm.createSelectFork(urls[i]) returns (uint256) {
                return block.number;
            } catch {}
        }
        revert("no rpc");
    }

    function setUp() public {
        _selectFork();
    }

    function _claim(address who, address token) internal returns (bool ok, uint256 balBefore, uint256 balAfter) {
        address[] memory one = new address[](1);
        one[0] = token;
        balBefore = IERC20(token).balanceOf(who);
        vm.prank(who);
        (ok,) = STAKING.call(abi.encodeWithSignature("getReward()"));
        balAfter = IERC20(token).balanceOf(who);
    }

    function test_existing_staker_claim() public {
        // one of the accounts that successfully claimed at block 123,673,374
        address staker = 0x0fa949783947Bf6c1b171DB13AEACBB488845B3f;
        (bool ok, uint256 b0, uint256 b1) = _claim(staker, A_LINK);
        emit log_named_string("existing staker getReward(aLINK) ok?", ok ? "YES" : "NO");
        emit log_named_uint("  aLINK before", b0);
        emit log_named_uint("  aLINK after", b1);
        (ok, b0, b1) = _claim(staker, A_DAI);
        emit log_named_string("existing staker getReward(aDAI) ok?", ok ? "YES" : "NO");
        emit log_named_uint("  aDAI before", b0);
        emit log_named_uint("  aDAI after", b1);
    }

    function test_fresh_eoa_claim_reverts() public {
        address fresh = makeAddr("fresh");
        (bool ok,,) = _claim(fresh, A_DAI);
        emit log_named_string("fresh EOA getReward(aDAI) ok?", ok ? "YES" : "NO");
    }

    function test_reward_accounting() public {
        // compare userRewardPerTokenPaid vs rewardPerTokenStored for the fresh staker scenario
        address staker = 0x0fa949783947Bf6c1b171DB13AEACBB488845B3f;
        emit log_named_uint("aDAI rewardPerTokenStored", _rpt(A_DAI));
        emit log_named_uint("aDAI staker paid", _paid(staker, A_DAI));
        emit log_named_uint("aDAI staking balance", _totalBalance(staker));
        emit log_named_uint("staking totalSupply", IMultiFeeDistribution(STAKING).totalSupply());
    }

    function _totalBalance(address u) internal view returns (uint256 v) {
        (bool ok, bytes memory d) = STAKING.staticcall(abi.encodeWithSignature("totalBalance(address)", u));
        require(ok, "totalBalance failed");
        v = abi.decode(d, (uint256));
    }

    function _rpt(address t) internal view returns (uint256) {
        (,,, uint256 rpt,) = _rewardData(t);
        return rpt;
    }

    function _paid(address u, address t) internal view returns (uint256 v) {
        (bool ok, bytes memory d) = STAKING.staticcall(abi.encodeWithSignature("userRewardPerTokenPaid(address,address)", u, t));
        require(ok, "call failed");
        v = abi.decode(d, (uint256));
    }

    function _rewardData(address t) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        (bool ok, bytes memory d) = STAKING.staticcall(abi.encodeWithSignature("rewardData(address)", t));
        require(ok, "rewardData failed");
        return abi.decode(d, (uint256, uint256, uint256, uint256, uint256));
    }
}
