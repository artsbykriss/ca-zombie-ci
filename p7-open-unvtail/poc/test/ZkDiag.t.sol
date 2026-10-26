// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Test, console2} from "forge-std/Test.sol";

contract ZkDiag is Test {
    function _bal(address token, address who) internal view returns (uint256) {
        (bool ok, bytes memory r) = token.staticcall(abi.encodeWithSelector(0x70a08231, who));
        if (!ok || r.length < 32) return 0;
        return abi.decode(r, (uint256));
    }
    function _try(string memory url) internal {
        console2.log("--- fork", url);
        vm.createSelectFork(url);
        address p = 0x7d5b0215EF203D0660BC37d5D09d964fd6b55a1E;
        address t = 0x1d17CBcF0D6D143135aE902365D2E5e2A16538D4;
        console2.log("block", block.number);
        console2.log("proxy code len", p.code.length);
        console2.log("token code len", t.code.length);
        console2.log("bal", _bal(t, p));
        console2.log("native", p.balance);
    }
    function test_diag() public {
        _try("https://mainnet.era.zksync.io");
    }
}
