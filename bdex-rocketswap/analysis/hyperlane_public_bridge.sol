// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

interface IMailbox {
    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external payable returns (bytes32);

    function quoteDispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external view returns (uint256);
}

interface IMessageRecipient {
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external payable;
}

interface IBridgeToken {
    function mintPublic(address to, uint256 amount) external;
    function burnFromPublic(address account, uint256 amount) external;
    function mintPrivate(address to, uint256 amount) external;
    function burnFromPrivate(address account, uint256 amount) external;
}

interface IERC20MetadataLike {
    function decimals() external view returns (uint8);
}

/**
 * @title HyperlaneTokenBridge
 * @notice Multi-token bridge with decimals normalization via sharedDecimals.
 */
contract HyperlaneTokenBridge is
    Initializable,
    IMessageRecipient,
    OwnableUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;
    uint8 private constant NATIVE_DECIMALS = 18;
    uint256 private constant MESSAGE_LENGTH = 128;
    uint256 public constant USE_DEFAULT_DAILY_LIMIT = 0;

    IMailbox public mailbox;
    uint256 public defaultDailyLimit;

    struct TokenConfig {
        bool enabled;
        bool isCollateral;
        address token;
        // The source-side bridge path treats `dailyLimit` as a per-transfer ceiling.
        // Destination-side settlement and pending-claim release use `current24hAmount`
        // as a cumulative 24-hour window guard on released value.
        uint256 dailyLimit;
        uint256 current24hAmount;
        uint256 lastReset;
    }

    mapping(bytes32 => TokenConfig) private tokenConfigs;
    mapping(bytes32 => mapping(uint32 => bytes32)) public remoteRouters;

    struct TokenDecimalsConfig {
        bool configured;
        uint8 localDecimals;
        uint8 sharedDecimals;
    }

    mapping(bytes32 => TokenDecimalsConfig) private tokenDecimalsConfigs;
    mapping(bytes32 => mapping(address => uint256)) private pendingClaims;
    mapping(address => bool) public whitelist;
    bool public isPrivateBridge;
    bool public whitelistEnabled;
    uint8 public constant MESSAGE_VERSION = 1;

    // --- Events ---
    event TokenRegistered(bytes32 indexed tokenId, address indexed token, bool isCollateral, uint256 dailyLimit);
    event TokenEnabled(bytes32 indexed tokenId, bool enabled);
    event BridgeSent(bytes32 indexed tokenId, address indexed sender, uint32 indexed dstDomain, bytes32 recipient, uint256 amount);
    event BridgeReceived(bytes32 indexed tokenId, address indexed recipient, uint32 indexed origin, uint256 amount);
    event RemoteRouterSet(bytes32 indexed tokenId, uint32 indexed domain, bytes32 router);
    event TokenDailyLimitChanged(bytes32 indexed tokenId, uint256 newLimit);
    event TokenDecimalsConfigured(bytes32 indexed tokenId, uint8 localDecimals, uint8 sharedDecimals);
    event AmountRounded(bytes32 indexed tokenId, uint256 amountLocal, uint256 amountShared, uint256 dustLocal);
    event NativeLocked(
        bytes32 indexed tokenId,
        address indexed sender,
        uint32 indexed dstDomain,
        bytes32 recipient,
        uint256 amount
    );
    event NativeReleased(bytes32 indexed tokenId, address indexed recipient, uint256 amount);
    event PendingClaimRecorded(bytes32 indexed tokenId, address indexed account, uint32 indexed origin, uint256 amount);
    event PendingClaimPaid(bytes32 indexed tokenId, address indexed account, address indexed recipient, uint256 amount);
    event PendingClaimRecovered(
        bytes32 indexed tokenId,
        address indexed account,
        address indexed recipient,
        address operator,
        uint256 amount
    );
    event BridgeModeConfigured(bool indexed isPrivateBridge);
    event WhitelistStatusChanged(bool indexed enabled);
    event WhitelistUpdated(address indexed account, bool indexed allowed);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier onlyMailbox() {
        require(msg.sender == address(mailbox), "Only mailbox");
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "Only self");
        _;
    }

    function initialize(address _mailbox, uint256 _defaultDailyLimit, bool _isPrivateBridge) public initializer {
        require(_mailbox != address(0), "Invalid mailbox");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        mailbox = IMailbox(_mailbox);
        defaultDailyLimit = _defaultDailyLimit;
        isPrivateBridge = _isPrivateBridge;
        whitelistEnabled = _isPrivateBridge;

        emit BridgeModeConfigured(_isPrivateBridge);
        emit WhitelistStatusChanged(whitelistEnabled);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // --- Configuration ---

    function registerToken(
        bytes32 _tokenId,
        address _token,
        bool _isCollateral,
        uint256 _dailyLimit
    ) external onlyOwner {
        require(_tokenId != bytes32(0), "Invalid tokenId");
        require(!_isRegistered(_tokenId), "Token already registered");
        if (!_isCollateral) {
            require(_token != address(0), "Invalid token");
        }
        TokenConfig storage cfg = tokenConfigs[_tokenId];
        cfg.enabled = true;
        cfg.isCollateral = _isCollateral;
        cfg.token = _token;
        cfg.dailyLimit = _resolveDailyLimit(_dailyLimit);
        cfg.current24hAmount = 0;
        cfg.lastReset = 0;
        emit TokenRegistered(_tokenId, _token, _isCollateral, cfg.dailyLimit);
    }

    function setTokenEnabled(bytes32 _tokenId, bool _enabled) external onlyOwner {
        require(_isRegistered(_tokenId), "Token not registered");
        tokenConfigs[_tokenId].enabled = _enabled;
        emit TokenEnabled(_tokenId, _enabled);
    }

    function setWhitelistEnabled(bool _enabled) external onlyOwner {
        whitelistEnabled = _enabled;
        emit WhitelistStatusChanged(_enabled);
    }

    function setWhitelisted(address _account, bool _allowed) external onlyOwner {
        require(_account != address(0), "Invalid account");
        whitelist[_account] = _allowed;
        emit WhitelistUpdated(_account, _allowed);
    }

    function setWhitelistedBatch(address[] calldata _accounts, bool _allowed) external onlyOwner {
        uint256 length = _accounts.length;
        for (uint256 i = 0; i < length; ++i) {
            address account = _accounts[i];
            require(account != address(0), "Invalid account");
            whitelist[account] = _allowed;
            emit WhitelistUpdated(account, _allowed);
        }
    }

    function setTokenDailyLimit(bytes32 _tokenId, uint256 _limit) external onlyOwner {
        require(_isRegistered(_tokenId), "Token not registered");
        uint256 resolvedLimit = _resolveDailyLimit(_limit);
        tokenConfigs[_tokenId].dailyLimit = resolvedLimit;
        emit TokenDailyLimitChanged(_tokenId, resolvedLimit);
    }

    /// @dev Remote routers must be peer bridge contracts that encode messages with
    ///      `abi.encode(uint8, bytes32, bytes32, uint256)` using `MESSAGE_VERSION`.
    function setRemoteRouter(bytes32 _tokenId, uint32 _domain, bytes32 _router) external onlyOwner {
        require(_isRegistered(_tokenId), "Token not registered");
        remoteRouters[_tokenId][_domain] = _router;
        emit RemoteRouterSet(_tokenId, _domain, _router);
    }

    function setPause(bool _status) external onlyOwner {
        if (_status) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setTokenDecimalsConfig(
        bytes32 _tokenId,
        uint8 _localDecimals,
        uint8 _sharedDecimals
    ) external onlyOwner {
        require(_isRegistered(_tokenId), "Token not registered");
        uint8 onchainLocal = _localDecimalsForToken(_tokenId);
        require(_localDecimals == onchainLocal, "localDecimals mismatch");
        _setTokenDecimalsConfig(_tokenId, _localDecimals, _sharedDecimals);
    }

    function autoSetTokenDecimalsConfig(
        bytes32 _tokenId,
        uint8 _sharedDecimals
    ) external onlyOwner {
        require(_isRegistered(_tokenId), "Token not registered");
        uint8 local = _localDecimalsForToken(_tokenId);
        _setTokenDecimalsConfig(_tokenId, local, _sharedDecimals);
    }

    function getTokenDecimalsConfig(bytes32 _tokenId)
        external
        view
        returns (bool configured, uint8 localDecimals, uint8 sharedDecimals)
    {
        TokenDecimalsConfig storage d = tokenDecimalsConfigs[_tokenId];
        return (d.configured, d.localDecimals, d.sharedDecimals);
    }

    // --- Bridge logic ---

    /// @notice Backward-compatible bridge entrypoint.
    /// @dev The fee portion of `msg.value` is treated as the caller's maximum mailbox fee budget.
    ///      Production integrations should prefer `bridgeWithMaxFee(...)` for an explicit bound.
    ///      This bridge assumes the configured mailbox returns a quote compatible with `dispatch(...)`
    ///      for identical parameters.
    function bridge(bytes32 _tokenId, uint32 _destDomain, bytes32 _recipient, uint256 _amount) external payable whenNotPaused nonReentrant {
        _bridge(_tokenId, _destDomain, _recipient, _amount, _legacyBridgeMaxFee(_tokenId, _amount));
    }

    function bridgeWithMaxFee(
        bytes32 _tokenId,
        uint32 _destDomain,
        bytes32 _recipient,
        uint256 _amount,
        uint256 _maxFee
    ) external payable whenNotPaused nonReentrant {
        _bridge(_tokenId, _destDomain, _recipient, _amount, _maxFee);
    }

    function handle(uint32 _origin, bytes32 _sender, bytes calldata _message) external payable override onlyMailbox whenNotPaused nonReentrant {
        require(msg.value == 0, "Unexpected ETH");
        (bytes32 tokenId, bytes32 recipientBytes, uint256 amountShared) = _decodeBridgeMessage(_message);
        _requireCanonicalRecipient(recipientBytes);
        _requireValidDecimalsConfig(tokenId);
        uint256 amountLocal = _toLocalAmount(tokenId, amountShared);

        TokenConfig storage cfg = tokenConfigs[tokenId];
        require(cfg.enabled, "Token disabled");
        require(_isRegistered(tokenId), "Token not registered");
        require(_sender == remoteRouters[tokenId][_origin], "Invalid remote router");

        address recipient = address(uint160(uint256(recipientBytes)));
        _resetDailyUsageIfNeeded(cfg);

        if (cfg.current24hAmount + amountLocal > cfg.dailyLimit) {
            pendingClaims[tokenId][recipient] += amountLocal;
            emit PendingClaimRecorded(tokenId, recipient, _origin, amountLocal);
            return;
        }

        if (_deliver(tokenId, cfg, recipient, amountLocal)) {
            cfg.current24hAmount += amountLocal;
            emit BridgeReceived(tokenId, recipient, _origin, amountLocal);
            return;
        }

        pendingClaims[tokenId][recipient] += amountLocal;
        emit PendingClaimRecorded(tokenId, recipient, _origin, amountLocal);
    }

    function quoteBridge(bytes32 _tokenId, uint32 _destDomain, bytes32 _recipient, uint256 _amount) external view returns (uint256) {
        TokenConfig storage cfg = tokenConfigs[_tokenId];
        require(cfg.enabled, "Token disabled");
        require(_isRegistered(_tokenId), "Token not registered");
        require(remoteRouters[_tokenId][_destDomain] != bytes32(0), "Remote router not set");
        require(_amount > 0, "Amount must be > 0");
        _requireCanonicalRecipient(_recipient);
        if (whitelistEnabled) {
            _requireWhitelistedRecipient(_recipient);
        }
        _requireValidDecimalsConfig(_tokenId);
        bytes memory message = _buildOutboundMessageView(_tokenId, _recipient, _amount);
        return mailbox.quoteDispatch(_destDomain, remoteRouters[_tokenId][_destDomain], message);
    }

    function getToken(bytes32 _tokenId) external view returns (
        bool enabled,
        bool isCollateral,
        address token,
        uint256 dailyLimit,
        uint256 current24hAmount,
        uint256 lastReset
    ) {
        TokenConfig storage cfg = tokenConfigs[_tokenId];
        return (
            cfg.enabled,
            cfg.isCollateral,
            cfg.token,
            cfg.dailyLimit,
            cfg.current24hAmount,
            cfg.lastReset
        );
    }

    function isTokenRegistered(bytes32 _tokenId) external view returns (bool) {
        return _isRegistered(_tokenId);
    }

    function getPendingClaim(bytes32 _tokenId, address _account) external view returns (uint256) {
        return pendingClaims[_tokenId][_account];
    }

    function claimPending(bytes32 _tokenId, address _recipient) external whenNotPaused nonReentrant {
        _settlePendingClaim(_tokenId, msg.sender, _recipient, pendingClaims[_tokenId][msg.sender]);
    }

    function claimPending(bytes32 _tokenId, address _recipient, uint256 _amount) external whenNotPaused nonReentrant {
        _settlePendingClaim(_tokenId, msg.sender, _recipient, _amount);
    }

    function recoverPendingClaim(
        bytes32 _tokenId,
        address _account,
        address _recipient,
        uint256 _amount
    ) external onlyOwner whenPaused nonReentrant {
        _settlePendingClaim(_tokenId, _account, _recipient, _amount);
        emit PendingClaimRecovered(_tokenId, _account, _recipient, msg.sender, _amount);
    }

    function getTokenDailyLimitState(bytes32 _tokenId)
        external
        view
        returns (uint256 dailyLimit, uint256 currentWindowAmount, uint256 remainingDailyCapacity, uint256 lastReset)
    {
        TokenConfig storage cfg = tokenConfigs[_tokenId];
        (currentWindowAmount, lastReset) = _currentDailyUsage(cfg);
        dailyLimit = cfg.dailyLimit;
        remainingDailyCapacity = dailyLimit > currentWindowAmount ? dailyLimit - currentWindowAmount : 0;
    }

    function getNativeCollateralHealth(bytes32 _tokenId)
        external
        view
        returns (
            bool enabled,
            bool isNativeCollateral,
            uint256 bridgeBalance,
            uint256 dailyLimit,
            uint256 current24hAmount,
            uint256 remainingDailyCapacity
        )
    {
        TokenConfig storage cfg = tokenConfigs[_tokenId];
        enabled = cfg.enabled;
        isNativeCollateral = _isNativeCollateral(cfg);
        bridgeBalance = isNativeCollateral ? address(this).balance : 0;
        dailyLimit = cfg.dailyLimit;
        (current24hAmount, ) = _currentDailyUsage(cfg);
        remainingDailyCapacity = dailyLimit > current24hAmount ? dailyLimit - current24hAmount : 0;
    }

    function canReleaseNative(bytes32 _tokenId, uint256 _amount)
        external
        view
        returns (bool ok, uint256 bridgeBalance)
    {
        TokenConfig storage cfg = tokenConfigs[_tokenId];
        require(_isNativeCollateral(cfg), "Token is not native collateral");
        bridgeBalance = address(this).balance;
        ok = bridgeBalance >= _amount;
    }

    // --- Internal helpers ---

    function deliverNativeToRecipient(address _recipient, uint256 _amount) external onlySelf {
        (bool ok, ) = payable(_recipient).call{value: _amount}("");
        require(ok, "Native transfer failed");
    }

    function deliverCollateralToRecipient(address _token, address _recipient, uint256 _amount) external onlySelf {
        uint256 bridgeBefore = IERC20(_token).balanceOf(address(this));
        uint256 recipientBefore = IERC20(_token).balanceOf(_recipient);
        IERC20(_token).safeTransfer(_recipient, _amount);
        uint256 bridgeAfter = IERC20(_token).balanceOf(address(this));
        uint256 recipientAfter = IERC20(_token).balanceOf(_recipient);
        require(bridgeAfter <= bridgeBefore, "Bridge balance invariant");
        require(recipientAfter >= recipientBefore, "Recipient balance invariant");

        uint256 debited = bridgeBefore - bridgeAfter;
        uint256 received = recipientAfter - recipientBefore;
        require(received == _amount, "Recipient delta mismatch");
        require(debited == _amount, "Bridge debit mismatch");
    }

    function mintSyntheticToRecipient(address _token, address _recipient, uint256 _amount) external onlySelf {
        if (isPrivateBridge) {
            IBridgeToken(_token).mintPrivate(_recipient, _amount);
        } else {
            IBridgeToken(_token).mintPublic(_recipient, _amount);
        }
    }

    function _bridge(
        bytes32 _tokenId,
        uint32 _destDomain,
        bytes32 _recipient,
        uint256 _amount,
        uint256 _maxFee
    ) internal {
        _requireCanonicalRecipient(_recipient);
        if (whitelistEnabled) {
            require(whitelist[msg.sender], "Sender not whitelisted");
            _requireWhitelistedRecipient(_recipient);
        }
        TokenConfig storage cfg = tokenConfigs[_tokenId];
        require(cfg.enabled, "Token disabled");
        require(_isRegistered(_tokenId), "Token not registered");
        require(remoteRouters[_tokenId][_destDomain] != bytes32(0), "Remote router not set");
        require(_amount > 0, "Amount must be > 0");
        require(_amount <= cfg.dailyLimit, "Amount exceeds outbound per-tx limit");
        _requireValidDecimalsConfig(_tokenId);

        bool isNative = _isNativeCollateral(cfg);
        bytes memory message = _buildOutboundMessage(_tokenId, _recipient, _amount);
        uint256 totalFee = mailbox.quoteDispatch(_destDomain, remoteRouters[_tokenId][_destDomain], message);
        require(totalFee <= _maxFee, "Bridge fee exceeds max");

        if (isNative) {
            require(msg.value >= totalFee + _amount, "Insufficient native value");
            emit NativeLocked(_tokenId, msg.sender, _destDomain, _recipient, _amount);
        } else if (cfg.isCollateral) {
            uint256 beforeBalance = IERC20(cfg.token).balanceOf(address(this));
            IERC20(cfg.token).safeTransferFrom(msg.sender, address(this), _amount);
            uint256 received = IERC20(cfg.token).balanceOf(address(this)) - beforeBalance;
            require(received == _amount, "Fee-on-transfer unsupported");
        } else {
            if (isPrivateBridge) {
                IBridgeToken(cfg.token).burnFromPrivate(msg.sender, _amount);
            } else {
                IBridgeToken(cfg.token).burnFromPublic(msg.sender, _amount);
            }
        }

        if (!isNative) {
            require(msg.value >= totalFee, "Insufficient fee");
        }

        mailbox.dispatch{value: totalFee}(_destDomain, remoteRouters[_tokenId][_destDomain], message);

        uint256 consumed = totalFee + (isNative ? _amount : 0);
        if (msg.value > consumed) {
            uint256 refund = msg.value - consumed;
            (bool ok, ) = payable(msg.sender).call{value: refund}("");
            require(ok, "Refund transfer failed");
        }

        emit BridgeSent(_tokenId, msg.sender, _destDomain, _recipient, _amount);
    }

    /// @dev Remote peer bridges must emit messages using this exact ABI encoding.
    function _encodeBridgeMessage(bytes32 _tokenId, bytes32 _recipient, uint256 _amountShared) internal pure returns (bytes memory) {
        return abi.encode(MESSAGE_VERSION, _tokenId, _recipient, _amountShared);
    }

    function _decodeBridgeMessage(bytes calldata _message)
        internal
        pure
        returns (bytes32 tokenId, bytes32 recipientBytes, uint256 amountShared)
    {
        require(_message.length == MESSAGE_LENGTH, "Invalid message length");
        (uint8 version, bytes32 decodedTokenId, bytes32 decodedRecipientBytes, uint256 decodedAmountShared) =
            abi.decode(_message, (uint8, bytes32, bytes32, uint256));
        require(version == MESSAGE_VERSION, "Unsupported message version");
        return (decodedTokenId, decodedRecipientBytes, decodedAmountShared);
    }

    function _settlePendingClaim(bytes32 _tokenId, address _account, address _recipient, uint256 _amount) internal {
        require(_account != address(0), "Invalid account");
        require(_recipient != address(0), "Invalid recipient");
        require(_recipient != address(this), "Bridge self recipient");

        uint256 claimable = pendingClaims[_tokenId][_account];
        require(claimable > 0, "No pending claim");
        require(_amount > 0 && _amount <= claimable, "Invalid claim amount");

        TokenConfig storage cfg = tokenConfigs[_tokenId];
        require(_isRegistered(_tokenId), "Token not registered");

        _resetDailyUsageIfNeeded(cfg);
        require(cfg.current24hAmount + _amount <= cfg.dailyLimit, "Daily limit exceeded");

        pendingClaims[_tokenId][_account] = claimable - _amount;
        bool delivered = _deliver(_tokenId, cfg, _recipient, _amount);
        if (!delivered) {
            pendingClaims[_tokenId][_account] = claimable;
            revert("Pending claim delivery failed");
        }

        cfg.current24hAmount += _amount;
        emit PendingClaimPaid(_tokenId, _account, _recipient, _amount);
    }

    function _buildOutboundMessage(bytes32 _tokenId, bytes32 _recipient, uint256 _amountLocal) internal returns (bytes memory) {
        TokenDecimalsConfig storage d = tokenDecimalsConfigs[_tokenId];
        require(d.configured, "Token decimals not configured");
        uint256 amountShared = _toSharedAmount(_tokenId, _amountLocal, d);
        return _encodeBridgeMessage(_tokenId, _recipient, amountShared);
    }

    function _buildOutboundMessageView(bytes32 _tokenId, bytes32 _recipient, uint256 _amountLocal) internal view returns (bytes memory) {
        TokenDecimalsConfig storage d = tokenDecimalsConfigs[_tokenId];
        require(d.configured, "Token decimals not configured");
        uint256 amountShared = _toSharedAmountView(_amountLocal, d);
        return _encodeBridgeMessage(_tokenId, _recipient, amountShared);
    }

    function _toSharedAmount(bytes32 _tokenId, uint256 _amountLocal, TokenDecimalsConfig storage d) internal returns (uint256) {
        if (d.localDecimals == d.sharedDecimals) return _amountLocal;
        uint8 diff = d.localDecimals - d.sharedDecimals;
        uint256 factor = 10 ** diff;
        uint256 amountShared = _amountLocal / factor;
        uint256 dust = _amountLocal % factor;
        if (dust > 0) {
            emit AmountRounded(_tokenId, _amountLocal, amountShared, dust);
        }
        return amountShared;
    }

    function _toSharedAmountView(uint256 _amountLocal, TokenDecimalsConfig storage d) internal view returns (uint256) {
        if (d.localDecimals == d.sharedDecimals) return _amountLocal;
        uint8 diff = d.localDecimals - d.sharedDecimals;
        uint256 factor = 10 ** diff;
        return _amountLocal / factor;
    }

    function _toLocalAmount(bytes32 _tokenId, uint256 _amountShared) internal view returns (uint256) {
        TokenDecimalsConfig storage d = tokenDecimalsConfigs[_tokenId];
        require(d.configured, "Token decimals not configured");
        if (d.localDecimals == d.sharedDecimals) return _amountShared;
        uint8 diff = d.localDecimals - d.sharedDecimals;
        return _amountShared * (10 ** diff);
    }

    function _isNativeCollateral(TokenConfig storage cfg) internal view returns (bool) {
        return cfg.isCollateral && cfg.token == address(0);
    }

    function _deliver(
        bytes32 _tokenId,
        TokenConfig storage cfg,
        address _recipient,
        uint256 _amount
    ) internal returns (bool) {
        if (_isNativeCollateral(cfg)) {
            try this.deliverNativeToRecipient(_recipient, _amount) {
                emit NativeReleased(_tokenId, _recipient, _amount);
                return true;
            } catch {
                return false;
            }
        }

        if (cfg.isCollateral) {
            try this.deliverCollateralToRecipient(cfg.token, _recipient, _amount) {
                return true;
            } catch {
                return false;
            }
        }

        try this.mintSyntheticToRecipient(cfg.token, _recipient, _amount) {
            return true;
        } catch {
            return false;
        }
    }

    function _isRegistered(bytes32 _tokenId) internal view returns (bool) {
        TokenConfig storage cfg = tokenConfigs[_tokenId];
        return cfg.isCollateral || cfg.token != address(0);
    }

    function _localDecimalsForToken(bytes32 _tokenId) internal view returns (uint8) {
        TokenConfig storage cfg = tokenConfigs[_tokenId];
        if (_isNativeCollateral(cfg)) {
            return NATIVE_DECIMALS;
        }
        return IERC20MetadataLike(cfg.token).decimals();
    }

    function _requireValidDecimalsConfig(bytes32 _tokenId) internal view {
        TokenDecimalsConfig storage d = tokenDecimalsConfigs[_tokenId];
        require(d.configured, "Token decimals not configured");
        require(d.localDecimals == _localDecimalsForToken(_tokenId), "Token decimals changed");
    }

    function _setTokenDecimalsConfig(bytes32 _tokenId, uint8 _localDecimals, uint8 _sharedDecimals) internal {
        require(_sharedDecimals <= _localDecimals, "sharedDecimals > localDecimals not supported");
        tokenDecimalsConfigs[_tokenId] = TokenDecimalsConfig({
            configured: true,
            localDecimals: _localDecimals,
            sharedDecimals: _sharedDecimals
        });
        emit TokenDecimalsConfigured(_tokenId, _localDecimals, _sharedDecimals);
    }

    function _resolveDailyLimit(uint256 _dailyLimit) internal view returns (uint256) {
        return _dailyLimit == USE_DEFAULT_DAILY_LIMIT ? defaultDailyLimit : _dailyLimit;
    }

    function _requireCanonicalRecipient(bytes32 _recipient) internal view {
        require(_recipient != bytes32(0) && (uint256(_recipient) >> 160) == 0, "Invalid recipient");
        require(address(uint160(uint256(_recipient))) != address(this), "Bridge self recipient");
    }

    function _requireWhitelistedRecipient(bytes32 _recipient) internal view {
        require(whitelist[address(uint160(uint256(_recipient)))], "Recipient not whitelisted");
    }

    function _legacyBridgeMaxFee(bytes32 _tokenId, uint256 _amount) internal returns (uint256) {
        TokenConfig storage cfg = tokenConfigs[_tokenId];
        if (_isNativeCollateral(cfg)) {
            require(msg.value >= _amount, "Insufficient native value");
            return msg.value - _amount;
        }
        return msg.value;
    }

    function _resetDailyUsageIfNeeded(TokenConfig storage cfg) internal {
        if (block.timestamp > cfg.lastReset + 1 days) {
            cfg.current24hAmount = 0;
            cfg.lastReset = block.timestamp;
        }
    }

    function _currentDailyUsage(TokenConfig storage cfg) internal view returns (uint256 current24hAmount, uint256 lastReset) {
        if (block.timestamp > cfg.lastReset + 1 days) {
            return (0, block.timestamp);
        }
        return (cfg.current24hAmount, cfg.lastReset);
    }
}
