// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.10;

import "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "../lzapp/OFTCoreUpgradeable.sol";
import "../interfaces/IRouter.sol";
import "../interfaces/IPair.sol";
import "../interfaces/IWETH.sol";
import "../lib/RPow.sol";
import "../lib/Ledger.sol";
import "lzapp/token/oft/v1/interfaces/IOFT.sol";

import "../IVault.sol";

interface IRewardDistributor {
    function reap() external;

    function migrate() external returns (address);

    function emissionRates() external returns (address[] memory, uint256[] memory);
}

struct ES33Parameters {
    uint256 initialSupply;
    uint256 maxSupply;
    uint256 decay;
    uint256 unstakingTime;
    uint256 emissionStart;
}

contract ES33 is
    ERC20Upgradeable,
    ReentrancyGuardUpgradeable,
    OFTCore,
    ERC1967Upgrade
{
    using LedgerLib for Ledger;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    constructor(address vault_, address lz) OFTCore(lz) {
        vault = vault_;
    }

    function slot(address a) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(a)));
    }

    function upgradeTo(address newImplementation) external onlyOwner {
        ERC1967Upgrade._upgradeTo(newImplementation);
    }

    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) external onlyOwner {
        ERC1967Upgrade._upgradeToAndCall(newImplementation, data, true);
    }

    address distributor;
    address immutable vault;

    uint256 public maxSupply;
    uint256 decay; // 1 - (emission per second / (maxSupply - totalEmission)), multiplied by (2 ** 128).
    uint256 unstakingTime;
    uint256 lastMint;
    uint256 totalEmission;
    mapping(address => uint256) protocolFeeRate;
    Ledger staked;
    Ledger unstaking;
    EnumerableSet.AddressSet rewardTokens;

    mapping(address => uint256) public unstakingEndDate;

    mapping(IERC20 => uint256) public accruedProtocolFee;

    event Stake(address from, uint256 amount);
    event StartUnstake(address from, uint256 amount);
    event CancelUnstake(address from, uint256 amount);
    event ClaimUnstake(address from, uint256 amount);
    event Donate(address from, address token, uint256 amount);
    event Harvest(address from, uint256 amount);

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IOFT).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function token() public view virtual override returns (address) {
        return address(this);
    }

    function circulatingSupply() public view virtual override returns (uint) {
        return totalSupply();
    }

    function _debitFrom(
        address _from,
        uint16,
        bytes memory,
        uint _amount
    ) internal virtual override returns (uint) {
        address spender = _msgSender();
        if (_from != spender) _spendAllowance(_from, spender, _amount);
        _burn(_from, _amount);
        return _amount;
    }

    function _creditTo(
        uint16,
        address _toAddress,
        uint _amount
    ) internal virtual override returns (uint) {
        _mint(_toAddress, _amount);
        return _amount;
    }

    uint256 initialLiquidity;
    function initialize(
        string memory name,
        string memory symbol,
        address admin,
        address vault,
        address factory,
        address vc,
        ES33Parameters calldata params
    ) external payable initializer {
        require(params.decay < 2 ** 128);

        maxSupply = params.maxSupply;
        decay = params.decay;
        unstakingTime = params.unstakingTime;
	initialLiquidity = params.initialSupply;

        _transferOwnership(admin);
        __ReentrancyGuard_init();
        __ERC20_init(name, symbol);
        lastMint = Math.max(params.emissionStart, block.timestamp);
        address pool = ConstantProductPoolFactory(factory).deploy(
            bytes32(uint256(uint160(address(this)))),
            0xEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
        );
    }

    function stakeLiquidity(address vault, address factory, address vc) external onlyOwner payable {
address pool = ConstantProductPoolFactory(factory).pools(
            bytes32(uint256(uint160(address(this)))),
            0xEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
);
        _mint(address(this), initialLiquidity);
        this.approve(vault, type(uint256).max);
        IVault(vault).execute3{value: msg.value}(
            pool,
            0,
            address(this),
            0,
            int128(uint128(initialLiquidity)),
            address(0),
            0,
            int128(uint128(msg.value)),
            pool,
            1,
            0,
            ""
        );
        IVault(vault).execute2(
            pool,
            1,
            pool,
            0,
            int128(uint128(IERC20(pool).balanceOf(address(this)))),
            vc,
            0,
            0,
            ""
        );
	initialLiquidity = 0;
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
        if (totalEmission >= maxSupply) return 0;

        uint256 decayed = 2 ** 128 -
            RPow.rpow(decay, block.timestamp - lastMint, 2 ** 128);
        uint256 mintable = maxSupply - totalEmission;

        uint256 emission = Math.mulDiv(mintable, decayed, 2 ** 128);

        lastMint = block.timestamp;
        totalEmission += emission;
        _mint(distributor, emission);
        return emission;
    }

    function mintEmission() external returns (uint256) {
        require(msg.sender == address(distributor));
        return _mintEmission();
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
            (bool success, ) = address(vault).call(
                hex"d3115a8a0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000001e000000000000000000000000000000000000000000000000000000000000000050000000000000000000000008d97cea50351fb4329d591682b148d43a0c3611b000000000000000000000000975ed13fa16857e83e7c493c7741d556eaad4a3f000000000000000000000000a0fb8cd450c8fd3a11901876cd5f17eb47c6bc50000000000000000000000000e65b77f52d8645ecad3edfdf4d3e5b1a9d31f988eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000001c0000000000000000000000000000000000000000000000000000000000000028000000000000000000000000000000000000000000000000000000000000003600000000000000000000000000000000000000000000000000000000000000440020000000000000000000000c124fe2f5edc1b645076a0722a7db8e9bd0227e30000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000068c5c3b16ce777f1f0208cf16bdb84790d0a0e28000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001030100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003c82fa372dd51cbfdd929dcb4f1b92fe752f0d56000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000002000100000000000000000000000000007fffffffffffffffffffffffffffffff010200000000000000000000000000007fffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004b5f68d5155c5504bdf7185376b6bba8e2c1519000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000002020200000000000000000000000000007fffffffffffffffffffffffffffffff040100000000000000000000000000007fffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013aea9ab700778b7472d8968a74a2179a62331ec000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000002000100000000000000000000000000007fffffffffffffffffffffffffffffff040200000000000000000000000000007fffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000"
            );

            require(success);

            for (uint256 i = 0; i < tokens.length; i++) {
                deltas[i] =
                    IERC20(tokens[i]).balanceOf(address(this)) -
                    deltas[i];

                uint256 delta = deltas[i];
                uint256 protocolFee = (delta * protocolFeeRate[tokens[i]]) / 1e18;
                accruedProtocolFee[IERC20(tokens[i])] += protocolFee;

                staked.reward(slot(tokens[i]), delta - protocolFee);
            }
        }

        if (addr != address(0)) {
            for (uint256 i = 0; i < tokens.length; i++) {
                uint256 harvested = staked.harvest(slot(addr), slot(tokens[i]));
                amounts[i] = harvested;

                if (harvested > 0) {
                    emit Harvest(addr, harvested);
                    IERC20(tokens[i]).safeTransfer(addr, harvested);
                }
            }
        }
        return amounts;
    }

    function setProtocolFeeRate(address token, uint256 feeRate) external onlyOwner {
	    protocolFeeRate[token] = feeRate;
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
        uint256 mintable = maxSupply - totalEmission;

        uint256 emission = Math.mulDiv(mintable, decayed, 2 ** 128);

        return Math.mulDiv(mintable - emission, 2 ** 128 - decay, 2 ** 128);
    }

    function rewardRate() external returns (address[] memory tokens, uint256[] memory rates) {
        _harvest(address(0), true);
        (address[] memory tokens, uint256[] memory rates) = IRewardDistributor(distributor)
            .emissionRates();
	if (staked.total == 0) {
		return (tokens, new uint256[](rates.length));
	}
	for (uint256 i = 0; i < tokens.length; i++) {
		rates[i] = rates[i] * (1e18 - protocolFeeRate[tokens[i]]) / staked.total;
	}
	return (tokens, rates);
    }

    receive() external payable {}
}
