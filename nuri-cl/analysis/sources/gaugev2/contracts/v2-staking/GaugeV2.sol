// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./interfaces/IGaugeV2.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "./interfaces/IFeeCollector.sol";
import "./libraries/FullMath.sol";

import "../v2/interfaces/IClPool.sol";

import "../v2/libraries/States.sol";

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract GaugeV2 is Initializable, IGaugeV2 {
    using SafeERC20 for IERC20;

    uint256 internal constant WEEK = 1 weeks;
    uint256 internal constant PRECISION = 10 ** 18;

    bool internal _unlocked;

    address public gaugeFactory;
    IClPool public pool;
    address public voter;
    IFeeCollector public feeCollector;
    INonfungiblePositionManager public nfpManager;

    /// @inheritdoc IGaugeV2
    uint256 public firstPeriod;

    /// @inheritdoc IGaugeV2
    /// @dev period => token => total supply
    mapping(uint256 => mapping(address => uint256))
        public tokenTotalSupplyByPeriod;

    /// @dev period => position hash => bool
    mapping(uint256 => mapping(bytes32 => bool)) internal periodAmountsWritten;
    /// @dev period => position hash => seconds in range
    mapping(uint256 => mapping(bytes32 => uint256))
        internal periodNfpSecondsX96;

    /// @inheritdoc IGaugeV2
    /// @dev period => position hash => reward token => amount
    mapping(uint256 => mapping(bytes32 => mapping(address => uint256)))
        public periodClaimedAmount;

    // token => position hash => period
    /// @inheritdoc IGaugeV2
    mapping(address => mapping(bytes32 => uint256)) public lastClaimByToken;

    /// @inheritdoc IGaugeV2
    address[] public rewards;
    /// @inheritdoc IGaugeV2
    mapping(address => bool) public isReward;

    /// @dev Mutually exclusive reentrancy protection into the pool to/from a method. This method also prevents entrance
    /// to a function before the Gauge is initialized.
    modifier lock() {
        require(_unlocked, "LOK");
        _unlocked = false;
        _;
        _unlocked = true;
    }

    /// @dev pushes fees from the pool to fee distributor on notify rewards
    modifier pushFees() {
        feeCollector.collectProtocolFees(pool);
        _;
    }

    /// @dev disables the initializer
    constructor() {
        _disableInitializers();
    }

    /// @inheritdoc IGaugeV2
    function initialize(
        address _gaugeFactory,
        address _voter,
        address _nfpManager,
        address _feeCollector,
        address _pool
    ) external override initializer {
        _unlocked = true;

        gaugeFactory = _gaugeFactory;
        voter = _voter;
        feeCollector = IFeeCollector(_feeCollector);
        nfpManager = INonfungiblePositionManager(_nfpManager);
        pool = IClPool(_pool);

        firstPeriod = _blockTimestamp() / WEEK;
    }

    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @inheritdoc IGaugeV2
    function left(address token) external view override returns (uint256) {
        uint256 period = _blockTimestamp() / WEEK;
        uint256 remainingTime = ((period + 1) * WEEK) - _blockTimestamp();
        return (tokenTotalSupplyByPeriod[period][token] * remainingTime) / WEEK;
    }

    /// @inheritdoc IGaugeV2
    function rewardRate(address token) external view returns (uint256) {
        uint256 period = _blockTimestamp() / WEEK;
        return (tokenTotalSupplyByPeriod[period][token] / WEEK);
    }

    /// @inheritdoc IGaugeV2
    function getRewardTokens()
        external
        view
        override
        returns (address[] memory)
    {
        return rewards;
    }

    /// @inheritdoc IGaugeV2
    function positionHash(
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, index, tickLower, tickUpper));
    }

    /// @inheritdoc IGaugeV2
    // idt we need this at this point cuz pool.positions returns liq
    // and nfpmanager
    // but ye
    function positionInfo(
        uint256 tokenId
    ) external view override returns (uint128 liquidity) {
        INonfungiblePositionManager _nfpManager = nfpManager;
        (, , , , , int24 tickLower, int24 tickUpper, , , , , ) = _nfpManager
            .positions(tokenId);

        bytes32 _positionHash = positionHash(
            address(_nfpManager),
            tokenId,
            tickLower,
            tickUpper
        );

        States.PoolStates storage states = States.getStorage();

        PositionInfo storage positionData = states.positions[_positionHash];

        bytes32 liquiditySlot;

        bytes32[] memory slots = new bytes32[](1);

        // define slots to read
        // both slots are in the 0th slot of the struct
        assembly {
            liquiditySlot := positionData.slot
        }
        slots[0] = liquiditySlot;

        // read slots from pool
        bytes32[] memory data = pool.readStorage(slots);

        liquidity = uint128(uint256(data[0]));
    }

    /// @inheritdoc IGaugeV2
    function notifyRewardAmount(
        address token,
        uint256 amount
    ) external override pushFees lock {
        IClPool(pool)._advancePeriod();
        uint256 period = _blockTimestamp() / WEEK;

        if (!isReward[token]) {
            isReward[token] = true;
            rewards.push(token);
        }

        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));

        amount = balanceAfter - balanceBefore;
        tokenTotalSupplyByPeriod[period][token] += amount;
        emit NotifyReward(msg.sender, token, amount, period);
    }

    /// @inheritdoc IGaugeV2
    function earned(
        address token,
        uint256 tokenId
    ) external view returns (uint256 reward) {
        INonfungiblePositionManager _nfpManager = nfpManager;
        (, , , , , int24 tickLower, int24 tickUpper, , , , , ) = _nfpManager
            .positions(tokenId);

        bytes32 _positionHash = positionHash(
            address(_nfpManager),
            tokenId,
            tickLower,
            tickUpper
        );

        uint256 lastClaim = Math.max(
            lastClaimByToken[token][_positionHash],
            firstPeriod
        );
        uint256 currentPeriod = _blockTimestamp() / WEEK;
        for (uint256 period = lastClaim; period <= currentPeriod; ++period) {
            reward += periodEarned(
                period,
                token,
                address(_nfpManager),
                tokenId,
                tickLower,
                tickUpper
            );
        }
    }

    /// @inheritdoc IGaugeV2
    function periodEarned(
        uint256 period,
        address token,
        uint256 tokenId
    ) public view override returns (uint256) {
        INonfungiblePositionManager _nfpManager = nfpManager;
        (, , , , , int24 tickLower, int24 tickUpper, , , , , ) = _nfpManager
            .positions(tokenId);

        return
            periodEarned(
                period,
                token,
                address(_nfpManager),
                tokenId,
                tickLower,
                tickUpper
            );
    }

    /// @inheritdoc IGaugeV2
    function periodEarned(
        uint256 period,
        address token,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper
    ) public view returns (uint256 amount) {
        (bool success, bytes memory data) = address(this).staticcall(
            abi.encodeCall(
                this.cachePeriodEarned,
                (period, token, owner, index, tickLower, tickUpper, false)
            )
        );

        if (!success) {
            return 0;
        }

        return abi.decode(data, (uint256));
    }

    /// @inheritdoc IGaugeV2
    /// @dev used by getReward() and saves gas by saving states
    function cachePeriodEarned(
        uint256 period,
        address token,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        bool caching
    ) public override returns (uint256 amount) {
        uint256 periodSecondsInsideX96;

        bytes32 _positionHash = positionHash(
            owner,
            index,
            tickLower,
            tickUpper
        );

        // get seconds from pool if not already written into storage
        if (!periodAmountsWritten[period][_positionHash]) {
            (bool success, bytes memory data) = address(pool).staticcall(
                abi.encodeCall(
                    IClPoolState.positionPeriodSecondsInRange,
                    (period, owner, index, tickLower, tickUpper)
                )
            );

            if (!success) {
                return 0;
            }

            (periodSecondsInsideX96) = abi.decode(data, (uint256));

            if (period < _blockTimestamp() / WEEK && caching) {
                periodAmountsWritten[period][_positionHash] = true;
                periodNfpSecondsX96[period][
                    _positionHash
                ] = periodSecondsInsideX96;
            }
        } else {
            periodSecondsInsideX96 = periodNfpSecondsX96[period][_positionHash];
        }

        amount = FullMath.mulDiv(
            tokenTotalSupplyByPeriod[period][token],
            periodSecondsInsideX96,
            WEEK << 96
        );

        uint256 claimed = periodClaimedAmount[period][_positionHash][token];
        if (amount >= claimed) {
            amount -= claimed;
        } else {
            amount = 0;
        }

        return amount;
    }

    /// @inheritdoc IGaugeV2
    function getPeriodReward(
        uint256 period,
        address[] calldata tokens,
        uint256 tokenId,
        address receiver
    ) external override lock {
        INonfungiblePositionManager _nfpManager = nfpManager;
        address owner = _nfpManager.ownerOf(tokenId);
        address operator = _nfpManager.getApproved(tokenId);

        require(
            msg.sender == owner || msg.sender == operator,
            "Not authorized"
        );

        (, , , , , int24 tickLower, int24 tickUpper, , , , , ) = _nfpManager
            .positions(tokenId);

        bytes32 _positionHash = positionHash(
            address(_nfpManager),
            tokenId,
            tickLower,
            tickUpper
        );

        for (uint256 i = 0; i < tokens.length; ++i) {
            if (period < _blockTimestamp() / WEEK) {
                lastClaimByToken[tokens[i]][_positionHash] = period;
            }

            _getReward(
                period,
                tokens[i],
                address(_nfpManager),
                tokenId,
                tickLower,
                tickUpper,
                _positionHash,
                receiver
            );
        }
    }

    /// @inheritdoc IGaugeV2
    function getPeriodReward(
        uint256 period,
        address[] calldata tokens,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        address receiver
    ) external override lock {
        require(msg.sender == owner, "Not authorized");
        bytes32 _positionHash = positionHash(
            owner,
            index,
            tickLower,
            tickUpper
        );

        for (uint256 i = 0; i < tokens.length; ++i) {
            if (period < _blockTimestamp() / WEEK) {
                lastClaimByToken[tokens[i]][_positionHash] = period;
            }

            _getReward(
                period,
                tokens[i],
                owner,
                index,
                tickLower,
                tickUpper,
                _positionHash,
                receiver
            );
        }
    }

    function getReward(
        uint256[] calldata tokenIds,
        address[] memory tokens
    ) external {
        uint256 length = tokenIds.length;

        for (uint256 i = 0; i < length; ++i) {
            getReward(tokenIds[i], tokens);
        }
    }

    function getReward(uint256 tokenId, address[] memory tokens) public lock {
        INonfungiblePositionManager _nfpManager = nfpManager;
        address owner = _nfpManager.ownerOf(tokenId);
        address operator = _nfpManager.getApproved(tokenId);

        require(
            msg.sender == owner || msg.sender == operator,
            "Not authorized"
        );

        (, , , , , int24 tickLower, int24 tickUpper, , , , , ) = _nfpManager
            .positions(tokenId);

        _getAllRewards(
            address(_nfpManager),
            tokenId,
            tickLower,
            tickUpper,
            tokens,
            msg.sender
        );
    }

    function getRewardForOwner(
        uint256 tokenId,
        address[] memory tokens
    ) external lock {
        require(
            msg.sender == voter || msg.sender == address(nfpManager),
            "Not authorized"
        );

        INonfungiblePositionManager _nfpManager = nfpManager;
        address owner = _nfpManager.ownerOf(tokenId);

        (, , , , , int24 tickLower, int24 tickUpper, , , , , ) = _nfpManager
            .positions(tokenId);

        _getAllRewards(
            address(_nfpManager),
            tokenId,
            tickLower,
            tickUpper,
            tokens,
            owner
        );
    }

    function getReward(
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        address[] memory tokens,
        address receiver
    ) external lock {
        require(msg.sender == owner, "Not authorized");
        _getAllRewards(owner, index, tickLower, tickUpper, tokens, receiver);
    }

    function _getAllRewards(
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        address[] memory tokens,
        address receiver
    ) internal {
        bytes32 _positionHash = positionHash(
            owner,
            index,
            tickLower,
            tickUpper
        );
        uint256 currentPeriod = _blockTimestamp() / WEEK;
        uint256 lastClaim;
        for (uint256 i = 0; i < tokens.length; ++i) {
            lastClaim = Math.max(
                lastClaimByToken[tokens[i]][_positionHash],
                firstPeriod
            );
            for (
                uint256 period = lastClaim;
                period <= currentPeriod;
                ++period
            ) {
                _getReward(
                    period,
                    tokens[i],
                    owner,
                    index,
                    tickLower,
                    tickUpper,
                    _positionHash,
                    receiver
                );
            }
            lastClaimByToken[tokens[i]][_positionHash] = currentPeriod - 1;
        }
    }

    function _getReward(
        uint256 period,
        address token,
        address owner,
        uint256 index,
        int24 tickLower,
        int24 tickUpper,
        bytes32 _positionHash,
        address receiver
    ) internal {
        uint256 _reward = cachePeriodEarned(
            period,
            token,
            owner,
            index,
            tickLower,
            tickUpper,
            true
        );

        if (_reward > 0) {
            periodClaimedAmount[period][_positionHash][token] += _reward;

            IERC20(token).safeTransfer(receiver, _reward);
            emit ClaimRewards(period, _positionHash, receiver, token, _reward);
        }
    }

    function addRewards(address reward) external {
        require(msg.sender == voter, "!AUTH");
        if (!isReward[reward]) {
            rewards.push(reward);
            emit RewardAdded(reward);
        }
    }

    function removeRewards(address reward) external {
        require(msg.sender == voter, "!AUTH");
        if (isReward[reward]) {
            uint256 idx;

            for (uint256 i; i < rewards.length; ++i) {
                if (rewards[i] == reward) {
                    idx = i;
                    break;
                }
            }

            for (uint256 i = idx; i < rewards.length - 1; ++i) {
                rewards[i] = rewards[i + 1];
            }

            rewards.pop();
            isReward[reward] = false;

            emit RewardRemoved(reward);
        }
    }

    // @inheritdoc IGaugeV2
    function notifyRewardAmountForPeriod(
        address token,
        uint256 amount,
        uint256 period
    ) external lock {
        require(isReward[token], "!Whitelisted");
        require(period > _blockTimestamp() / WEEK, "Retro");
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));

        amount = balanceAfter - balanceBefore;
        tokenTotalSupplyByPeriod[period][token] += amount;

        emit NotifyReward(msg.sender, token, amount, period);
    }

    /// @inheritdoc IGaugeV2
    function notifyRewardAmountNextPeriod(
        address token,
        uint256 amount
    ) external lock {
        require(isReward[token], "!Whitelisted");
        uint256 period = (_blockTimestamp() / WEEK) + 1;
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));

        amount = balanceAfter - balanceBefore;
        tokenTotalSupplyByPeriod[period][token] += amount;

        emit NotifyReward(msg.sender, token, amount, period);
    }
}
