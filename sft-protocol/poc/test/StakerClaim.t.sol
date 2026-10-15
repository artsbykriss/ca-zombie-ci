// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";

/// Can any existing staker still claim FIL from the reward pool (H-O liveness)?
contract StakerClaimTest is Test {
    address constant REWARD = 0xE86D3dBd8233F1BFA22679cB57FaB3428E9654f7;

    function setUp() public {
        vm.createSelectFork(vm.envOr("FIL_RPC_URL", string("https://filecoin.drpc.org")), 6_457_969);
    }

    function claimFor(address who, uint256 idx) internal {
        uint256[] memory a = new uint256[](1);
        uint256[] memory b = new uint256[](1);
        uint256[] memory c = new uint256[](1);
        a[0] = 4; b[0] = idx; c[0] = 1e13;
        uint256 before = who.balance;
        vm.prank(who);
        (bool ok, ) = REWARD.call(abi.encodeWithSelector(bytes4(0xb74b08ab), a, b, c));
        emit log_named_string(
            string.concat("staker ", vm.toString(who), " idx ", vm.toString(idx), " ok"),
            ok ? "yes" : "no"
        );
        emit log_named_int("  FIL delta", int(who.balance) - int(before));
    }

    function test_claims() public {
        address[8] memory stakers = [
            0xDE6A9fbfD752DbbA8d90E735D7960CEA4290afFB,
            0xd9f1eB19C096b0e826e892265616eb3Bd95f6037,
            0x9B6Fa2A3373422C1c6EebE9329069e357B196061,
            0x449710aadf0a1d8275445436e40451411613eB22,
            0x0698Fa3B48313c5160619bDB970dEB98e558Ea75,
            0xA50D269835De99b430825375Bcc90b4269C0D77f,
            0x8F64E277Bcb6B9d49cc1CaDdf3ebb189aE844eB1,
            0xc0F5c68dDCA769d4ABEAEe1406Fa49Fb671d1D4C
        ];
        for (uint i = 0; i < stakers.length; i++) {
            claimFor(stakers[i], 0);
            claimFor(stakers[i], 1);
        }
    }
}
