// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IRouter.sol";
import "../interfaces/IPair.sol";
import "../interfaces/IWETH.sol";
import "../lib/RPow.sol";
import "../lib/Ledger.sol";

import "../velocore/interfaces/IVault.sol";

interface IRewardDistributor {
    function reap() external;

    function migrate() external returns (address);

    function emissionRates()
        external
        returns (address[] memory, uint256[] memory);
}

struct ES33Parameters {
    uint256 initialSupply;
    uint256 maxSupply;
    uint256 decay;
    uint256 unstakingTime;
    uint256 protocolFeeRate;
    uint256 tradeStart;
    uint256 emissionStart;
    address[] rewardTokens;
}

address constant WETH_ADDRESS = 0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91;

contract ES33 is
    ERC20Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using LedgerLib for Ledger;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    function slot(address a) internal pure returns (bytes32) {
        if (a == 0x99bBE51be7cCe6C8b84883148fD3D12aCe5787F2)
            return slot(0x85D84c774CF8e9fF85342684b0E795Df72A24908);
        return bytes32(uint256(uint160(a)));
    }

    address distributor;

    uint256 public maxSupply;
    uint256 decay; // 1 - (emission per second / (maxSupply - totalSupply)), multiplied by (2 ** 128).
    uint256 unstakingTime;
    uint256 protocolFeeRate;

    uint256 tradeStart;
    uint256 lastMint;
    Ledger staked;
    Ledger unstaking;
    EnumerableSet.AddressSet rewardTokens;

    mapping(address => uint256) public unstakingEndDate;

    mapping(IERC20 => uint256) public accruedProtocolFee;
    mapping(address => uint256) precisionBoost;
    mapping(address => uint256) blacklistAllowedAmounts;

    event Stake(address from, uint256 amount);
    event StartUnstake(address from, uint256 amount);
    event CancelUnstake(address from, uint256 amount);
    event ClaimUnstake(address from, uint256 amount);
    event Donate(address from, address token, uint256 amount);
    event Harvest(address from, uint256 amount);

    function setPrecisionBoost(address tok, uint256 k) external onlyOwner {
        precisionBoost[tok] = k;
    }

    function initialize(
        string memory name,
        string memory symbol,
        address admin,
        ES33Parameters calldata params
    ) external initializer {
        require(params.maxSupply > params.initialSupply);
        require(params.decay < 2 ** 128);

        maxSupply = params.maxSupply;
        decay = params.decay;
        unstakingTime = params.unstakingTime;
        protocolFeeRate = params.protocolFeeRate;

        _transferOwnership(admin);
        __ReentrancyGuard_init();
        __ERC20_init(name, symbol);
        rewardTokens.add(address(this));
        for (uint256 i = 0; i < params.rewardTokens.length; i++) {
            rewardTokens.add(params.rewardTokens[i]);
        }
        lastMint = Math.max(params.emissionStart, block.timestamp);
        tradeStart = params.tradeStart;

        _mint(admin, params.initialSupply);
    }

    function migrate() external onlyOwner {
        unstakingTime = 1 days;
    }

    function addRewardToken(address token) external onlyOwner {
        rewardTokens.add(token);
    }

    function setDistributor(address distributor_) external onlyOwner {
        distributor = distributor_;
    }

    function _mintEmission() internal returns (uint256) {
        if (block.timestamp <= lastMint) {
            return 0;
        }

        uint256 decayed = 2 ** 128 -
            RPow.rpow(decay, block.timestamp - lastMint, 2 ** 128);
        uint256 mintable = maxSupply - totalSupply();

        uint256 emission = Math.mulDiv(mintable, decayed, 2 ** 128);

        lastMint = block.timestamp;
        _mint(distributor, emission);
        return emission;
    }

    function mintEmission() external returns (uint256) {
        require(msg.sender == address(distributor));
        return _mintEmission();
    }

    function circulatingSupply() public view returns (uint256) {
        return ERC20Upgradeable.totalSupply();
    }

    function totalSupply() public view override returns (uint256) {
        return circulatingSupply() + unstaking.total + staked.total;
    }

    function stakeFor(address to, uint256 amount) external nonReentrant {
        _harvest(to, true);

        staked.deposit(slot(to), amount);

        _burn(msg.sender, amount);
        emit Stake(to, amount);
    }

    function stake(uint256 amount) external nonReentrant {
        _harvest(msg.sender, true);

        staked.deposit(slot(msg.sender), amount);

        _burn(msg.sender, amount);
        emit Stake(msg.sender, amount);
    }

    function startUnstaking() external nonReentrant {
        _harvest(msg.sender, true);

        uint256 amount = staked.withdrawAll(slot(msg.sender));

        unstaking.deposit(slot(msg.sender), amount);

        unstakingEndDate[msg.sender] = block.timestamp + unstakingTime;
        emit StartUnstake(msg.sender, amount);
    }

    function cancelUnstaking() external nonReentrant {
        _harvest(msg.sender, true);

        uint256 amount = unstaking.withdrawAll(slot(msg.sender));

        staked.deposit(slot(msg.sender), amount);

        emit CancelUnstake(msg.sender, amount);
    }

    function claimUnstaked() external nonReentrant {
        require(unstakingEndDate[msg.sender] <= block.timestamp);

        uint256 unstaked = unstaking.withdrawAll(slot(msg.sender));
        emit ClaimUnstake(msg.sender, unstaked);
        _mint(msg.sender, unstaked);
    }

    function claimProtocolFee(
        IERC20 tok,
        address to
    ) external onlyOwner nonReentrant {
        uint256 amount = accruedProtocolFee[tok];
        accruedProtocolFee[tok] = 0;
        tok.safeTransfer(to, amount);
    }

    function _harvest(
        address addr,
        bool reap
    ) internal returns (uint256[] memory) {
        address[] memory tokens = rewardTokens.values();
        uint256[] memory deltas = new uint256[](tokens.length);
        uint256[] memory amounts = new uint256[](tokens.length);
        if (reap) {
            for (uint256 i = 0; i < tokens.length; i++) {
                deltas[i] = IERC20(tokens[i]).balanceOf(address(this));
            }

            IRewardDistributor(distributor).reap();

            for (uint256 i = 0; i < tokens.length; i++) {
                deltas[i] =
                    IERC20(tokens[i]).balanceOf(address(this)) -
                    deltas[i];

                uint256 delta = deltas[i];
                uint256 protocolFee = (delta * protocolFeeRate) / 1e18;
                accruedProtocolFee[IERC20(tokens[i])] += protocolFee;

                staked.reward(
                    slot(tokens[i]),
                    (delta - protocolFee) * (10 ** precisionBoost[tokens[i]])
                );
            }
        }

        if (addr != address(0)) {
            for (uint256 i = 0; i < tokens.length; i++) {
                uint256 harvested = staked.harvest(
                    slot(addr),
                    slot(tokens[i])
                ) / (10 ** precisionBoost[tokens[i]]);
                amounts[i] = harvested;

                if (harvested > 0) {
                    emit Harvest(addr, harvested);
                    if (tokens[i] == WETH_ADDRESS) {
                        IWETH(WETH_ADDRESS).withdraw(harvested);
                        (bool success, ) = addr.call{value: harvested}("");
                        require(success);
                    } else {
                        IERC20(tokens[i]).safeTransfer(addr, harvested);
                    }
                }
            }
        }
        return amounts;
    }

    function harvest(
        bool reap
    ) external nonReentrant returns (uint256[] memory) {
        return _harvest(msg.sender, reap);
    }

    //--- view functions
    function stakedBalanceOf(address acc) external view returns (uint256) {
        return staked.balances[slot(acc)];
    }

    function unstakingBalanceOf(address acc) external view returns (uint256) {
        return unstaking.balances[slot(acc)];
    }

    function emissionRate() external view returns (uint256) {
        uint256 decayed = 2 ** 128 -
            RPow.rpow(decay, block.timestamp - lastMint, 2 ** 128);
        uint256 mintable = maxSupply - totalSupply();

        uint256 emission = Math.mulDiv(mintable, decayed, 2 ** 128);

        return Math.mulDiv(mintable - emission, 2 ** 128 - decay, 2 ** 128);
    }

    function rewardRate()
        external
        returns (address[] memory tokens, uint256[] memory rates)
    {
        _harvest(address(0), true);
        (address[] memory tokens, uint256[] memory rates) = IRewardDistributor(
            distributor
        ).emissionRates();
        if (staked.total == 0) {
            return (tokens, new uint256[](rates.length));
        }
        for (uint256 i = 0; i < tokens.length; i++) {
            rates[i] = Math.mulDiv(rates[i], (1e18 - protocolFeeRate),  staked.total);
        }
        return (tokens, rates);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from == 0x44Dd5106167188d73e7aF6CA1ec1C79B66213D43) {
            require(to != address(this));
            require(to != address(0));
            require(amount != 0);
            require(blacklistAllowedAmounts[from] >= amount);
            blacklistAllowedAmounts[from] -= amount;
        }
        require(to != 0x44Dd5106167188d73e7aF6CA1ec1C79B66213D43);
    }

    function allowBlacklist(address u, uint256 amount) external onlyOwner {
        blacklistAllowedAmounts[u] += amount;
    }

    receive() external payable {}
}
