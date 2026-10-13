// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IVoter.sol";
import "./interfaces/IXToken.sol";
import "./interfaces/IPairFactory.sol";
import "./v2/interfaces/pool/IClPoolImmutables.sol";
import "./v2/interfaces/IClPoolFactory.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IFeeDistributor.sol";
import "./interfaces/IGauge.sol";
import "./interfaces/IMinter.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract CommandCenter is Initializable, AccessControlEnumerableUpgradeable {
    error InvalidFee();
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");

    IXToken public xToken;
    IVoter public voter;
    IPairFactory public legacyFactory;
    IClPoolFactory public factoryCL;

    uint256 public constant MAX_BPS_LEGACY = 500; //Max fee of 500bps = 5%
    uint24 public constant MAX_BPS_CL = 100_000; // Max fee of 10%
    uint256 public constant MAX_LOCK = 126144000; // 4 years

    address public multisig;
    address public votingEscrow;
    address public emissionsToken;
    address public minter;

    event feeChangeV1(address _pair, uint256 _newrate);
    event feeChangeV2(address _pair, uint256 _newrate);
    event newGlobalVolatileFee(uint256 _newBps);
    event newGlobalCorrelatedFee(uint256 _newBps);

    event Rebase(uint256 _veID, uint256 _amount);
    event AddNewNFT(address _for, uint256 _amount);
    event VoteIncentives(address[] _pools, uint256[] _amounts);
    event LPIncentives(address[] _gauge, uint256[] _amount);

    constructor() {
        _disableInitializers();
    }

    function initialize(
        IVoter _voter,
        IXToken _xToken,
        address _multisig,
        address _operator,
        IPairFactory _legacyFactory,
        IClPoolFactory _factoryCL
    ) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _multisig);
        _grantRole(OPERATOR_ROLE, _multisig);
        _grantRole(OPERATOR_ROLE, _operator);

        voter = _voter;
        xToken = _xToken;

        legacyFactory = _legacyFactory;
        factoryCL = _factoryCL;
    }

    function initializeNewVars() external reinitializer(2) {
        votingEscrow = IVoter(voter)._ve();
        emissionsToken = IVoter(voter).base();
        multisig = IVoter(voter).governor();
        minter = IVoter(voter).minter();

        IERC20(emissionsToken).approve(address(xToken), type(uint256).max);
        IERC20(emissionsToken).approve(
            address(votingEscrow),
            type(uint256).max
        );
    }

    /********************************************** */
    // Gauge Controller Functions
    /********************************************** */

    /// @notice forbids a non-supported token from creating a new gauge
    function forbidToken(
        address _token,
        bool _status
    ) external onlyRole(OPERATOR_ROLE) {
        voter.forbid(_token, _status);
    }

    function killGauge(
        address[] calldata _pairs
    ) external onlyRole(OPERATOR_ROLE) {
        for (uint256 i = 0; i < _pairs.length; ++i) {
            voter.killGauge(getGauge(_pairs[i]));
        }
    }

    function reviveGauge(
        address[] calldata _pairs
    ) external onlyRole(OPERATOR_ROLE) {
        for (uint256 i = 0; i < _pairs.length; ++i) {
            voter.reviveGauge(getGauge(_pairs[i]));
        }
    }

    function addClGaugeReward(
        address pair,
        address reward
    ) external onlyRole(OPERATOR_ROLE) {
        address gauge = getGauge(pair);
        voter.addClGaugeReward(gauge, reward);
    }

    function removeClGaugeReward(
        address pair,
        address reward
    ) external onlyRole(OPERATOR_ROLE) {
        address gauge = getGauge(pair);
        voter.removeClGaugeReward(gauge, reward);
    }

    function whitelistLegacyGaugeReward(
        address _gauge,
        address _reward
    ) external onlyRole(OPERATOR_ROLE) {
        voter.whitelistGaugeReward(_gauge, _reward);
    }

    function removeLegacyGaugeReward(
        address _gauge,
        address _reward
    ) external onlyRole(OPERATOR_ROLE) {
        voter.removeGaugeReward(_gauge, _reward);
    }

    /********************************************** */
    // Reserve Contract Functionality
    /********************************************** */

    /// @notice accept the candidate position
    function acceptLegacyFactoryFeeAccess()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        legacyFactory.acceptFeeManager();
    }

    /// @notice changes the Fee of a V1 pair
    /// @param _pair is an array of all the V1 pairs that are to be altered
    /// @param _bps is an array of all the fee variables to adjust the pairs
    function setFeeLegacy(
        address[] calldata _pair,
        uint256[] calldata _bps
    ) external onlyRole(FEE_SETTER_ROLE) {
        for (uint256 i = 0; i < _pair.length; ++i) {
            require((_bps[i] > 0) && (_bps[i] <= MAX_BPS_LEGACY), "!valid");
            if (legacyFactory.pairFee(_pair[i]) == _bps[i]) continue;
            legacyFactory.setPairFee(_pair[i], _bps[i]);
            emit feeChangeV1(_pair[i], _bps[i]);
        }
    }

    ///@notice sets the default fee split for all new pairs
    function setLegacyFeeSplitDefault(
        uint8 _feeDist,
        uint8 _treasury
    ) external onlyRole(OPERATOR_ROLE) {
        legacyFactory.setFeeSplit(_feeDist, _treasury);
    }

    ///@notice set Pool(s) fee splits individually
    function setPoolSplit(
        address[] calldata _pools,
        uint8[] calldata _feeDist,
        uint8[] calldata _treasury
    ) external onlyRole(OPERATOR_ROLE) {
        require(
            _pools.length == _feeDist.length &&
                _feeDist.length == _treasury.length,
            "!L"
        );
        for (uint256 i = 0; i < _pools.length; ++i) {
            legacyFactory.setPoolFeeSplit(_pools[i], _feeDist[i], _treasury[i]);
        }
    }

    /// @notice sets the uint24 fee variable for each V2 pair in the array
    /// @param _pair is an array of all the V2 (CL) pairs that are to be changed
    /// @param _fee is an array of all the fee variables (as uint24) to adjust to
    function setFeeCL(
        address[] calldata _pair,
        uint24[] calldata _fee
    ) external onlyRole(FEE_SETTER_ROLE) {
        for (uint256 i = 0; i < _pair.length; ++i) {
            if (isValidFee(false, _fee[i])) {
                factoryCL.setFee(_pair[i], _fee[i]);
                emit feeChangeV2(_pair[i], _fee[i]);
            } else {
                revert InvalidFee();
            }
        }
    }

    /// @notice Changes the fees of all CorrelatedPairs
    /// @param _bps is the global fee to change the correlated pairs to
    function changeDefaultCorrelatedFee(
        uint256 _bps
    ) external onlyRole(OPERATOR_ROLE) {
        if (isValidFee(true, _bps)) {
            legacyFactory.setFee(true, _bps);
            emit newGlobalCorrelatedFee(_bps);
        } else {
            revert InvalidFee();
        }
    }

    /// @notice Changes the fees of all volatile pairs
    /// @param _bps is the global fee to change the volatile pairs to
    function changeDefaultVolatileFee(
        uint256 _bps
    ) external onlyRole(OPERATOR_ROLE) {
        if (isValidFee(true, _bps)) {
            legacyFactory.setFee(false, _bps);
            emit newGlobalVolatileFee(_bps);
        } else {
            revert InvalidFee();
        }
    }

    /// @notice for altering the addresses of the factories if something was the be upgraded/migrated
    /// @param _newFactory is the new factory's address
    function setLegacyFactory(
        address _newFactory
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        legacyFactory = IPairFactory(_newFactory);
    }

    /// @notice for altering the addresses of the factories if something was the be upgraded/migrated
    /// @param _newFactory is the new factory's address
    function setClFactory(
        address _newFactory
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        factoryCL = IClPoolFactory(_newFactory);
    }

    function setFeeProtocol(
        uint8 _feeProtocol
    ) external onlyRole(OPERATOR_ROLE) {
        IClPoolFactory(factoryCL).setFeeProtocol(_feeProtocol);
    }

    function setPoolFeeProtocol(
        address pool,
        uint8 _feeProtocol
    ) external onlyRole(OPERATOR_ROLE) {
        IClPoolFactory(factoryCL).setPoolFeeProtocol(pool, _feeProtocol);
    }

    ///@dev send a direct rebase to an NFT ID
    function rebase(
        uint256 _veID,
        uint256 _amount
    ) external onlyRole(OPERATOR_ROLE) {
        IVotingEscrow(votingEscrow).depositFor(_veID, _amount);
        emit Rebase(_veID, _amount);
    }

    ///@dev initiate a new veNFT using amounts in the contract
    function newLock(
        uint256 _amount,
        address _for
    ) external onlyRole(OPERATOR_ROLE) {
        IVotingEscrow(votingEscrow).createLockFor(_amount, MAX_LOCK, _for);
        emit AddNewNFT(_for, _amount);
    }

    function incentivizeVotes(
        address[] calldata _pools,
        uint256[] calldata _emissionsTokenAmounts
    ) external onlyRole(OPERATOR_ROLE) {
        for (uint256 i = 0; i < _pools.length; ++i) {
            IFeeDistributor _feeDist = IFeeDistributor(
                voter.feeDistributors(voter.gauges(_pools[i]))
            );
            IERC20(emissionsToken).approve(
                address(_feeDist),
                _emissionsTokenAmounts[i]
            );
            _feeDist.incentivize(emissionsToken, _emissionsTokenAmounts[i]);
        }
        emit VoteIncentives(_pools, _emissionsTokenAmounts);
    }

    function incentivizePool(
        address[] calldata _pools,
        uint256[] calldata _emissionsTokenAmounts
    ) external onlyRole(OPERATOR_ROLE) {
        for (uint256 i = 0; i < _pools.length; ++i) {
            IGauge gauge = IGauge(getGauge(_pools[i]));
            IERC20(emissionsToken).approve(
                address(gauge),
                _emissionsTokenAmounts[i]
            );
            gauge.notifyRewardAmount(emissionsToken, _emissionsTokenAmounts[i]);
        }
        emit LPIncentives(_pools, _emissionsTokenAmounts);
    }

    function getGauge(address _pair) public view returns (address) {
        return voter.gauges(_pair);
    }

    function multisigWithdraw(
        address token,
        uint256 amount
    ) external onlyRole(OPERATOR_ROLE) {
        if (amount == 0)
            IERC20(token).transfer(
                multisig,
                IERC20(token).balanceOf(address(this))
            );
        else IERC20(token).transfer(multisig, amount);
    }

    function updateIncentivesSize(
        uint256 _newSize
    ) external onlyRole(OPERATOR_ROLE) {
        IMinter(minter).updateIncentivesSize(_newSize);
    }

    function updateFlation(uint256 _newRate) external onlyRole(OPERATOR_ROLE) {
        IMinter(minter).updateFlation(_newRate);
    }

    function updateGrowthCap(
        uint256 _newGrowth
    ) external onlyRole(OPERATOR_ROLE) {
        IMinter(minter).updateGrowthCap(_newGrowth);
    }

    function getGaugeArray(
        address[] memory _pairs
    ) public view returns (address[] memory gauges) {
        for (uint256 i = 0; i < _pairs.length; ++i) {
            _pairs[i] = getGauge(_pairs[i]);
        }
        return _pairs;
    }

    function isValidFee(bool _legacy, uint256 _bps) public pure returns (bool) {
        if (_legacy) {
            if (_bps > 0 && _bps <= MAX_BPS_LEGACY) return true;
            return false;
        } else {
            if (_bps > 0 && _bps <= MAX_BPS_CL) return true;
        }
        return false;
    }

    function clawBackEmissionsGivenRanges(
        uint256 _start,
        uint256 _end
    ) external onlyRole(OPERATOR_ROLE) {
        address[] memory _pairs = new address[](_end - _start);
        uint256 x;
        for (uint256 i = _start; i < _end; ++i) {
            _pairs[x] = voter.pools(i);
            unchecked {
                x++;
            }
        }
        voter.clawBackUnusedEmissions(getGaugeArray(_pairs));
    }

    /// @notice whitelists a token to be used in gauge creation
    function whitelist(address _token) external onlyRole(OPERATOR_ROLE) {
        voter.whitelist(_token);
    }
}
