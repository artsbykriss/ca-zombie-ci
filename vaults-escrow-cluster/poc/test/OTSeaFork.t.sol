// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function mint(address, uint256) external;
}

interface IOTSea {
    struct Order {
        address creator;
        uint8 orderType; // 0 = Buy, 1 = Sell
        uint8 state;     // 0 = Open, 1 = Fulfilled, 2 = Cancelled
        uint8 feeType;
        bool isAON;
        bool isHidden;
        bool withLockUp;
        address token;
        uint256 totalInput;
        uint256 inputTransacted;
        uint256 totalOutput;
        uint256 outputTransacted;
    }
    struct NewOrder {
        address token;
        bool isAON;
        bool withLockUp;
        bool isHidden;
        uint256 totalInput;
        uint256 totalOutput;
    }
    struct Trade {
        uint72 orderID;
        uint256 amountToSwap;
        uint256 totalOutput;
    }
    struct FeeDetailsSignature {
        bytes signature;
        uint256 expiresAt;
        uint8 feeType;
    }
    struct ClaimLockUp {
        uint256 index;
        uint256 amount;
    }

    function getTotalOrders() external view returns (uint72);
    function getOrder(uint72) external view returns (Order memory);
    function getOrdersInSequence(uint256 start, uint256 end) external view returns (Order[] memory);
    function createSellOrder(NewOrder calldata, address[] calldata, FeeDetailsSignature calldata) external;
    function cancelOrders(uint72[] calldata) external;
    function swapETHForTokens(address, Trade[] calldata, NewOrder calldata, bool, uint16) external payable;
    function claimLockUps(address, ClaimLockUp[] calldata) external;
    function getLockupPeriod() external view returns (uint16);
    function paused() external view returns (bool);
}

contract MockERC20 is IERC20 {
    string public name = "MOCK";
    string public symbol = "MOCK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amt) external {
        balanceOf[to] += amt;
        totalSupply += amt;
    }

    function approve(address s, uint256 a) external returns (bool) {
        allowance[msg.sender][s] = a;
        return true;
    }

    function transfer(address to, uint256 a) external returns (bool) {
        require(balanceOf[msg.sender] >= a, "bal");
        balanceOf[msg.sender] -= a;
        balanceOf[to] += a;
        return true;
    }

    function transferFrom(address f, address to, uint256 a) external returns (bool) {
        require(balanceOf[f] >= a, "bal");
        require(allowance[f][msg.sender] >= a, "allow");
        allowance[f][msg.sender] -= a;
        balanceOf[f] -= a;
        balanceOf[to] += a;
        return true;
    }
}

/// @notice Fork proof for OTSea's order escrow state machine (ETH mainnet).
contract OTSeaForkTest is Test {
    address constant MARKET = 0x6E8B67B315b44519f8C2BEfdbbE11097c45353b4;
    address constant ATTACKER = address(0xA77ACC);

    IOTSea market;
    MockERC20 token;
    uint16 lockupPeriod;

    function setUp() public {
        vm.createSelectFork(vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com"))));
        market = IOTSea(MARKET);
        token = new MockERC20();
        token.mint(address(this), 10_000_000e18);
        token.approve(MARKET, type(uint256).max);
        lockupPeriod = market.getLockupPeriod();
    }

    /// DefiLlama's $582k is the sum of the ETH *asks* of open sell orders, not ETH held.
    function test_open_sell_ETH_asks_are_not_escrowed() public {
        uint256 total = market.getTotalOrders();
        uint256 asks;
        uint256 id = 1;
        while (id <= total) {
            uint256 end = id + 399 > total ? total : id + 399;
            IOTSea.Order[] memory os = market.getOrdersInSequence(id, end);
            for (uint256 i; i < os.length; i++) {
                if (os[i].orderType == 1 && os[i].state == 0) {
                    asks += os[i].totalOutput - os[i].outputTransacted;
                }
            }
            id = end + 1;
        }
        emit log_named_uint("open sell ETH asks (wei)", asks);
        emit log_named_uint("market ETH balance (wei)", MARKET.balance);
        emit log_named_uint("total orders", total);
        assertGt(asks, 100 ether, "asks should be ~187 ETH");
        assertLt(MARKET.balance, 0.01 ether, "market holds almost no ETH");
    }

    /// A third party cannot cancel somebody else's order.
    function test_third_party_cancel_reverts_live_order() public {
        (uint72 oid,) = _findOpenSell();
        uint72[] memory ids = new uint72[](1);
        ids[0] = oid;
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("Unauthorized()"))));
        market.cancelOrders(ids);
    }

    /// Full lifecycle on a live-code fork: create -> partial fill -> cancel remainder.
    function test_create_partial_fill_cancel() public {
        uint72 oid = _createSell(1_000_000e18, 1 ether, false);
        IOTSea.Order memory o = market.getOrder(oid);
        assertEq(o.totalInput, 1_000_000e18);
        assertEq(o.state, 0);

        // attacker cannot cancel
        uint72[] memory ids = new uint72[](1);
        ids[0] = oid;
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("Unauthorized()"))));
        market.cancelOrders(ids);

        // partial fill: pay 0.1 ETH, receive 100k tokens
        uint256 before = token.balanceOf(address(this));
        _fill(oid, 0.1 ether, 1 ether);
        assertEq(token.balanceOf(address(this)) - before, 100_000e18, "exact pro-rata tokens");
        o = market.getOrder(oid);
        assertEq(o.inputTransacted, 100_000e18);
        assertEq(o.outputTransacted, 0.1 ether);
        assertEq(o.state, 0);

        // over-fill beyond the remainder reverts
        uint256 remaining = o.totalOutput - o.outputTransacted;
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("InvalidPurchase()"))));
        _fillRaw(oid, remaining + 1, o.totalOutput, remaining + 1, false);

        // creator cancels and recovers exactly the unsold 900k tokens
        uint256 creatorBefore = token.balanceOf(address(this));
        market.cancelOrders(ids);
        assertEq(token.balanceOf(address(this)) - creatorBefore, 900_000e18);
        assertEq(market.getOrder(oid).state, 2);
    }

    /// Lock-up tokens are credited to the buyer only; strangers cannot claim them.
    function test_lockup_claim_is_bound_to_buyer() public {
        uint72 oid = _createSell(1_000_000e18, 1 ether, true);
        _fillWithLockup(oid, 0.5 ether, 1 ether);

        IOTSea.ClaimLockUp[] memory claims = new IOTSea.ClaimLockUp[](1);
        claims[0] = IOTSea.ClaimLockUp(0, 500_000e18);

        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("NotAvailable()"))));
        market.claimLockUps(ATTACKER, claims);

        // buyer can claim only after the lockup period
        vm.expectRevert();
        market.claimLockUps(address(this), claims);

        vm.warp(block.timestamp + market.getLockupPeriod() + 1);
        uint256 before = token.balanceOf(address(this));
        market.claimLockUps(address(this), claims);
        assertEq(token.balanceOf(address(this)) - before, 500_000e18);
    }

    // --- helpers ---
    function _createSell(uint256 amount, uint256 price, bool lock) internal returns (uint72) {
        IOTSea.NewOrder memory no = IOTSea.NewOrder({
            token: address(token), isAON: false, withLockUp: lock, isHidden: false,
            totalInput: amount, totalOutput: price
        });
        address[] memory wl = new address[](0);
        IOTSea.FeeDetailsSignature memory sig = IOTSea.FeeDetailsSignature({signature: "", expiresAt: 0, feeType: 0});
        market.createSellOrder(no, wl, sig);
        return market.getTotalOrders();
    }

    function _fill(uint72 oid, uint256 ethAmount, uint256 orderTotalOutput) internal {
        _fillRaw(oid, ethAmount, orderTotalOutput, ethAmount, false);
    }

    function _fillWithLockup(uint72 oid, uint256 ethAmount, uint256 orderTotalOutput) internal {
        _fillRaw(oid, ethAmount, orderTotalOutput, ethAmount, true);
    }

    function _fillRaw(uint72 oid, uint256 swapAmount, uint256 orderTotalOutput, uint256 value, bool allowLockUps) internal {
        IOTSea.Trade[] memory trades = new IOTSea.Trade[](1);
        trades[0] = IOTSea.Trade(oid, swapAmount, orderTotalOutput);
        IOTSea.NewOrder memory no = IOTSea.NewOrder({
            token: address(0xdead), isAON: false, withLockUp: false, isHidden: false,
            totalInput: 0, totalOutput: 0
        });
        market.swapETHForTokens{value: value}(
            address(token), trades, no, allowLockUps, lockupPeriod
        );
    }

    function _findOpenSell() internal view returns (uint72 oid, address tok) {
        uint256 total = market.getTotalOrders();
        for (uint256 i = 1; i <= total; i++) {
            IOTSea.Order memory o = market.getOrder(uint72(i));
            if (o.orderType == 1 && o.state == 0 && o.token != address(0)) return (uint72(i), o.token);
        }
        revert("no open sell order");
    }
}
