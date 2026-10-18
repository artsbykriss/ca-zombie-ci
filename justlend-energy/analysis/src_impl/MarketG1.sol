// File: contracts/strx-protocol/src/AdminStorage.sol

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

contract AdminStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of this contract
    */
    address public implementation;

    /**
    * @notice Pending brains of this contract
    */
    address public pendingImplementation;
}

// File: contracts/strx-protocol/interface/IRateModel.sol

pragma solidity ^0.8.18;

interface IRateModel {
    function getRentalRate(uint256 supply, uint256 borrows) external view returns (uint256);
}

// File: contracts/strx-protocol/interface/ISTRXForMarket.sol

pragma solidity ^0.8.18;

interface ISTRXForMarket {

    function marketDelegateResource(address payable renter, uint256 amount, uint256 resourceType) external;

    function marketUndelegateResource(address payable renter, uint256 amount, uint256 resourceType) external;

    function receiveRental() external payable;

    function getBalanceToUnfreeze() external view returns (uint256);
}

// File: contracts/strx-protocol/src/MarketV1Storage.sol

pragma solidity ^0.8.18;



contract MarketV1Storage is AdminStorage {

    uint256 internal constant AMOUNT_MASK = 0xFFFF_FFFF_FFFF_FFFF << 192;

    uint256 internal constant SECURITY_DEPOSIT_MASK = 0xFFFF_FFFF_FFFF_FFFF << 128;

    uint256 internal constant RENT_INDEX_MASK = 0xFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;

    struct RentalInfo {
        // 64 bit
        uint256 amount;
        // 64 bit
        uint256 securityDeposit;
        // 128 bit
        uint256 rentIndex;
    }

    struct RentState {
        uint128 lastUpdateTime;
        uint128 rentIndex;
    }

    struct RentRate {
        uint128 timestamp;
        uint128 rate;
    }

    bool public initialized;

    bool[2] public rentPaused;

    ISTRXForMarket public strx;

    uint256 public maxRentalScaleLimit;

    IRateModel[2] public rentalRateModels;

    uint256 public minFee;

    uint256 public feeRatio;

    uint256 public liquidateThreshold;

    uint256 public rateRampTime;

    uint256 public usageChargeRatio;

    RentState[2] public globalRentState;

    RentRate[2] public initialRentRate;

    RentRate[2] public futureRentRate;

    // ----------------------------- Logic related storages, no need to initial -----------------------------

    uint256 public badDebt;

    uint256 public badDebtCovered;

    uint256 public totalRent;

    uint256 public rentClaimed;

    mapping(address => mapping(address => uint256[2])) private rentals_;

    function setRental(address renter, address receiver, uint256 resourceType, RentalInfo memory info) internal {
        uint256 data;
        data |= (info.amount << 192) & AMOUNT_MASK;
        data |= (info.securityDeposit << 128) & SECURITY_DEPOSIT_MASK;
        data |= info.rentIndex & RENT_INDEX_MASK;

        rentals_[renter][receiver][resourceType] = data;
    }

    function rentals(address renter, address receiver, uint256 resourceType) public view returns (RentalInfo memory) {
        uint256 data = rentals_[renter][receiver][resourceType];

        uint256 amount = (data & AMOUNT_MASK) >> 192;
        uint256 securityDeposit = (data & SECURITY_DEPOSIT_MASK) >> 128;
        uint256 rentIndex = data & RENT_INDEX_MASK;

        RentalInfo memory info = RentalInfo(amount, securityDeposit, rentIndex);
        return info;
    }

}

// File: contracts/strx-protocol/interface/IResourceMarket.sol

pragma solidity ^0.8.18;

interface IResourceMarket {

    /**
     * @notice Event emitted when resource is rented
     */
    event ResourceRented(
        address indexed resourceRenter,
        address indexed resourceReceiver,
        uint256 indexed resourceType,
        uint256 resourceAmount
    );

    /**
     * @notice Event emitted when resource is returned
     */
    event ResourceReturned(
        address indexed resourceRenter,
        address indexed resourceReceiver,
        uint256 indexed resourceType,
        uint256 resourceAmount
    );

    /**
     * @notice Sender rent a specified amount of resource for resourceReceiver
     * @param resourceReceiver The user to receive the resource, can not be contract or inactivated address
     * @param resourceAmount The amount of resource to rent, in trx
     * @param resourceType The type of resource to rent
     */
    function rentResource(address resourceReceiver, uint256 resourceAmount, uint256 resourceType) external payable;

    /**
     * @notice Sender return a specified amount of resource that sender rented for resourceReceiver
     * @param resourceReceiver The user received the resource
     * @param resourceAmount The amount of resource to return, in trx
     * @param resourceType The type of resource to return
     */
    function returnResource(address resourceReceiver, uint256 resourceAmount, uint256 resourceType) external returns (uint256);

    /**
     * @notice Sender return a specified amount of resource that resourceRenter rented for sender
     * @param resourceRenter The user rented the resource
     * @param resourceAmount The amount of resource to return, in trx
     * @param resourceType The type of resource to return
     */
    function returnResourceByReceiver(address resourceRenter, uint256 resourceAmount, uint256 resourceType) external returns (uint256);

    /**
     * @notice Check whether a type of resource is supported in the market
     * @param resourceType The type of resource to check
     * @return support True if the type of resource is supported, else False
     */
    function supportsResourceType(uint256 resourceType) external view returns (bool support);
}

// File: contracts/strx-protocol/interface/IMarketForSTRX.sol

pragma solidity ^0.8.18;

interface IMarketForSTRX {
    function claimRental() external returns (uint256);

    function repayBadDebt() external payable;

    function updateRentRate() external;

    function badDebtGap() external view returns (uint256);
}

// File: contracts/strx-protocol/interface/IProxy.sol

pragma solidity ^0.8.18;

interface IProxy {
    function _acceptImplementation() external;
    function admin() external view returns (address);
}

// File: contracts/strx-protocol/interface/ITRC165.sol

pragma solidity ^0.8.18;

interface ITRC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// File: contracts/strx-protocol/src/TRC165.sol

pragma solidity ^0.8.18;

abstract contract TRC165 is ITRC165 {

    // ITRC165 interfaceId: 0x01ffc9a7
    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(ITRC165).interfaceId;
    }
}

// File: contracts/strx-protocol/src/MarketG1.sol

pragma solidity ^0.8.18;

contract MarketG1 is MarketV1Storage, IResourceMarket, IMarketForSTRX, TRC165 {

    uint256 public constant SCALE = 1e18;

    uint256 public constant HALF_SCALE = 5e17;

    uint256 public constant ONE_TRX = 1e6;

    struct RepayResult {
        uint256 sendBack;

        uint256 dirtyRent;
    }

    event RentResource(
        address indexed renter,
        address indexed receiver,
        uint256 addedAmount,
        uint256 resourceType,
        uint256 addedSecurityDeposit,
        uint256 amount,
        uint256 securityDeposit,
        uint256 rentIndex
    );

    event ReturnResource(
        address indexed renter,
        address indexed receiver,
        uint256 subedAmount,
        uint256 resourceType,
        uint256 usageRental,
        uint256 subedSecurityDeposit,
        uint256 amount,
        uint256 securityDeposit,
        uint256 rentIndex
    );

    event Liquidate(
        address indexed liquidator,
        address indexed renter,
        address indexed receiver,
        uint256 amount,
        uint256 resourceType,
        uint256 usageRental,
        uint256 liquidateFee,
        uint256 sendBack
    );

    event RentIndex(
        uint256 indexed resourceType,
        uint256 rate,
        uint256 prevIndex,
        uint256 newIndex,
        uint256 delegated,
        uint256 income
    );

    event OrderIndex(
        address indexed renter,
        address indexed receiver,
        uint256 indexed resourceType,
        uint256 prevIndex,
        uint256 newIndex,
        uint256 amount,
        uint256 rental,
        uint256 badDebt
    );

    event BadDebtAdded(uint256 add, uint256 totalBadDebt);

    event BadDebtCovered(uint256 add, uint256 totalCovered);

    event RentClaimed(uint256 add, uint256 totalClaimed);

    event BandwidthRentalRateModelUpdated(IRateModel oldModel, IRateModel newModel);

    event EnergyRentalRateModelUpdated(IRateModel oldModel, IRateModel newModel);

    event MinFeeUpdated(uint256 oldFee, uint256 newFee);

    event FeeRatioUpdated(uint256 oldRatio, uint256 newRatio);

    event RentPaused(uint256 resourceType, bool state);

    event UsageChargeRatioUpdated(uint256 oldRatio, uint256 newRatio);

    // -------------------------------- modifiers --------------------------------

    modifier onlyAdmin() {
        require(msg.sender == admin, "permission denied: not admin");
        _;
    }

    modifier onlyRentNotPaused(uint256 resourceType) {
        require(!rentPaused[resourceType], "rent is paused");
        _;
    }

    modifier onlyBandwidthOrEnergy(uint256 resourceType) {
        require(
            resourceType == 0 || resourceType == 1,
            "resource type invalid: only bandwidth or energy are supported");
        _;
    }

    modifier onlyStrx() {
        require(msg.sender == address(strx), "permission denied: not strx");
        _;
    }

    modifier canRent(
        address receiver,
        uint256 amount,
        uint256 resourceType
    )
    {
        require(!receiver.isContract, "resource rent: receiver cannot be contract");
        require(amount == 0 || amount >= ONE_TRX, "resource rent: resource amount must be no less than 1TRX");
        require(msg.value > 0 || amount > 0, "resource rent: amount and msg.value cannot both be zero");

        if (amount > 0) {
            uint256 delegatableResource = address(strx).delegatableResource(resourceType);
            require(amount <= delegatableResource, "resource rent: exceed delegate resource limit");
        }

        uint256 delegatedResource = totalDelegated();
        uint256 undelegatedResource = totalUnfreezable();
        uint256 toUnfreeze = strx.getBalanceToUnfreeze();
        require(
            amount + delegatedResource <= (delegatedResource + undelegatedResource - toUnfreeze) * maxRentalScaleLimit / SCALE,
            "resource rent: exceed resource rent limit");

        _;
    }

    modifier canReturn(
        address renter,
        address receiver,
        uint256 amount,
        uint256 resourceType
    )
    {
        require(amount > 0, "resource return: return amount zero error");
        require(
            rentals(renter, receiver, resourceType).amount >= amount,
            "resource return: no enough rental resource");
        _;
    }

    function init(
        address _strx,
        IRateModel[2] calldata _rentalRateModels,
        uint256 _maxRentalScaleLimit,
        uint256 _minFee,
        uint256 _feeRatio
    )
        external
        onlyAdmin
    {
        require(!initialized, "already initialized");
        require(_strx != address(0), "strx is empty");
        require(_maxRentalScaleLimit <= SCALE, "setMaxRentalScaleLimit: invalid rental limit");

        strx = ISTRXForMarket(_strx);
        rentalRateModels = _rentalRateModels;

        initialized = true;
        maxRentalScaleLimit = _maxRentalScaleLimit; // 1e18: 100%
        minFee = _minFee; // 200 * 1e6: 200TRX
        feeRatio = _feeRatio; // 1e16: 1%, fee = MAX(minFee, 1% * rentAmount)

        // pause the rent of bandwidth at init
        rentPaused[0] = true;
        rateRampTime = 6 hours;
        usageChargeRatio = HALF_SCALE;

        RentState memory state = RentState(uint128(block.timestamp), 0);
        globalRentState[0] = state;
        globalRentState[1] = state;

        RentRate memory bandwidthRentRate = RentRate(uint128(block.timestamp), uint128(_rentalRate(0, 0)));
        RentRate memory energyRentRate = RentRate(uint128(block.timestamp), uint128(_rentalRate(0, 1)));

        initialRentRate[0] = bandwidthRentRate;
        initialRentRate[1] = energyRentRate;

        futureRentRate[0] = bandwidthRentRate;
        futureRentRate[1] = energyRentRate;
    }

    function _become(IProxy market) external {
        require(msg.sender == market.admin(), "only admin can change brains");
        market._acceptImplementation();
    }

    function claimRental() external onlyStrx returns (uint256) {
        uint256 income;
        if (totalDelegatedOfType(0) > 0) {
            income += _updateRentIndexAndCalcIncome(0);
        }

        if (totalDelegatedOfType(1) > 0) {
            income += _updateRentIndexAndCalcIncome(1);
        }

        uint256 _rent = _settleIncome(income);

        uint256 _balance = address(this).balance;
        if (_rent > _balance) {
            _rent = _balance;
        }

        if (_rent > 0) {
            strx.receiveRental{value: _rent}();
            rentClaimed += _rent;
            emit RentClaimed(_rent, rentClaimed);
        }
        return _rent;
    }

    function repayBadDebt() external payable {
        require(msg.value > 0, "msg.value is zero");


        uint256 repay = badDebt - badDebtCovered;
        if (repay > msg.value) {
            repay = msg.value;
        }


        if (repay > 0) {
            uint256 covered = badDebtCovered;
            covered += repay;
            badDebtCovered = covered;
            emit BadDebtCovered(repay, covered);
        }


        if (msg.value > repay) {
            payable(msg.sender).transfer(msg.value - repay);
        }
    }

    // -------------------------------- resource renting related functions --------------------------------


    function rentResource(
        address receiver,
        uint256 amount,
        uint256 resourceType
    )
        external
        payable
        onlyRentNotPaused(resourceType)
        onlyBandwidthOrEnergy(resourceType)
        canRent(receiver, amount, resourceType)
    {
        (uint256 income, RentalInfo memory rentInfo) = _updateMarketWithRentUser(msg.sender, receiver, resourceType);
        _settleIncome(income);

        rentInfo.amount += amount;
        rentInfo.securityDeposit += msg.value;
        {
            require(rentInfo.amount > 0, "resource rent: rent amount is zero");

            uint256 rate = _rentalRate(amount, resourceType);
            uint256 fee = _calculateFee(rentInfo.amount);
            uint256 required = rentInfo.amount * rate * (1 days + liquidateThreshold) / SCALE + fee;
            require(rentInfo.securityDeposit > required, "resource rent: Not enough security deposit");
        }
        if (amount > 0) {
            try strx.marketDelegateResource(payable(receiver), amount, resourceType) {
            } catch {
                revert("resource rent: delegate resource error");
            }
        }

        setRental(msg.sender, receiver, resourceType, rentInfo);
        _updateRentRate(resourceType);

        emit ResourceRented(msg.sender, receiver, resourceType, amount);
        emit RentResource(msg.sender, receiver, amount, resourceType, msg.value, rentInfo.amount,
            rentInfo.securityDeposit, rentInfo.rentIndex);
    }

    function returnResource(
        address receiver,
        uint256 amount,
        uint256 resourceType
    )
        external
        returns (uint256)
    {
        return _returnResource(msg.sender, receiver, amount, resourceType);
    }

    function returnResourceByReceiver(
        address renter,
        uint256 amount,
        uint256 resourceType
    )
        external
        returns (uint256)
    {
        return _returnResource(renter, msg.sender, amount, resourceType);
    }


    function liquidate(
        address renter,
        address receiver,
        uint256 resourceType
    )
        external
        onlyBandwidthOrEnergy(resourceType)
        returns (uint256)
    {
        require(msg.sender != renter && msg.sender != receiver, "liquidate: not allowed to liquidate own orders");
        (uint256 income, RentalInfo memory rentInfo) = _updateMarketWithRentUser(renter, receiver, resourceType);

        _liquidateCheck(rentInfo, resourceType);

        uint256 liquidateAmount = rentInfo.amount;
        uint256 liquidateFee = _calculateFee(rentInfo.amount);
        RepayResult memory repayResult = _internalRepayForLiquidate(renter, receiver, resourceType, rentInfo, liquidateFee);
        _updateRentRate(resourceType);

        income += repayResult.dirtyRent;
        _settleIncome(income);

        if (repayResult.sendBack > 0) {
            _doTransferOut(payable(renter), repayResult.sendBack);
        }

        _doTransferOut(payable(msg.sender), liquidateFee);

        emit ResourceReturned(renter, receiver, resourceType, liquidateAmount);
        emit Liquidate(msg.sender, renter, receiver, liquidateAmount, resourceType,
            repayResult.dirtyRent, liquidateFee, repayResult.sendBack);

        return liquidateFee;
    }

    function forceLiquidate(
        address renter,
        address receiver,
        uint256 resourceType
    )
        external
        onlyBandwidthOrEnergy(resourceType)
        returns (uint256)
    {
        require(msg.sender != renter && msg.sender != receiver, "liquidate: not allowed to liquidate own orders");
        (uint256 income, RentalInfo memory rentInfo) = _updateMarketWithRentUser(renter, receiver, resourceType);

        _liquidateCheck(rentInfo, resourceType);

        uint256 liquidateAmount = rentInfo.amount;

        uint256 liquidateFee = 0;
        RepayResult memory repayResult = _internalRepayForLiquidate(renter, receiver, resourceType, rentInfo, liquidateFee);
        _updateRentRate(resourceType);

        income += repayResult.dirtyRent;
        _settleIncome(income);

        if (repayResult.sendBack > 0) {
            _doTransferOut(payable(renter), repayResult.sendBack);
        }

        emit ResourceReturned(renter, receiver, resourceType, liquidateAmount);
        emit Liquidate(msg.sender, renter, receiver, liquidateAmount, resourceType,
            repayResult.dirtyRent, liquidateFee, repayResult.sendBack);

        return liquidateFee;
    }

    function badDebtGap() external view returns (uint256) {
        return badDebt - badDebtCovered;
    }

    function getRentInfo(
        address renter,
        address receiver,
        uint256 resourceType
    )
        external
        view
        onlyBandwidthOrEnergy(resourceType)
        returns (uint256, uint256, bool)
    {
        RentState memory rentState = globalRentState[resourceType];
        uint256 _lastUpdateTime = uint256(rentState.lastUpdateTime);
        RentalInfo memory rentInfo = rentals(renter, receiver, resourceType);

        uint256 rate = _rentalRate(0, resourceType);

        uint256 rentIndexChange = (block.timestamp - _lastUpdateTime) * rate;
        uint256 _globalRentIndex = uint256(rentState.rentIndex) + rentIndexChange;

        if (rentInfo.amount == 0) {
            return (0, _globalRentIndex, false);
        }


        uint256 rental = (rentInfo.amount * (_globalRentIndex - rentInfo.rentIndex) + HALF_SCALE) / SCALE;
        uint256 _securityDeposit;
        if (rental >= rentInfo.securityDeposit) {
            _securityDeposit = 0;
        } else {
            _securityDeposit = rentInfo.securityDeposit - rental;
        }

        bool liquidatable;
        rate = _liquidateRate(resourceType);

        uint256 oneDayRent = rentInfo.amount * rate * 1 days / SCALE;
        uint256 threshold = rentInfo.amount * rate * liquidateThreshold / SCALE;

        uint256 _fee = _calculateFee(rentInfo.amount);
        if (_securityDeposit <= _fee + oneDayRent + threshold) {
            liquidatable = true;
        }

        return (_securityDeposit, _globalRentIndex, liquidatable);
    }

    // resourceType: 0 - bandwidth, 1 - energy
    function supportsResourceType(uint256 resourceType) external view returns (bool) {
        return resourceType == 1;
    }

    // IMarket interfaceId: 0x64f7cb8e
    // ITRC165 interfaceId: 0x01ffc9a7
    function supportsInterface(bytes4 interfaceID) public view override returns (bool) {
        return interfaceID == type(IResourceMarket).interfaceId ||
            super.supportsInterface(interfaceID);
    }

    // -------------------------------- admin management functions --------------------------------

    function setMaxRentalScaleLimit(uint256 limit) public onlyAdmin {
        require(limit <= SCALE, "setMaxRentalScaleLimit: invalid rental limit");
        maxRentalScaleLimit = limit;
    }

    function setBandwidthRentalRateModel(IRateModel model) public onlyAdmin {
        IRateModel oldRateModel = rentalRateModels[0];
        _setRateModel(0, model);

        emit BandwidthRentalRateModelUpdated(oldRateModel, model);
    }

    function setEnergyRentalRateModel(IRateModel model) public onlyAdmin {
        IRateModel oldRateModel = rentalRateModels[1];
        _setRateModel(1, model);

        emit EnergyRentalRateModelUpdated(oldRateModel, model);
    }

    function setRateModel(uint256 _resourceType, IRateModel model) public onlyAdmin onlyBandwidthOrEnergy(_resourceType) {
        if (_resourceType == 1) {
            setEnergyRentalRateModel(model);
        } else if (_resourceType == 0) {
            setBandwidthRentalRateModel(model);
        }
    }

    function setMinFee(uint256 newFee) public onlyAdmin {
        uint256 oldFee = minFee;
        minFee = newFee;

        emit MinFeeUpdated(oldFee, newFee);
    }

    function setFeeRatio(uint256 newRatio) public onlyAdmin {
        uint256 oldRatio = feeRatio;
        feeRatio = newRatio;

        emit FeeRatioUpdated(oldRatio, newRatio);
    }

    function setRentPaused(uint256 _resourceType, bool _pause) public onlyAdmin onlyBandwidthOrEnergy(_resourceType) {
        require(_resourceType == 1, "only energy rent market is implemented");
        rentPaused[_resourceType] = _pause;

        emit RentPaused(_resourceType, _pause);
    }

    function setUsageChargeRatio(uint256 ratio) public onlyAdmin {
        emit UsageChargeRatioUpdated(usageChargeRatio, ratio);

        usageChargeRatio = ratio;
    }

    function updateRentRate() public {
        _updateRentRate(0);
        _updateRentRate(1);
    }

    // -------------------------------- public view functions --------------------------------

    function totalDelegated() public view returns (uint256) {
        return address(strx).totalDelegatedResource(0) + address(strx).totalDelegatedResource(1);
    }


    function totalDelegatedOfType(uint256 resourceType) public view returns (uint256) {
        return address(strx).totalDelegatedResource(resourceType);
    }

    function totalUnfreezable() public view returns (uint256) {
        return address(strx).unfreezableBalanceV2(0) + address(strx).unfreezableBalanceV2(1);
    }

    function totalUnfreezableOfType(uint256 resourceType) public view returns (uint256) {
        return address(strx).unfreezableBalanceV2(resourceType);
    }

    function totalFrozen() public view returns (uint256) {
        return totalDelegated() + totalUnfreezable();
    }

    function totalFrozenOfType(uint256 resourceType) public view returns (uint256) {
        return totalDelegatedOfType(resourceType) + totalUnfreezableOfType(resourceType);
    }

    function delegatableOfType(uint256 resourceType) public view returns (uint256) {
        return address(strx).delegatableResource(resourceType);
    }

    function maxRentableOfType(uint256 resourceType) public view returns (uint256) {


        uint256 delegatedResource = totalDelegated();

        uint256 undelegatedResource = totalUnfreezable();

        uint256 toUnfreeze = strx.getBalanceToUnfreeze();

        uint256 _budget = (delegatedResource + undelegatedResource - toUnfreeze) * maxRentalScaleLimit / SCALE;
        if (_budget <= delegatedResource) {
            return 0;
        }
        _budget -= delegatedResource;

        uint256 _delegatable = address(strx).delegatableResource(resourceType);

        return _delegatable < _budget ? _delegatable : _budget;
    }

    function _liquidateRate(uint256 resourceType) public view returns (uint256) {
        uint256 stableRate = _stableRate(resourceType);
        uint256 currentRate = _rentalRate(0, resourceType);
        return stableRate > currentRate ? currentRate : stableRate;
    }

    function _stableRate(uint256 resourceType) public view returns (uint256) {
        RentRate memory _futureRentRate = futureRentRate[resourceType];
        if (block.timestamp >= uint256(_futureRentRate.timestamp)) {
            return uint256(_futureRentRate.rate);
        }

        RentRate memory _initialRentRate = initialRentRate[resourceType];

        uint256 sums = uint256(_initialRentRate.rate) * (uint256(_futureRentRate.timestamp) - block.timestamp)
            + uint256(_futureRentRate.rate) * (block.timestamp - uint256(_initialRentRate.timestamp));
        uint256 time_interval = uint256(_futureRentRate.timestamp - _initialRentRate.timestamp);

        return sums / time_interval;
    }

    function _rentalRate(uint256 amount, uint256 resourceType) public view returns (uint256) {
        IRateModel rateModel = rentalRateModels[resourceType];
        if (address(rateModel) == address(0x00)) {
            return 0;
        }

        return rateModel.getRentalRate(
            totalFrozenOfType(resourceType), totalDelegatedOfType(resourceType) + amount);
    }

    // -------------------------------- internal functions --------------------------------

    function _returnResource(
        address renter,
        address receiver,
        uint256 amount,
        uint256 resourceType
    )
        internal
        onlyBandwidthOrEnergy(resourceType)
        canReturn(renter, receiver, amount, resourceType)
        returns (uint256)
    {
        (uint256 income, RentalInfo memory rentInfo) = _updateMarketWithRentUser(renter, receiver, resourceType);
        uint256 prevAmount = rentInfo.amount;
        RepayResult memory repayResult;

        {
            uint256 _fee = _calculateFee(rentInfo.amount - amount);
            repayResult = _internalRepayForReturn(renter, receiver, amount, resourceType, rentInfo, _fee);
            _updateRentRate(resourceType);
        }

        emit ResourceReturned(renter, receiver, resourceType, prevAmount - rentInfo.amount);
        emit ReturnResource(renter, receiver, prevAmount - rentInfo.amount, resourceType,
            repayResult.dirtyRent, repayResult.sendBack, rentInfo.amount,
            rentInfo.securityDeposit, rentInfo.rentIndex);

        income += repayResult.dirtyRent;
        _settleIncome(income);

        if (repayResult.sendBack > 0) {
            _doTransferOut(payable(renter), repayResult.sendBack);
        }

        return repayResult.sendBack;
    }

    function _internalRepayForLiquidate(
        address renter,
        address receiver,
        uint256 resourceType,
        RentalInfo memory rentInfo,
        uint256 _fee
    )
        internal
        returns (RepayResult memory)
    {

        RepayResult memory repayResult = RepayResult(0, 0);

        (, uint256 dirtyAmount, uint256 restoreTime) =
            receiver.checkUnDelegateResource(rentInfo.amount, resourceType);
        uint256 rate = _rentalRate(0, resourceType);

        repayResult.dirtyRent = (dirtyAmount * restoreTime * usageChargeRatio / SCALE) * rate / SCALE;

        if (repayResult.dirtyRent + _fee > rentInfo.securityDeposit) {
            if (rentInfo.securityDeposit > _fee)
                repayResult.dirtyRent = rentInfo.securityDeposit - _fee;
            else
                repayResult.dirtyRent = 0;
        }

        if (repayResult.dirtyRent > 0) {
            rentInfo.securityDeposit -= repayResult.dirtyRent;
        }

        strx.marketUndelegateResource(payable(receiver), rentInfo.amount, resourceType);
        rentInfo.amount = 0;


        if (rentInfo.securityDeposit < _fee) {
            uint256 gap = _fee - rentInfo.securityDeposit;
            badDebt += gap;
            emit BadDebtAdded(gap, badDebt);
        } else {
            repayResult.sendBack = rentInfo.securityDeposit - _fee;
        }
        rentInfo.securityDeposit = 0;

        setRental(renter, receiver, resourceType, rentInfo);
        return repayResult;
    }

    function _internalRepayForReturn(
        address renter,
        address receiver,
        uint256 amount,
        uint256 resourceType,
        RentalInfo memory rentInfo,
        uint256 _fee
    )
        internal
        returns (RepayResult memory)
    {
        RepayResult memory repayResult = RepayResult(0, 0);

        (, uint256 dirtyAmount, uint256 restoreTime) =
        receiver.checkUnDelegateResource(amount, resourceType);
        uint256 rate = _rentalRate(0, resourceType);


        repayResult.dirtyRent = (dirtyAmount * restoreTime * usageChargeRatio / SCALE + amount * 3) * rate / SCALE;

        if (repayResult.dirtyRent + _fee >= rentInfo.securityDeposit) {

            if (amount < rentInfo.amount) {
                amount = rentInfo.amount;
                (, dirtyAmount, restoreTime) =
                receiver.checkUnDelegateResource(amount, resourceType);
                repayResult.dirtyRent = (dirtyAmount * restoreTime * usageChargeRatio / SCALE + amount * 3) * rate / SCALE;
            }

            if (repayResult.dirtyRent > rentInfo.securityDeposit){
                repayResult.dirtyRent = rentInfo.securityDeposit;
            }
        }

        if (repayResult.dirtyRent > 0) {
            rentInfo.securityDeposit -= repayResult.dirtyRent;
        }

        strx.marketUndelegateResource(payable(receiver), amount, resourceType);
        rentInfo.amount -= amount;


        if (rentInfo.amount == 0) {
            repayResult.sendBack = rentInfo.securityDeposit;
            rentInfo.securityDeposit = 0;
        }

        setRental(renter, receiver, resourceType, rentInfo);
        return repayResult;
    }

    function _updateMarketAndSettle(uint256 _type) internal {
        uint256 income = _updateRentIndexAndCalcIncome(_type);
        _settleIncome(income);
    }

    function _updateMarketWithRentUser(
        address user,
        address receiver,
        uint256 resourceType
    )
        internal
        returns (uint256, RentalInfo memory)
    {
        uint256 income = _updateRentIndexAndCalcIncome(resourceType);
        RentalInfo memory rentInfo = _updateUserRentIndex(user, receiver, resourceType);
        return (income, rentInfo);
    }

    function _updateRentIndexAndCalcIncome(uint256 _type) internal returns (uint256) {
        RentState memory rentState = globalRentState[_type];
        uint256 _lastUpdateTime = uint256(rentState.lastUpdateTime);
        if (block.timestamp <= _lastUpdateTime) {
            return 0;
        }

        uint256 delegated = totalDelegatedOfType(_type);

        uint256 rate = _rentalRate(0, _type);
        uint256 rentIndexChange = (block.timestamp - _lastUpdateTime) * rate;

        uint256 oldRentIndex = uint256(rentState.rentIndex);
        rentState.rentIndex = uint128(oldRentIndex + rentIndexChange);
        rentState.lastUpdateTime = uint128(block.timestamp);

        uint256 income = rentIndexChange * delegated / SCALE;

        emit RentIndex(_type, rate, oldRentIndex, uint256(rentState.rentIndex), delegated, income);

        globalRentState[_type] = rentState;
        return income;
    }


    function _updateUserRentIndex(
        address payer,
        address receiver,
        uint256 resourceType
    )
        internal
        returns (RentalInfo memory)
    {
        RentalInfo memory rentInfo = rentals(payer, receiver, resourceType);
        uint256 _globalRentIndex = uint256(globalRentState[resourceType].rentIndex);
        // TODO: require(_globalRentIndex != rentInfo.rentIndex, "multiple executions not allowed in one block");
        if (_globalRentIndex == rentInfo.rentIndex) {
            return rentInfo;
        }


        uint256 rental = (rentInfo.amount * (_globalRentIndex - rentInfo.rentIndex) + HALF_SCALE) / SCALE;
        uint256 newBadDebt;
        if (rental > rentInfo.securityDeposit) {

            newBadDebt = rental - rentInfo.securityDeposit;
            badDebt += newBadDebt;
            emit BadDebtAdded(newBadDebt, badDebt);
            rentInfo.securityDeposit = 0;
        } else {
            rentInfo.securityDeposit -= rental;
        }

        emit OrderIndex(payer, receiver, resourceType, rentInfo.rentIndex, _globalRentIndex, rentInfo.amount, rental, newBadDebt);

        rentInfo.rentIndex = _globalRentIndex;
        return rentInfo;
    }

    function _settleIncome(uint256 income) internal returns (uint256) {
        uint256 _totalRent = totalRent;
        uint256 _rentClaimed = rentClaimed;
        uint256 toClaim = _payBadDebt(income + _totalRent - _rentClaimed);

        uint256 _leftTotal = _rentClaimed + toClaim;
        if (totalRent != _leftTotal) {
            totalRent = _leftTotal;
        }
        return toClaim;
    }

    function _payBadDebt(uint256 income) internal returns (uint256) {
        if (income == 0) {
            return income;
        }

        uint256 _badDebt = badDebt;
        uint256 covered = badDebtCovered;

        if(_badDebt <= covered){
            return income;
        }

        uint256 repay = _badDebt - covered;

        if (income < repay) {
            repay = income;
        }

        income -= repay;
        covered += repay;
        badDebtCovered = covered;
        emit BadDebtCovered(repay, covered);

        return income;
    }

    function _doTransferOut(address payable to, uint256 amount) internal {
        require(address(this).balance >= amount, "market transfer: balance not enough");
        to.transfer(amount);
    }

    function _updateRentRate(uint256 resourceType) internal {
        uint256 _rate = _rentalRate(0, resourceType);
        if (_rate != uint256(futureRentRate[resourceType].rate)) {
            initialRentRate[resourceType] = RentRate(uint128(block.timestamp), uint128(_stableRate(resourceType)));
            futureRentRate[resourceType] = RentRate(uint128(block.timestamp + rateRampTime), uint128(_rate));
        }
    }

    function _setRateModel(uint256 resourceType, IRateModel model) internal {
        _updateMarketAndSettle(resourceType);

        rentalRateModels[resourceType] = model;

        _updateRentRate(resourceType);
    }

    function _calculateFee(uint256 amount) internal view returns (uint256) {
        uint256 _minFee = minFee;
        uint256 _ratioFee = amount * feeRatio / SCALE;
        return _minFee >= _ratioFee ? _minFee : _ratioFee;
    }

    function _liquidateCheck(
        RentalInfo memory rentInfo,
        uint256 resourceType
    )
        private
        view
    {
        require(rentInfo.amount > 0, "liquidate: no resource to liquidate");

        uint256 rate = _liquidateRate(resourceType);
        uint256 oneDayRent = rentInfo.amount * rate * 1 days / SCALE;
        uint256 threshold = rentInfo.amount * rate * liquidateThreshold / SCALE;

        uint256 _fee = _calculateFee(rentInfo.amount);
        require(
            rentInfo.securityDeposit <= _fee + oneDayRent + threshold,
            "liquidate: liquidate condition not met"
        );
    }

}
