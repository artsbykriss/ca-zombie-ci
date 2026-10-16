// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {Bip340NaiveLib} from "./Bip340NaiveLib.sol";
import {Bip340Util} from "bip340-solidity/Bip340Util.sol";
import {Secp256k1} from "bip340-solidity/Secp256k1.sol";
import {IMultiAssetStrategy} from "./interfaces/IMultiAssetStrategy.sol";

/// @title VaultImpl
/// @notice A MULTI-ASSET custody vault backing a Bitcoin-native fr-asset (frUSD,
///         frETH, …). It custodies several ERC20s (USDC and USDT today) under one
///         contract, each named by the `assetId` a Bitcoin-side burn carries, and
///         releases them EXCLUSIVELY under a FROST (BIP340) group signature. The
///         fr-asset is a Bitcoin alkane — there is NO ERC20 fr-asset here, and no
///         EVM mint/burn.
///
/// @dev UPGRADE MODEL: UUPS behind a single `ERC1967Proxy`.
///
///      `_authorizeUpgrade` is `onlyAuth`, so replacing the implementation takes
///      exactly the authority that already moves the money: a FROST signature
///      over the calldata, bound to this address, the chain id and `authNonce`,
///      submitted through `authenticatedCall`. There is no second key, no
///      separate admin contract and no second verifier — the upgrade path and
///      the withdrawal path are the same gate.
///
///      This REPLACES the previous beacon topology (`FrostBeacon` + one
///      `BeaconProxy` per asset). That shape existed to share one implementation
///      across several single-asset vaults; with one vault holding every asset
///      there is nothing left to share, and the beacon only added a second
///      upgrade authority that — as deployed — held the same key, so a single
///      compromise granted both withdrawal AND arbitrary implementation
///      replacement.
///
///      Two bridge directions (the asset is named by `assetId`, resolved HERE):
///        * IN  — `depositAndBridge(assetId, amount, bridgeData)`: lock the asset,
///                emit `PaymentQueued`; the coordinator mints on Bitcoin.
///        * OUT — `withdrawFromBridge(bridgeNonce, assetId, amount, target, script)`:
///                release the asset against a Bitcoin burn. FROST-gated
///                (`onlyAuth`) + at-most-once per burn (`usedBridgeNonce`).
///
///      STORAGE: `Initializable` (ERC-7201), `ReentrancyGuard` (computed slot) and
///      `UUPSUpgradeable` (none) all declare NO sequential storage, so the layout
///      below starts at slot 0 and the inheritance list does not shift it. Pinned
///      by `test_AUDIT_StorageLayoutIsPinned`.
contract VaultImpl is
    Initializable,
    ReentrancyGuard,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    /// @notice A queued bridge-in: asset locked here -> fr-asset minted on Bitcoin.
    ///
    /// This is the ONE payment record — stored in `payments` and returned
    /// verbatim by `getUnprocessedPayments`, so the coordinator reads exactly
    /// what the vault holds and there is no second shape to keep in sync.
    ///
    /// `frAmount` is stored rather than derived on read: it fixes the 6->8
    /// scaling at the instant of the deposit, so a later change to
    /// `assetDecimals` can never retroactively restate what a queued deposit is
    /// owed. `paymentId` is the index, carried inline so a record stays
    /// self-identifying once it has been copied out of the array.
    ///
    /// Field order is chosen for packing: `timestamp` (64) + `depositor` (160)
    /// + `processed` (8) = 232 bits share one slot, so carrying the two extra
    /// fields costs no more storage than the five-field version did.
    ///
    /// NOTE: there is deliberately no transaction hash here — Solidity cannot
    /// observe its own txid. The coordinator's at-most-once key is
    /// (this vault's address, `paymentId`).
    struct Payment {
        uint256 paymentId;   // index into `payments`
        uint256 assetAmount; // NET asset locked (after fee), in the asset's own base units
        uint256 frAmount;    // the same value in 8-dec fr-asset base units
        uint64 timestamp;    // when payment was queued
        address depositor;   // who initiated the bridge
        uint8 assetId;       // which registered asset was deposited
        bytes bridgeData;    // opaque, coordinator-interpreted (see bridge_data.proto)
    }

    /// @notice The ERC20s this vault custodies, indexed by asset id.
    ///
    /// The id is what a Bitcoin-side burn names (0 = USDC, 1 = USDT), and the
    /// vault resolves it HERE. That direction matters: if the coordinator mapped
    /// ids to addresses from its own config, a misconfigured manifest would pay
    /// out the wrong token under a valid FROST signature.
    mapping(uint8 => IERC20) public assets;

    /// @notice Decimals of each registered asset, captured at registration.
    mapping(uint8 => uint8) public assetDecimalsOf;

    /// @notice Whether an id has been registered (0 is a valid id, so a null
    /// address check alone cannot distinguish "unset" from "id 0").
    mapping(uint8 => bool) public assetRegistered;

    /// @notice Highest registered id + 1, for enumeration.
    uint8 public assetCount;

    /// @notice The authorized Schnorr public key (the FROST group). Gates every onlyAuth op.
    /// @dev BIP340 verification is done in-contract via the inlined `Bip340NaiveLib`
    /// (full-coordinate, compares the actual 256-bit x(R)==rx — B4 audit). No separate
    /// verifier contract; the verifier travels with the impl (fixable via a beacon upgrade).
    bytes32 public defaultPublicKey;

    /// @notice Nonce for authenticated operations (monotonic).
    uint256 public authNonce;

    /// @notice Protocol fee in basis points (100 = 1%, 10 = 0.1%).
    uint256 public protocolFeeBps;

    /// @notice Flat fee charged once per bridge-in and once per bridge-out, in
    /// THIS VAULT'S ASSET UNITS (e.g. 1_990_000 = $1.99 of 6-dec USDC).
    ///
    /// Denominated in asset units, not USD, so the contract never needs a price
    /// feed. For a volatile asset the operator re-prices it with `setFlatFee`.
    /// It is charged in ADDITION to `protocolFeeBps`, and both accrue to
    /// `feesCollected`.
    uint256 public flatFee;

    /// @notice Fee recipient address.
    address public feeRecipient;

    /// @notice Optional yield strategy, shared by every registered asset
    /// (null-guarded). Asset-aware: see `IMultiAssetStrategy`.
    IMultiAssetStrategy public strategy;

    /// @notice NET asset committed to not-yet-settled bridge-ins, per asset.
    mapping(uint8 => uint256) public pending;

    /// @notice Asset deployed to the strategy, per asset.
    mapping(uint8 => uint256) public inStrategy;

    /// @notice Protocol fees accrued, per asset.
    mapping(uint8 => uint256) public feesCollected;

    /// @notice Queue of bridge-in payments.
    Payment[] public payments;

    /// @notice B2 (audit): on-chain at-most-once anchor for the reverse bridge.
    /// Keyed by the Bitcoin burn's on-chain `bridge_id` (unique per burn). A second
    /// withdrawFromBridge for the same burn reverts, independent of coordinator
    /// liveness/ordering/restart or a reorg re-mining the burn.
    mapping(uint256 => bool) public usedBridgeNonce;

    /// @notice Highest burn nonce paid out, + 1 — where the coordinator resumes.
    ///
    /// Symmetric with the alkane's `/next_payment_id`: the chain that PERFORMS
    /// the action records that it happened, so neither side needs an
    /// acknowledgement round-trip. `usedBridgeNonce` stays as the actual
    /// at-most-once guard — this is only a scan hint, and replacing the map with
    /// it would lose per-nonce replay protection.
    ///
    /// Stores next-not-last for the same reason the alkane does: nonces start at
    /// 0, so a "last paid" of 0 is indistinguishable from "nothing paid".
    uint256 public nextBurnNonce;

    /// @notice Addresses permitted to SUBMIT an authenticated call.
    ///
    /// This is a liveness/anti-grief control, NOT an authority over funds. What
    /// may happen is decided entirely by the BIP340 signature, which commits to
    /// the calldata, its order, the nonce and this vault; a relayer can only
    /// choose whether and when to submit a payload it cannot alter.
    ///
    /// The reason to gate it at all: without this, anyone watching the mempool
    /// can copy a signed payload and land it first. The signature is nonce-bound,
    /// so their transaction succeeds and the real relayer's then reverts on
    /// `InvalidNonce`, wasting its gas. Repeated, that is a cheap way to drain a
    /// relayer while the bridge appears merely slow.
    mapping(address => bool) public isRelayer;

    /// @notice May add and remove relayers. Set to the deployer at initialize.
    ///
    /// Deliberately SEPARATE from the FROST authority, and deliberately unable to
    /// move money. Gating the submit path makes it a liveness dependency, so
    /// there must be a way back when a relayer key is lost — and `onlyAuth`
    /// alone cannot provide one, because an `onlyAuth` call has to be submitted
    /// through the very path that is gated. That is a deadlock. This admin is
    /// the independent second path; the FROST group can also manage the set.
    address public relayerAdmin;

    /// @notice How many relayers are currently authorised.
    ///
    /// The gate must open when this reaches zero (see `onlyRelayer`), and a
    /// mapping cannot be enumerated, so the count is tracked explicitly.
    ///
    /// APPENDED, not inserted. Placing it above `relayerAdmin` — which the first
    /// attempt did — moves that field from slot 13 to 14 and silently corrupts
    /// every upgraded proxy. `test_AUDIT_StorageLayoutIsPinned` caught it.
    uint256 public relayerCount;

    /// @notice Per asset: idle balance below which an incoming deposit is NOT
    /// swept to the strategy. `0` = sweep every deposit.
    ///
    /// A sweep is a real position entry — an `add_liquidity` into a Curve pool,
    /// hundreds of thousands of gas. Charging that to every `depositAndBridge`
    /// makes a small deposit uneconomic and buys a dust LP position for it.
    /// Holding until the idle balance clears this bar batches many deposits into
    /// one entry; `depositToStrategy` always flushes regardless.
    ///
    /// PER ASSET because the value is denominated in the asset's own base units,
    /// and this vault registers assets with different decimals (6-dec USDC/USDT,
    /// 18-dec WETH). One scalar would mean "$1000" for one asset and 1e-15 of a
    /// unit for another. Defaulted at registration, see `_registerAsset`.
    ///
    /// APPENDED, and `__gap` shrunk to match — see the note on `relayerCount`.
    mapping(uint8 => uint256) public minSweep;

    /// @notice Per asset: granularity of a strategy pull, in the asset's units.
    ///
    /// A payout sources from the idle balance first and only asks the strategy
    /// for the shortfall — but that ask is an exit from the position
    /// (`remove_liquidity_one_coin`), and it costs the same whether it pulls $10
    /// or $1000. Paying it once per small withdrawal is the expensive shape.
    ///
    /// So the shortfall is rounded UP to a multiple of this, and the excess
    /// stays idle in the vault where the NEXT withdrawals can be served with a
    /// plain `transfer`. One expensive exit amortizes over many cheap payouts.
    ///
    /// The cost is that the excess is out of the position and stops earning
    /// until it is either paid out or re-swept, so this trades a little yield
    /// for a lot of gas. `0` (or 1) disables rounding and pulls exactly what is
    /// needed.
    mapping(uint8 => uint256) public withdrawChunk;

    /// @dev Storage gap so future appends don't shift layout across impl upgrades.
    /// Reduced from 45 as fields were appended above — the SUM must stay constant
    /// or an upgrade shifts every slot after it.
    uint256[40] private __gap;

    /// @dev The fr-asset on Bitcoin is 8-decimal (Alkanes-aligned). `assetDecimals`
    /// is captured at initialize so 6-dec (USDC/USDT ->x100) and 18-dec (WETH ->/1e10)
    /// assets convert correctly; see `_toFrAmount`.
    uint8 private constant FR_DECIMALS = 8;

    /// @dev Default `minSweep` and `withdrawChunk`, in WHOLE units of the asset,
    /// applied at registration. 1000 units of a 6-dec stablecoin is $1000 —
    /// large enough that one Curve entry/exit is amortized over a meaningful
    /// balance, small enough that little value sits idle.
    ///
    /// For a non-USD asset this default is denominated in that asset, so 1000
    /// WETH is not a sane bar and the operator must re-price it with
    /// `setMinSweep`/`setWithdrawChunk`. That is the same limitation, and the
    /// same remedy, as `flatFee`.
    uint256 private constant DEFAULT_THRESHOLD_UNITS = 1000;

    // Events
    /// @notice Emitted on a bridge-in. `frAmount` is the 8-dec fr-asset to mint on
    /// Bitcoin; `assetAmount` is the NET asset locked in the asset's own base units.
    /// The coordinator's poll-deposits reads `data = [frAmount, assetAmount]` and
    /// build-mint mints `frAmount` verbatim — keep this layout in lockstep.
    event PaymentQueued(uint256 indexed paymentId, address indexed depositor, uint256 frAmount, uint256 assetAmount);
    event FlatFeeUpdated(uint256 oldFee, uint256 newFee);
    event PaymentProcessed(uint256 indexed paymentId, address indexed processor);
    event StrategyUpdated(address indexed oldStrategy, address indexed newStrategy);
    event DefaultPublicKeyUpdated(bytes32 indexed oldKey, bytes32 indexed newKey);
    event AuthenticatedCall(address indexed caller, bytes4 indexed selector, uint256 nonce);
    event AuthenticatedMulticall(address indexed caller, uint256 callCount, uint256 nonce);
    event BridgeWithdrawal(address indexed target, uint256 amount, address fallbackAddress, bool targetCallSuccess);
    event AssetsDeployedToStrategy(uint256 amount);
    event AssetsWithdrawnFromStrategy(uint256 amount);
    event MinSweepUpdated(uint8 indexed assetId, uint256 oldValue, uint256 newValue);
    event WithdrawChunkUpdated(uint8 indexed assetId, uint256 oldValue, uint256 newValue);
    event ProtocolFeeUpdated(uint256 oldFeeBps, uint256 newFeeBps);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    /// @notice B2 (audit): emitted once per unique bridge burn payout.
    event BridgeWithdrawalProcessed(uint256 indexed bridgeNonce, address indexed target, uint256 amount);

    // Errors
    error InvalidSignature();
    error InvalidNonce();
    error NotSelf();
    error ZeroPublicKey();
    error ZeroAddress();
    error PaymentAlreadyProcessed();
    error PaymentNotFound();
    error InsufficientAssets();
    error ZeroAmount();
    /// @notice B2 (audit): reverse-bridge replay of an already-paid Bitcoin burn.
    error BridgeNonceAlreadyUsed();
    /// @notice A payout target that would let the scripted call escape its budget:
    /// the vault itself (which would satisfy `onlyAuth`) or the custody asset
    /// (whose `transfer` the vault would then be invoking on itself).
    error InvalidTarget();
    /// @notice A scripted payout consumed more of the asset than it was allotted.
    error WithdrawalOverspend();
    /// Amount does not cover `flatFee`, so the transfer would net nothing.
    error BelowFlatFee();
    /// A batch with no calls would burn a nonce and do nothing.
    error EmptyBatch();
    /// A batch may not contain another authenticated entry point.
    error NestedAuthCall();
    /// `msg.sender` is not an authorised relayer.
    error NotRelayer();
    /// An asset id that was never registered.
    error UnknownAsset();
    /// Asset ids are permanent; re-pointing one would re-denominate existing records.
    error AssetAlreadyRegistered();
    /// Caller is neither the relayer admin nor the vault itself (FROST).
    error NotRelayerAdmin();
    /// `initialize` was given no assets, or more ids than a uint8 can carry.
    error InvalidAssetList();
    /// The same ERC20 was registered under two ids — two ledgers over one pot.
    error DuplicateAsset();
    /// Repointing `strategy` while the current one still holds a position would
    /// strand it — drain it first.
    error StrategyNotEmpty();

    /// @notice A relayer was authorised or revoked.
    event RelayerSet(address indexed relayer, bool allowed);
    /// @notice An ERC20 was registered under an asset id.
    event AssetRegistered(uint8 indexed id, address indexed token, uint8 decimals);
    /// @notice The relayer admin changed.
    event RelayerAdminTransferred(address indexed from, address indexed to);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the vault with its full set of custody assets.
    /// @param assets_ The ERC20s this vault custodies, registered under ids
    ///        0, 1, … in the order given. For the frUSD topology that is
    ///        `[USDC, USDT]`, so USDC is id 0 and USDT is id 1 — and those ids
    ///        are exactly what a Bitcoin-side burn names.
    ///
    ///        EVERY asset is registered HERE, at deploy, and there is no way to
    ///        add one afterwards — the asset set is fixed for the life of the
    ///        deployment.
    ///
    ///        Registering atomically closes a real window: the previous
    ///        `addAsset` was `onlyAuth`, so a second asset needed a FROST-signed
    ///        call, which means the signing group had to already be live — and
    ///        until it landed, `depositAndBridge` was permissionlessly open for
    ///        asset 0 while a burn naming asset 1 could not be paid at all.
    /// @param _defaultPublicKey The FROST group key (the withdrawal authority)
    /// @param flatFee_ Flat bridge fee, in ASSET UNITS, shared by every asset.
    ///        Correct while all registered assets have the SAME decimals (USDC
    ///        and USDT are both 6). Registering an 18-dec asset alongside them
    ///        would make one number mean two very different values — re-price it
    ///        per asset before doing so.
    /// @param initialRelayer_ The address permitted to SUBMIT authenticated
    ///        calls from launch — normally the coordinator's gas-paying EOA,
    ///        which is not usually the deployer. Pass `address(0)` to seed the
    ///        deployer instead.
    ///
    ///        `relayerAdmin` is always the deployer regardless, so the party
    ///        that can repair the relayer set is separate from the party that
    ///        submits. A vault must never initialize with NO relayer: every
    ///        authenticated entry point is gated, so not even the call adding the
    ///        first relayer could be submitted.
    function initialize(
        address[] calldata assets_,
        bytes32 _defaultPublicKey,
        uint256 flatFee_,
        address initialRelayer_
    ) external initializer {
        // At least one asset, or the vault is inert. At most 255: `_registerAsset`
        // sets `assetCount = id + 1` on a uint8, so id 255 would panic — and an
        // unchecked `uint8(i)` cast past that would silently wrap and re-register
        // id 0, overwriting the first asset's decimals.
        if (assets_.length == 0 || assets_.length > 255) revert InvalidAssetList();
        // Validate the key with the SAME rules as `setDefaultPublicKey`. Deploying
        // with an unusable key is unrecoverable: `_verifySignature` could never
        // return true, so no withdrawal and no key rotation would ever be possible,
        // while `depositAndBridge` stays permissionlessly open for users to lock
        // funds into a vault that can never release them.
        _validatePublicKey(_defaultPublicKey);

        // Ids are positional. `_registerAsset` rejects a zero address and a
        // duplicate id, and captures each asset's decimals + sweep thresholds.
        for (uint256 i = 0; i < assets_.length; i++) {
            _registerAsset(uint8(i), assets_[i]);
        }
        defaultPublicKey = _defaultPublicKey;
        protocolFeeBps = 10;          // 0.1%
        flatFee = flatFee_;           // asset units; re-priceable via setFlatFee
        feeRecipient = address(this); // can be changed later (onlyAuth)

        // The creator is the first relayer and the relayer admin. A vault that
        // initialized with NO relayer would be inert: every authenticated entry
        // point is gated, so not even the call that adds the first relayer could
        // be submitted.
        relayerAdmin = msg.sender;
        address firstRelayer = initialRelayer_ == address(0) ? msg.sender : initialRelayer_;
        isRelayer[firstRelayer] = true;
        relayerCount = 1;
        emit RelayerAdminTransferred(address(0), msg.sender);
        emit RelayerSet(firstRelayer, true);
    }

    /// Register an ERC20 under `id`.
    ///
    /// `initialize` is the ONLY caller — the asset set is fixed for the life of
    /// the deployment. The public `addAsset(uint8,address)` that used to sit
    /// here is gone: with both assets registered at initialize it had no
    /// remaining use, and it was a live FROST-gated entry point that could
    /// re-denominate the vault's accounting for every queued payment and every
    /// unpaid burn record. Deleting it is not a one-way door — under UUPS a
    /// future asset can be introduced by an implementation upgrade, which is a
    /// deliberate, reviewable act rather than a standing capability.
    ///
    /// Ids are positional and permanent. The `assetRegistered` guard below is
    /// therefore unreachable from `initialize` (which walks 0..n-1) and is kept
    /// as defence-in-depth for any future caller.
    function _registerAsset(uint8 id, address token) internal {
        if (token == address(0)) revert ZeroAddress();
        if (assetRegistered[id]) revert AssetAlreadyRegistered();

        // The same ERC20 must never occupy two ids. Nothing above stops it: the
        // guard beside this one rejects a reused ID, not a reused TOKEN.
        //
        // Two ids over one token means two ledgers over one pot. `feesCollected`,
        // `pending` and `inStrategy` would each split across ids that share a
        // single balance, and `totalAssets(0)` and `totalAssets(1)` would BOTH
        // report the whole balance — the backing reads as double what it is.
        //
        // This is a deploy-time footgun now that `initialize` takes a list: a
        // mistyped `[USDC, USDC]` would otherwise produce a silently
        // double-counting vault with no later call that surfaces it. O(n) over a
        // handful of ids, and it costs no storage slot.
        for (uint8 i = 0; i < assetCount; i++) {
            if (assetRegistered[i] && address(assets[i]) == token) revert DuplicateAsset();
        }

        assets[id] = IERC20(token);
        uint8 dec = IERC20Metadata(token).decimals();
        assetDecimalsOf[id] = dec;
        assetRegistered[id] = true;
        if (id >= assetCount) assetCount = id + 1;

        // Seed the gas-amortization thresholds so a vault is never deployed in
        // the degenerate configuration (sweep every dust deposit, pull the exact
        // shortfall for every payout) purely because nobody set them.
        //
        // Guarded at 18 decimals: `10 ** dec` overflows above 77 and would make
        // registration revert on a pathological token. Such an asset simply
        // starts at 0 (the old behaviour) and the operator configures it.
        if (dec <= 18) {
            uint256 unit = DEFAULT_THRESHOLD_UNITS * (10 ** uint256(dec));
            minSweep[id] = unit;
            withdrawChunk[id] = unit;
            emit MinSweepUpdated(id, 0, unit);
            emit WithdrawChunkUpdated(id, 0, unit);
        }

        emit AssetRegistered(id, token, dec);
    }

    /// Resolve a burn-side selector to a registered ERC20.
    ///
    /// Reverts on an unknown id rather than defaulting to asset 0 — a burn that
    /// named an unregistered asset must not be quietly paid in a different one.
    function _asset(uint8 id) internal view returns (IERC20) {
        if (!assetRegistered[id]) revert UnknownAsset();
        return assets[id];
    }

    // ============ Modifiers ============

    modifier onlyAuth() {
        if (msg.sender != address(this)) revert NotSelf();
        _;
    }

    /// Only an authorised relayer may SUBMIT an authenticated call.
    ///
    /// UPGRADE SAFETY: `relayerAdmin == address(0)` means this vault predates
    /// relayer gating — `initialize` has already run and cannot run again, so a
    /// beacon upgrade leaves both new fields zeroed. Enforcing the gate in that
    /// state would brick the vault permanently: no relayer is authorised, and
    /// `setRelayer` needs an admin that does not exist. So an unconfigured vault
    /// stays OPEN, exactly as it behaved before, and gating switches on the
    /// moment an admin is set (`claimRelayerAdmin`, a FROST-authorised call that
    /// is submittable precisely because the gate is still open).
    modifier onlyRelayer() {
        // Open when NOBODY is authorised. Two states reach that, and both must
        // stay recoverable:
        //
        //  * `relayerAdmin == 0` — a vault upgraded from an implementation that
        //    predates gating, whose `initialize` cannot run again.
        //  * `relayerCount == 0` — every relayer revoked.
        //
        // The second is the important one. Gating makes submission a liveness
        // dependency, and `onlyAuth` cannot rescue it because an `onlyAuth` call
        // has to arrive through the gated path. So a hostile or careless admin
        // that revoked everyone would otherwise hold every custodied asset
        // hostage INDEFINITELY, with no override available to the FROST group
        // that actually owns the funds. Failing open costs only the mempool
        // grief protection — the BIP340 signature still authorises everything —
        // and it leaves the group a way back in.
        if (relayerAdmin != address(0) && relayerCount != 0 && !isRelayer[msg.sender]) {
            revert NotRelayer();
        }
        _;
    }

    /// The relayer admin, or the vault itself (i.e. a FROST-authorised call).
    /// Two independent paths on purpose — see `relayerAdmin`.
    modifier onlyRelayerAdmin() {
        if (msg.sender != relayerAdmin && msg.sender != address(this)) {
            revert NotRelayerAdmin();
        }
        _;
    }

    // ============ View ============

    /// @notice Total asset controlled by this vault (in-vault + in-strategy).
    function totalAssets(uint8 assetId) public view returns (uint256) {
        uint256 vaultBalance = _asset(assetId).balanceOf(address(this));
        uint256 strategyBalance =
            address(strategy) != address(0) ? strategy.totalAssets(assetId) : 0;
        return vaultBalance + strategyBalance;
    }

    /// @dev Converts a NET asset amount (asset's own base units) to the 8-dec
    /// fr-asset amount minted on Bitcoin. 6-dec -> x100; 18-dec -> /1e10 (sub-1e10-wei
    /// dust is truncated and remains as backing).
    function _toFrAmount(uint8 assetId, uint256 amount) internal view returns (uint256) {
        if (assetDecimalsOf[assetId] <= FR_DECIMALS) {
            return amount * (10 ** uint256(FR_DECIMALS - assetDecimalsOf[assetId]));
        }
        return amount / (10 ** uint256(assetDecimalsOf[assetId] - FR_DECIMALS));
    }

    // ============ Bridge In ============

    /// @notice Locks `amount` of the vault's asset and queues a bridge-in to Bitcoin.
    /// The coordinator observes `PaymentQueued`, reads `bridgeData` off the payment
    /// record, and mints the fr-asset on Bitcoin to the destination it encodes. The
    /// vault treats `bridgeData` as opaque — it stores the bytes verbatim and makes
    /// no assumption about their format (the coordinator interprets them). No EVM
    /// token is minted.
    function depositAndBridge(
        uint8 assetId,
        uint256 amount,
        bytes calldata bridgeData
    ) external nonReentrant returns (uint256 netAmount) {
        IERC20 token = _asset(assetId);
        if (amount == 0) revert ZeroAmount();

        // Credit what actually ARRIVED, not what was requested. USDC/USDT/WETH move
        // the full amount today, but USDT carries a dormant, owner-toggleable
        // transfer fee (`setParams`) — if it is ever switched on, crediting `amount`
        // would mint fr-asset on Bitcoin that this vault does not hold.
        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 received = token.balanceOf(address(this)) - balanceBefore;
        if (received == 0) revert ZeroAmount();

        // Flat fee first, then the bps fee on what remains. Reverting (rather
        // than accepting and crediting nothing) keeps the user's funds with the
        // user: a deposit too small to bridge never leaves their wallet.
        if (received <= flatFee) revert BelowFlatFee();
        uint256 afterFlat = received - flatFee;
        uint256 feeAmount = (afterFlat * protocolFeeBps) / 10000;
        netAmount = afterFlat - feeAmount;
        feesCollected[assetId] += flatFee + feeAmount;

        uint256 paymentId = payments.length;
        Payment storage payment = payments.push();
        payment.paymentId = paymentId;
        payment.depositor = msg.sender;
        payment.assetId = assetId;
        payment.assetAmount = netAmount;
        payment.frAmount = _toFrAmount(assetId, netAmount);
        payment.bridgeData = bridgeData;
        payment.timestamp = uint64(block.timestamp);

        pending[assetId] += netAmount;

        emit PaymentQueued(paymentId, msg.sender, payment.frAmount, netAmount);

        // Deploy by DEFAULT. Idle custody earns nothing, and requiring an
        // operator to notice each deposit and sign a `depositToStrategy` makes
        // the yield a function of how attentive the operator is. Anything above
        // `minSweep` goes straight out; below it, the balance accumulates until
        // the next deposit clears the bar.
        //
        // Deliberately AFTER the payment record and the event: the bridge-in is
        // complete and observable at this point, so the sweep is an independent
        // step rather than something the coordinator's view depends on.
        _sweepToStrategy(assetId, minSweep[assetId]);
        return netAmount;
    }

    // ============ Payment getters ============

    function getPaymentsLength() external view returns (uint256) {
        return payments.length;
    }

    function getPayment(uint256 index)
        external
        view
        returns (
            address depositor,
            uint256 assetAmount,
            bytes memory bridgeData,
            uint256 timestamp,
            uint8 assetId
        )
    {
        if (index >= payments.length) revert PaymentNotFound();
        Payment storage p = payments[index];
        return (p.depositor, p.assetAmount, p.bridgeData, p.timestamp, p.assetId);
    }

    /// @notice Batch-reads unprocessed bridge-ins for coordinator efficiency.
    ///
    /// This is the coordinator's ONLY deposit read. It replaces scanning
    /// `PaymentQueued` logs plus a `getPayment` per hit: one `eth_call`, already
    /// filtered to unprocessed, with no block-range window to fall out of.
    /// Call it at a finality-lagged block to gate against reorgs.
    ///
    /// Returns the stored `Payment` records verbatim — same type, same fields —
    /// so there is no projection that can drift from what the vault holds.
    ///
    /// The return is named `unprocessed`, not `pending`: `pending` is the
    /// vault's NET-asset-committed accumulator, and reusing the name shadows it.
    function getPayments(uint256 startIndex, uint256 maxCount)
        external
        view
        returns (Payment[] memory page)
    {
        // A plain ranged read. There is no `processed` flag any more: the ALKANE
        // records how far the coordinator has minted (`/next_payment_id`) inside
        // the same call that mints, and passes that value here as `startIndex`.
        //
        // That removes the second EVM transaction the forward leg used to need
        // purely to acknowledge a mint — `markPaymentProcessed`, the settle
        // batch, and the ~1M-gas BIP340 verify it carried. The reverse leg
        // already worked this way (`withdrawFromBridge` records its own nonce);
        // this makes the two symmetric.
        uint256 endIndex = startIndex + maxCount;
        if (endIndex > payments.length) endIndex = payments.length;
        if (startIndex >= endIndex) return new Payment[](0);

        page = new Payment[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            page[i - startIndex] = payments[i];
        }
    }

    // ============ Authenticated ops ============

    /// @notice Executes an authenticated call with Schnorr signature verification.
    /// The signed message binds (data, nonce, chainid, address(this)) — so a
    /// signature can't be replayed on another chain or another vault.
    /// @notice Domain tag mixed into the multicall digest.
    ///
    /// Keeps a batch signature from ever being replayable against
    /// `authenticatedCall` (or the reverse). Without it the two digests differ
    /// only by ABI encoding shape, which is a thin thing to rely on for a
    /// signature that moves custody.
    bytes32 private constant MULTICALL_DOMAIN =
        keccak256("SUBFROST_VAULT_MULTICALL_V1");

    /// @notice Execute several authenticated actions under ONE signature.
    ///
    /// The point is gas. Every `authenticatedCall` pays for a BIP340
    /// verification in pure Solidity — around 1M gas, far more than the actions
    /// themselves. Settling a batch (say, three `markPaymentProcessed` plus two
    /// `withdrawFromBridge`) as five separate calls pays that five times; as one
    /// batch it is paid once.
    ///
    /// The signature commits to the WHOLE array, so the relayer — which is an
    /// untrusted gas payer with no on-chain role — cannot reorder, drop or add
    /// calls. The batch consumes exactly ONE nonce, so it is a single replay
    /// unit, and it is ATOMIC: if any call reverts the whole batch reverts and
    /// no nonce is spent.
    ///
    /// @param calls ABI-encoded calls, executed in order against this contract.
    /// @param nonce Must equal `authNonce`.
    /// @param signature BIP340 signature by `defaultPublicKey` over
    ///        keccak256(abi.encode(DOMAIN, calls, nonce, chainid, address(this))).
    function authenticatedMulticall(
        bytes[] calldata calls,
        uint256 nonce,
        bytes calldata signature
    ) external onlyRelayer returns (bytes[] memory results) {
        if (calls.length == 0) revert EmptyBatch();
        if (nonce != authNonce) revert InvalidNonce();

        bytes32 message = keccak256(
            abi.encode(MULTICALL_DOMAIN, calls, nonce, block.chainid, address(this))
        );
        if (!_verifySignature(message, signature)) revert InvalidSignature();

        // Effects before interactions: the nonce is spent before any call runs,
        // so a re-entrant attempt cannot reuse it.
        authNonce = nonce + 1;

        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            bytes calldata call_ = calls[i];
            // A nested authenticated entry point inside a batch would consume a
            // second nonce and muddy "one batch = one replay unit". Each action
            // is already authorised by the batch signature, so nesting has no
            // legitimate use.
            if (call_.length >= 4) {
                bytes4 sel = bytes4(call_[:4]);
                if (
                    sel == this.authenticatedCall.selector ||
                    sel == this.authenticatedMulticall.selector
                ) revert NestedAuthCall();
            }

            (bool success, bytes memory returnData) = address(this).call(call_);
            if (!success) {
                // Bubble the inner revert verbatim so the operator sees WHICH
                // action failed and why, not a generic batch error.
                assembly {
                    revert(add(returnData, 32), mload(returnData))
                }
            }
            results[i] = returnData;
        }

        emit AuthenticatedMulticall(msg.sender, calls.length, nonce);
        return results;
    }

    function authenticatedCall(
        bytes calldata data,
        uint256 nonce,
        bytes calldata signature
    ) external onlyRelayer returns (bytes memory result) {
        if (nonce != authNonce) revert InvalidNonce();

        bytes32 message = keccak256(abi.encode(data, nonce, block.chainid, address(this)));
        if (!_verifySignature(message, signature)) revert InvalidSignature();

        authNonce = nonce + 1;

        (bool success, bytes memory returnData) = address(this).call(data);
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }

        emit AuthenticatedCall(msg.sender, bytes4(data[:4]), nonce);
        return returnData;
    }

    // `_closePayment` and `markPaymentProcessed` are GONE.
    //
    // The forward leg no longer acknowledges anything on this chain. The alkane
    // records how far it has minted, in the same call that mints, and the
    // coordinator reads that as the `startIndex` for `getPayments`. So the
    // ~1M-gas authenticated ack per batch — and the whole settle-batch and
    // relayer-envelope path built to carry it — is unnecessary.
    //
    // `pending` is therefore never decremented here. It is now a monotonic
    // record of gross asset committed per id; it was already read by nothing
    // (audit F3), so nothing regressed. If a solvency invariant is added later
    // it must net against the alkane's mark rather than a local flag, since this
    // contract no longer knows what has been minted.

    // ============ Bridge Out ============    // ============ Bridge Out ============

    /// @notice Releases `amount` of the asset to `target` against a Bitcoin burn.
    /// @param bridgeNonce The burn's on-chain `bridge_id` — unique per burn. B2 (audit):
    ///        on-chain at-most-once payout.
    function withdrawFromBridge(
        uint256 bridgeNonce,
        uint8 assetId,
        uint256 amount,
        address target,
        bytes calldata script
    ) external onlyAuth nonReentrant {
        // Resolved HERE, from the id the burn record named. The coordinator
        // passes the index through verbatim and never chooses the token.
        IERC20 token = _asset(assetId);
        if (amount == 0) revert ZeroAmount();
        if (target == address(0)) revert ZeroAddress();
        // A payout must go OUT of the vault. Targeting the vault itself would make
        // the scripted call satisfy `onlyAuth` (turning a withdrawal signature into
        // an unlabelled arbitrary-admin call); targeting the asset would have the
        // vault invoke `transfer` on its own balance, escaping `amount` entirely.
        if (target == address(this) || target == address(token)) revert InvalidTarget();

        // B2: dedup — reject a replay of the same Bitcoin burn.
        // check-and-set BEFORE any transfer/strategy pull (effects-before-interactions).
        if (usedBridgeNonce[bridgeNonce]) revert BridgeNonceAlreadyUsed();
        usedBridgeNonce[bridgeNonce] = true;
        // Resume hint for the coordinator, recorded in the same call that pays
        // out — the mirror of the alkane's /next_payment_id. Monotonic, and
        // next-not-last because nonces start at 0. The per-nonce map above stays
        // the actual at-most-once guard; this only saves the coordinator from
        // re-reading burns it has already settled.
        if (bridgeNonce + 1 > nextBurnNonce) nextBurnNonce = bridgeNonce + 1;
        emit BridgeWithdrawalProcessed(bridgeNonce, target, amount);

        // Same flat fee on the way out. Checked BEFORE the nonce is burned
        // would be wrong — the nonce marks the Bitcoin burn as settled, and a
        // reverting call rolls that back with everything else, so ordering here
        // is safe either way.
        if (amount <= flatFee) revert BelowFlatFee();
        uint256 afterFlat = amount - flatFee;
        uint256 feeAmount = (afterFlat * protocolFeeBps) / 10000;
        uint256 netAmount = afterFlat - feeAmount;
        feesCollected[assetId] += flatFee + feeAmount;

        // With auto-sweep on, the idle balance is normally near zero, so a payout
        // sourcing from the strategy is the RULE rather than the exception.
        if (_ensureLiquidity(assetId, token, amount) < amount) revert InsufficientAssets();

        if (script.length > 0 && target.code.length > 0) {
            _executeContractWithdrawal(token, netAmount, target, script);
        } else {
            token.safeTransfer(target, netAmount);
            emit BridgeWithdrawal(target, netAmount, target, true);
        }
    }

    function _executeContractWithdrawal(
        IERC20 token,
        uint256 amount,
        address target,
        bytes calldata script
    ) internal {
        address fallbackAddress;
        bytes memory callData;
        (fallbackAddress, callData) = abi.decode(script, (address, bytes));
        if (fallbackAddress == address(0)) fallbackAddress = target;

        uint256 balanceBefore = token.balanceOf(address(this));
        token.forceApprove(target, amount);
        (bool success,) = target.call(callData);

        // Retract the allowance immediately. Without this, a target that spends
        // less than it was approved for keeps a standing approval for the residue
        // AND receives that residue back via the refund below — letting it take the
        // same value a second time (and every later bridge-out tops the approval
        // back up). Clearing here caps the target at exactly one `amount`.
        token.forceApprove(target, 0);

        uint256 balanceAfter = token.balanceOf(address(this));
        uint256 spent = balanceBefore - balanceAfter;
        // Defence in depth: the approval bounded the pull at `amount`, so this can
        // only trip if the asset behaves unexpectedly (e.g. a rebase during the call).
        if (spent > amount) revert WithdrawalOverspend();

        if (spent < amount) {
            token.safeTransfer(fallbackAddress, amount - spent);
        }
        emit BridgeWithdrawal(target, amount, fallbackAddress, success);
    }

    // ============ Strategy ============

    /// @notice Point the vault at a yield strategy, and immediately deploy the
    ///         idle balance of EVERY registered asset into it.
    ///
    /// The outgoing strategy must already be empty. Repointing over a funded one
    /// would strand its position: the vault stops reading that address,
    /// `inStrategy` is overwritten with the new strategy's (zero) balance, and
    /// the backing becomes recoverable only through the old strategy's own
    /// escape hatch — a silent loss of custody that no later call would surface.
    /// Drain it first with `withdrawAllFromStrategy` per asset.
    function setStrategy(address _strategy) external onlyAuth {
        IMultiAssetStrategy old = strategy;
        if (address(old) != address(0)) {
            for (uint8 id = 0; id < assetCount; id++) {
                if (assetRegistered[id] && old.totalAssets(id) != 0) revert StrategyNotEmpty();
                inStrategy[id] = 0;
            }
        }

        emit StrategyUpdated(address(old), _strategy);
        strategy = IMultiAssetStrategy(_strategy);
        if (_strategy == address(0)) return;

        // Threshold 0: wiring a strategy is an explicit, signed operator action,
        // so there is nothing to batch for — deploy whatever is idle now.
        for (uint8 id = 0; id < assetCount; id++) {
            if (assetRegistered[id]) _sweepToStrategy(id, 0);
        }
    }

    /// @notice Set this asset's auto-sweep threshold. See `minSweep`.
    function setMinSweep(uint8 assetId, uint256 newMinSweep) external onlyAuth {
        emit MinSweepUpdated(assetId, minSweep[assetId], newMinSweep);
        minSweep[assetId] = newMinSweep;
    }

    /// @notice Set this asset's strategy-pull granularity. See `withdrawChunk`.
    function setWithdrawChunk(uint8 assetId, uint256 newChunk) external onlyAuth {
        emit WithdrawChunkUpdated(assetId, withdrawChunk[assetId], newChunk);
        withdrawChunk[assetId] = newChunk;
    }

    /// Round a strategy ask UP to the asset's chunk size.
    ///
    /// Deliberately NOT capped at what the strategy holds: the vault cannot know
    /// that without another external call, and a strategy asked for more than it
    /// has returns what it can (`CrvUsdStrategy` caps the LP burn at its
    /// balance). `_ensureLiquidity` re-reads the balance afterwards, so an
    /// over-ask degrades to "drained the strategy", never to a revert.
    function _chunked(uint8 assetId, uint256 shortfall) internal view returns (uint256) {
        uint256 chunk = withdrawChunk[assetId];
        if (chunk <= 1) return shortfall;
        // Round up. `shortfall` is non-zero here (the caller checked), so this
        // never returns 0 and never asks the strategy for nothing.
        return ((shortfall + chunk - 1) / chunk) * chunk;
    }

    /// @notice Flush this asset's idle balance to the strategy now, ignoring
    ///         `minSweep`.
    function depositToStrategy(uint8 assetId) external onlyAuth {
        _asset(assetId); // reverts on an unregistered id
        if (address(strategy) == address(0)) revert ZeroAddress();
        _sweepToStrategy(assetId, 0);
    }

    function withdrawFromStrategy(uint8 assetId, uint256 amount) external onlyAuth {
        if (address(strategy) == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        strategy.withdraw(assetId, amount);
        inStrategy[assetId] = strategy.totalAssets(assetId); // resync to actual (audit #6)
        emit AssetsWithdrawnFromStrategy(amount);
    }

    function withdrawAllFromStrategy(uint8 assetId) external onlyAuth {
        if (address(strategy) == address(0)) revert ZeroAddress();
        uint256 amount = strategy.withdrawAll(assetId);
        inStrategy[assetId] = 0;
        emit AssetsWithdrawnFromStrategy(amount);
    }

    /// Move this asset's idle balance into the strategy, keeping the fee reserve
    /// behind. Returns what was actually deployed.
    ///
    /// `threshold` is the minimum idle balance that justifies the entry:
    /// `depositAndBridge` passes `minSweep` so small deposits batch, everything
    /// else passes 0 to flush unconditionally.
    ///
    /// Returns 0 rather than reverting when there is no strategy, it is paused,
    /// or there is nothing to move. This runs inside `depositAndBridge`, and a
    /// user's bridge-in must not fail because of how the yield side is
    /// configured — pausing the strategy degrades the vault to plain custody
    /// instead of closing the front door.
    function _sweepToStrategy(uint8 assetId, uint256 threshold) internal returns (uint256) {
        IMultiAssetStrategy s = strategy;
        if (address(s) == address(0) || !s.isActive()) return 0;

        IERC20 token = assets[assetId];
        // Do NOT deploy the fee reserve (audit): fees are held here and paid by
        // withdrawFees(), so sweeping them would make paying out money the vault
        // already holds depend on a strategy round-trip.
        uint256 bal = token.balanceOf(address(this));
        uint256 fees = feesCollected[assetId];
        uint256 available = bal > fees ? bal - fees : 0;
        if (available == 0 || available < threshold) return 0;

        token.forceApprove(address(s), available);
        s.deposit(assetId, available);
        // Retract any residue: a strategy that pulled less than it was approved
        // for would otherwise keep a standing allowance over custody funds.
        token.forceApprove(address(s), 0);

        inStrategy[assetId] = s.totalAssets(assetId); // resync to actual (audit #6)
        emit AssetsDeployedToStrategy(available);
        return available;
    }

    /// Make sure `needed` of `token` is sitting in the vault, pulling the
    /// shortfall back from the strategy. Returns the balance actually available
    /// afterwards, which the caller must check — a strategy can deliver less
    /// than it was asked for.
    ///
    /// IDLE BALANCE FIRST. A payout served from what is already sitting here is
    /// a plain ERC20 transfer; one served from the strategy is a Curve exit
    /// costing an order of magnitude more gas. So the strategy is touched only
    /// for the part the idle balance cannot cover, and not at all when it can.
    ///
    /// When it IS touched, the ask is rounded up to `withdrawChunk` — the exit
    /// costs the same whether it pulls the exact shortfall or a round lot, and
    /// the excess stays here to serve later payouts by transfer alone.
    function _ensureLiquidity(uint8 assetId, IERC20 token, uint256 needed)
        internal
        returns (uint256 available)
    {
        available = token.balanceOf(address(this));
        if (available >= needed || address(strategy) == address(0)) return available;

        strategy.withdraw(assetId, _chunked(assetId, needed - available));
        // Resync to the strategy's actual value (audit #6): a lossy strategy may
        // return slightly less; reading totalAssets() keeps it exact + safe.
        inStrategy[assetId] = strategy.totalAssets(assetId);
        available = token.balanceOf(address(this));
    }

    // ============ Key rotation / fees ============

    /// @notice Rotates the FROST key (FROST-gated). Validates the new key so a bad
    /// DKG output can't brick the fund gate: reject zero, reject x in [N,P), and
    /// require it to lift to a real on-curve point (TOB-VAULT-005/006).
    function setDefaultPublicKey(bytes32 newPublicKey) external onlyAuth {
        _validatePublicKey(newPublicKey);
        bytes32 oldKey = defaultPublicKey;
        defaultPublicKey = newPublicKey;
        emit DefaultPublicKeyUpdated(oldKey, newPublicKey);
    }

    /// @dev Rejects a key that could never verify a signature: zero, x outside the
    /// curve order, or an x with no corresponding curve point (TOB-VAULT-005/006).
    function _validatePublicKey(bytes32 key) private pure {
        if (key == bytes32(0)) revert ZeroPublicKey();
        uint256 kx = uint256(key);
        if (kx >= Secp256k1.NN) revert ZeroPublicKey();
        (, bool liftOk) = Bip340Util.liftX(kx);
        if (!liftOk) revert ZeroPublicKey();
    }

    function setProtocolFee(uint256 newFeeBps) external onlyAuth {
        if (newFeeBps > 100) revert("Fee too high"); // Max 1%
        uint256 oldFee = protocolFeeBps;
        protocolFeeBps = newFeeBps;
        emit ProtocolFeeUpdated(oldFee, newFeeBps);
    }

    /// @notice Re-price the flat fee (asset units).
    ///
    /// `onlyAuth` is the vault's sole authority — a FROST group signature
    /// routed through `authenticatedCall`. There is no owner or admin role, so
    /// this is the "admin" path: threshold-signed, replay-guarded by authNonce.
    ///
    /// Deliberately unbounded: for an 18-dec asset a sane fee is a large number,
    /// and any cap expressed here would be wrong for some asset. The threshold
    /// signature is the control.
    /// @notice Authorise or revoke a relayer.
    ///
    /// Callable by the relayer admin OR through a FROST-authorised call, so a
    /// lost key on either side is recoverable from the other.
    ///
    /// Keep at least two funded relayers. A relayer holds no authority over
    /// funds, but it is the ONLY way to submit one — with none authorised, and
    /// the admin key also lost, the vault can never move money again.
    function setRelayer(address relayer, bool allowed) external onlyRelayerAdmin {
        if (relayer == address(0)) revert ZeroAddress();
        if (isRelayer[relayer] != allowed) {
            isRelayer[relayer] = allowed;
            // Kept exact rather than incremented blindly: a repeated
            // setRelayer(x, true) would otherwise inflate the count and the
            // gate could never re-open.
            if (allowed) relayerCount += 1;
            else relayerCount -= 1;
            emit RelayerSet(relayer, allowed);
        }
    }

    /// @notice Turn on relayer gating for a vault upgraded from a version that
    ///         predates it.
    ///
    /// Only callable while `relayerAdmin` is unset, and only through a
    /// FROST-authorised call — which works because an unconfigured vault is
    /// still open. After this the gate is live and `setRelayer` is the way in.
    ///
    /// Not needed for a fresh deploy: `initialize` seeds the creator.
    function claimRelayerAdmin(address admin, address firstRelayer) external onlyAuth {
        if (relayerAdmin != address(0)) revert NotRelayerAdmin();
        if (admin == address(0) || firstRelayer == address(0)) revert ZeroAddress();
        relayerAdmin = admin;
        isRelayer[firstRelayer] = true;
        relayerCount += 1;
        emit RelayerAdminTransferred(address(0), admin);
        emit RelayerSet(firstRelayer, true);
    }

    /// @notice Hand the relayer admin role to another address (e.g. a multisig).
    ///
    /// Not renounceable to `address(0)`: that would delete one of the two
    /// recovery paths and leave the FROST group unable to re-authorise a relayer
    /// if it ever lost all of them.
    function transferRelayerAdmin(address newAdmin) external onlyRelayerAdmin {
        if (newAdmin == address(0)) revert ZeroAddress();
        emit RelayerAdminTransferred(relayerAdmin, newAdmin);
        relayerAdmin = newAdmin;
    }

    function setFlatFee(uint256 newFlatFee) external onlyAuth {
        uint256 oldFee = flatFee;
        flatFee = newFlatFee;
        emit FlatFeeUpdated(oldFee, newFlatFee);
    }

    function setFeeRecipient(address newRecipient) external onlyAuth {
        if (newRecipient == address(0)) revert ZeroAddress();
        address oldRecipient = feeRecipient;
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(oldRecipient, newRecipient);
    }

    function withdrawFees(uint8 assetId) external onlyAuth nonReentrant {
        IERC20 token = _asset(assetId);
        uint256 amount = feesCollected[assetId];
        if (amount == 0) revert ZeroAmount();
        // `feeRecipient` defaults to this vault. Paying out to that default would be
        // a self-transfer: it zeroes the ledger while no tokens move, silently
        // folding accrued fees into general backing and emitting a FeesWithdrawn
        // event that indexers would read as revenue actually paid. Require a real
        // recipient to be configured first.
        address recipient = feeRecipient;
        if (recipient == address(this)) revert InvalidTarget();

        // The reserve is never SWEPT (`_sweepToStrategy` holds it back), but a
        // payout can still consume it: `withdrawFromBridge` sources from the idle
        // balance first, and that balance includes the reserve. So pull the
        // shortfall back rather than refusing to pay out fees the vault
        // demonstrably earned. `nonReentrant` because this now makes an external
        // strategy call before zeroing the ledger.
        if (_ensureLiquidity(assetId, token, amount) < amount) revert InsufficientAssets();

        feesCollected[assetId] = 0;
        token.safeTransfer(recipient, amount);
        emit FeesWithdrawn(recipient, amount);
    }

    // ============ Upgrade ============

    /// @notice Authorizes a UUPS implementation swap.
    ///
    /// @dev `onlyAuth` — the same gate as `withdrawFromBridge`. An upgrade is
    ///      therefore a FROST BIP340 signature over the calldata, bound to this
    ///      vault, this chain id and `authNonce`, submitted by an authorised
    ///      relayer through `authenticatedCall`. Replacing the implementation is
    ///      strictly more powerful than any single withdrawal, so it must not sit
    ///      behind a weaker or merely different authority than the funds do.
    ///
    ///      Deliberately NOT delegated to a separate admin contract. The obvious
    ///      candidate here, `SchnorrProxyAdmin`, verifies with `Bip340Ecrec`,
    ///      whose check ends at `ecrecover(...) == fakeAddr` — a 160-bit ADDRESS
    ///      comparison. This vault verifies with `Bip340NaiveLib`, which compares
    ///      the full 256-bit x(R) (the B4 audit fix). Routing upgrades through the
    ///      ecrecover variant would put total custody behind a weaker check than
    ///      the withdrawals it protects.
    ///
    ///      Standard UUPS caveat: an implementation that drops this function ends
    ///      upgradeability permanently. Verify any candidate implementation still
    ///      inherits `UUPSUpgradeable` before signing the swap.
    function _authorizeUpgrade(address newImplementation) internal override onlyAuth {
        // The zero address would brick the proxy — every subsequent call
        // delegates to code that does not exist.
        if (newImplementation == address(0)) revert ZeroAddress();
    }

    // ============ Internal ============

    function _verifySignature(bytes32 message, bytes calldata signature)
        internal
        view
        returns (bool)
    {
        if (signature.length != 64) return false;
        uint256 rx = uint256(bytes32(signature[0:32]));
        uint256 s = uint256(bytes32(signature[32:64]));
        return Bip340NaiveLib.verify(uint256(defaultPublicKey), rx, s, message);
    }
}
