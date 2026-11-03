// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPoolManager {
    struct PoolKey {
        address currency0;
        address currency1;
        address hooks;
        uint24 fee;
        bytes32 parameters;
    }
    struct SwapParams {
        bool zeroForOne;
        int256 amountSpecified;
        uint160 sqrtPriceLimitX96;
    }

    function lock(bytes calldata data) external returns (bytes memory);
    function take(address currency, address to, uint256 amount) external;
    function settle() external payable returns (uint256);
    function settleFor(address recipient) external payable returns (uint256);
    function sync(address currency) external;
    function mint(address to, address currency, uint256 amount) external;
    function burn(address from, address currency, uint256 amount) external;
    function clear(address currency, uint256 amount) external;
    function balanceOf(address owner, address currency) external view returns (uint256);
    function transferFrom(address sender, address receiver, address currency, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender, address currency) external view returns (uint256);
    function collectProtocolFees(address recipient, address currency, uint256 amount)
        external
        returns (uint256);
    function setProtocolFeeController(address controller) external;
    function setOperator(address operator, bool approved) external returns (bool);
    function initialize(PoolKey calldata key, uint160 sqrtPriceX96) external returns (int24);
    function swap(PoolKey calldata key, SwapParams calldata params, bytes calldata hookData)
        external
        returns (int256);
    struct ModifyLiquidityParams {
        int24 tickLower;
        int24 tickUpper;
        int256 liquidityDelta;
        bytes32 salt;
    }
    function modifyLiquidity(
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external returns (int256, int256);
    function getUnsettledDeltasCount() external view returns (uint256);
    function owner() external view returns (address);
    function paused() external view returns (bool);
    function poolCount() external view returns (uint256);
    function getSlot0(bytes32 id)
        external
        view
        returns (uint160 sqrtPriceX96, int24 tick, uint24 protocolFee, uint24 lpFee);
}

contract MockERC20 {
    string public name = "Mock";
    string public symbol = "MOCK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "balance");
        require(allowance[from][msg.sender] >= amount, "allowance");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

/// Attacker contract: implements lockAcquired(bytes) so it can be a locker and
/// exercise every payer-accounting path from inside its own lock.
contract Attacker {
    IPoolManager public pm;
    MockERC20 public token;
    address public victim;
    uint8 public action;
    bool public reentered;

    constructor(IPoolManager _pm, MockERC20 _token, address _victim) {
        pm = _pm;
        token = _token;
        victim = _victim;
    }

    function setAction(uint8 a) external {
        action = a;
    }

    function attack() external returns (bytes memory) {
        return pm.lock("");
    }

    function stealClaim() external returns (bool) {
        return pm.transferFrom(victim, address(this), address(token), 10);
    }

    function lockAcquired(bytes calldata) external returns (bytes memory) {
        // 1: take without paying
        if (action == 1) {
            pm.take(address(token), address(this), 100e18);
        }
        // 2: correct pay-then-take flow
        else if (action == 2) {
            pm.sync(address(token));
            token.transfer(address(pm), 100e18);
            pm.settle();
            pm.take(address(token), address(this), 100e18);
        }
        // 3: mint claims without paying the manager
        else if (action == 3) {
            pm.mint(address(this), address(token), 100e18);
        }
        // 4: burn a victim's claim without allowance
        else if (action == 4) {
            pm.burn(victim, address(token), 1);
        }
        // 5: take native without paying
        else if (action == 5) {
            pm.take(address(0), address(this), 1 ether);
        }
        // 6: nested lock
        else if (action == 6) {
            reentered = true;
            pm.lock("");
        }
        // 7: mint claims to victim, fully paid by this contract
        else if (action == 7) {
            pm.sync(address(token));
            token.transfer(address(pm), 10);
            pm.settle();
            pm.mint(victim, address(token), 10);
        }
        // 8: try to clear a negative delta (must fail)
        else if (action == 8) {
            pm.take(address(token), address(this), 100e18);
            pm.clear(address(token), 100e18);
        }
        return "";
    }

    receive() external payable {}
}

/// Minimal v4-style hook: declares a registration bitmap and records who called
/// its fallback. Used to prove hook callbacks come from the PoolManager itself.
contract MockHook {
    uint16 public bitmap;
    address public lastCaller;
    bytes4 public lastSelector;
    uint256 public calls;

    constructor(uint16 b) {
        bitmap = b;
    }

    function getHooksRegistrationBitmap() external view returns (uint16) {
        return bitmap;
    }

    fallback() external payable {
        lastCaller = msg.sender;
        lastSelector = msg.sig;
        calls += 1;
        assembly {
            mstore(0, 1)
            return(0, 32)
        }
    }
}
