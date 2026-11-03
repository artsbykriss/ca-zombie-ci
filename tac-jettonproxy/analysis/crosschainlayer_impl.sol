// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import { VersionLib } from "../libs/VersionLib.sol";

import { TVMFeeInfo, InMessageV1, TokenInfo, TokenAmount, EpochInfo, SimulationParams, NFTInfo, NFTAmount } from "./Structs.sol";
import { TokenHelperLib } from "../libs/TokenHelperLib.sol";
import { IConsensus } from "../interfaces/IConsensus.sol";
import { ICrossChainLayer } from "../interfaces/ICrossChainLayer.sol";
import { ITokenUtils } from "../interfaces/ITokenUtils.sol";
import { TacProxy } from "../proxies/TacProxy.sol";
import { TacInitializable } from "./TacInitializable.sol";


/**
 * @title CrossChainLayer
 * @dev A contract for managing cross-chain messages and tokens.
 */
contract CrossChainLayer is TacInitializable, UUPSUpgradeable, Ownable2StepUpgradeable, ICrossChainLayer {

    // Errors

    // protocol errors
    error TokenNotExist(address token);
    error ProxyCallError(bytes reason);
    error NativeTrasferError(bytes reason);
    error TargetIsNotTacProxy(address target);
    error InvalidProxyVersion(address target, uint version);
    error RecursiveMessageProcessing();
    error OnlySelfCall();
    error MessageAlreadyProcessed(bytes32 messageHash);
    error InvalidMerkleProof();
    error AppLayerUnexpectedError();
    error AppLayerCallError(bytes32 operationId, bytes reason);
    error BridgeAmountToBig(address token, uint256 amount);
    error ExecutorIsNotValid(bytes32 operationId, address sender);
    error NativeFeeTransferError(bytes32 operationId, bytes reason);
    error NotEnoughGas(uint64 gasLimit, uint256 gasLeft);
    error CantUnlockNative(uint256 locked, uint256 toUnlock);
    error ExtraDataIsNotSupported();

    // fee errors
    error ZeroFeeSetting();
    error InsufficientProtocolFeeBalance(uint256 needed, uint256 available);
    error InsufficientFeeAmount(uint256 needed, uint256 attached);
    error InsufficientNativeAttached(uint256 needed, uint256 attached);

    // simulation errors
    error SimulationRecursiveCall();
    error SimulationUnexpectedSuccess();
    error SimulationUnexpectedError();
    error SimulationIsNotInProgress();
    error SimulationFinished(bool success, bytes result);
    error SimulationFailedError(bytes reason);

    // Events

    /**
     * @dev Error event for calling the application layer context.
     */
    event AppLayerCallErrorEvent(bytes32 operationId, bytes reason);

    event SimulationSuccess(OutMessageProcessedEventStruct[] outMessages);

    /**
     * @dev Input (receive) message executed event
     * @param operationId Operation Id to track message
     */
    event InMessageProcessed(bytes32 operationId);

    /**
     * @dev Output (send) message executed event
     * @param shardsKey Key to track message
     * @param operationId Operation Id to track message
     * @param callerAddress Caller address (EVM message initiator)
     * @param targetAddress Recipient address (TVM recipient address))
     * @param payload Message payload
     * @param protocolFee Protocol fee for the message
     * @param executorFee Executor fee for the message
     * @param tvmValidExecutors TVM valid executors for the message
     * @param tokensBurned Token burned during message processing
     * @param tokensLocked Token locked during message processing
     * @param nftsBurned NFT burned during message processing
     * @param nftsLocked NFT locked during message processing
     */
    event OutMessageProcessed(
        uint64 shardsKey,
        bytes32 operationId,
        address callerAddress,
        string targetAddress,
        string payload,
        uint256 protocolFee,
        uint256 executorFee,
        string[] tvmValidExecutors,
        TokenAmount[] tokensBurned,
        TokenAmount[] tokensLocked,
        NFTAmount[] nftsBurned,
        NFTAmount[] nftsLocked
    );

    // Constants

    address public constant NATIVE_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    uint256 private constant MAX_BRIDGE_AMOUNT = uint256(1 << 120);

    // State variables

    ITokenUtils private _tokenUtils;
    IConsensus private _consensus;

    bytes32 private _currentInMessageOperationId;
    bool private _receiveInProgress;

    mapping(bytes32 => bool) private _processedInMessages;

    // simulation state
    enum SimulationMode {
        None,
        JustGas,
        WithMessages
    }
    SimulationMode private _simulationMode;
    bytes32 private _simulationRoot;

    /**
     * @dev Output (send) message executed event structure
     * @param shardsKey Key to track message
     * @param operationId Operation Id to track message
     * @param callerAddress Caller address (EVM message initiator)
     * @param targetAddress Recipient address (TVM recipient address))
     * @param payload Message payload
     * @param protocolFee Protocol fee for the message
     * @param executorFee Executor fee for the message
     * @param tvmValidExecutors TVM valid executors for the message
     * @param tokensBurned Token burned during message processing
     * @param tokensLocked Token locked during message processing
     * @param nftsBurned NFT burned during message processing
     * @param nftsLocked NFT locked during message processing
     */
    struct OutMessageProcessedEventStruct {
        uint64 shardsKey;
        bytes32 operationId;
        address callerAddress;
        string targetAddress;
        string payload;
        uint256 protocolFee;
        uint256 executorFee;
        string[] tvmValidExecutors;
        TokenAmount[] tokensBurned;
        TokenAmount[] tokensLocked;
        NFTAmount[] nftsBurned;
        NFTAmount[] nftsLocked;
    }
    /**
     * @dev This array is always empty, because all changes are reverted inside simulateAppLayerContext
     * So the OutMessageProcessedEventStruct struct can be upgraded safely
     */
    OutMessageProcessedEventStruct[] private _simulationOutMessagesProcessedEvents;

    uint256 private _protocolFee;
    uint256 private _collectedProtocolFee;
    /** END OF STORAGE VARS **/

    /**
     * @dev Initializer function to initialize the contract with initial state.
     * @param adminAddress admin address.
     * @param consensusAddress Consensus contract address.
     */
    function initialize(
        address adminAddress,
        address consensusAddress
    ) public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init(adminAddress);

        _consensus = IConsensus(consensusAddress);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    // Admin methods

    /**
     * @dev Sets the token utils contract address.
     * @param tokenUtils Token utils contract address.
     */
    function setTokenUtils(address tokenUtils) external onlyOwner {
        if (address(_tokenUtils) != address(0)) revert();
        _tokenUtils = ITokenUtils(tokenUtils);
    }

    function setProtocolFee(uint256 fee) external onlyOwner {
        if (fee == 0) {
            revert ZeroFeeSetting();
        }
        _protocolFee = fee;
    }

    function withdrawProtocolFee(address payable to, uint256 amount) external onlyOwner {
        if (to == address(0) || amount == 0) {
            revert();
        }

        if (amount > _collectedProtocolFee) {
            revert InsufficientProtocolFeeBalance(amount, _collectedProtocolFee);
        }

        (bool success, bytes memory response) = to.call{value: amount}("");
        if (!success) {
            revert NativeTrasferError(response);
        }

        _collectedProtocolFee -= amount;
    }

    // Internal methods

    function _decodeCustomError(bytes memory customErrorBytes) internal pure returns (bytes4 selector, bytes memory data) {
        assembly ("memory-safe") {
            // Load the 4-byte error selector
            selector := mload(add(customErrorBytes, 0x20))

            // Calculate the length of `data` (excluding the 4-byte selector)
            let dataLength := sub(mload(customErrorBytes), 4)

            // Allocate memory for `data`
            data := mload(0x40) // Get the current free memory pointer
            mstore(data, dataLength) // Store the length of `data`
            mstore(0x40, add(data, add(dataLength, 0x20))) // Update the free memory pointer

            // Copy full 32-byte chunks
            let source := add(customErrorBytes, 0x24) // Start of data in customErrorBytes
            let dest := add(data, 0x20) // Start of the `data` array in memory
            for { let i := 0 } lt(i, sub(dataLength, mod(dataLength, 0x20))) { i := add(i, 0x20) } {
                mstore(add(dest, i), mload(add(source, i)))
            }

            // Copy remaining bytes (if any)
            let remainingBytes := mod(dataLength, 0x20)
            if gt(remainingBytes, 0) {
                let mask :=  not(sub(exp(0x100, sub(0x20, remainingBytes)), 1)) // Mask for remaining bytes
                let src := mload(add(source, sub(dataLength, remainingBytes)))
                mstore(add(dest, sub(dataLength, remainingBytes)), and(src,mask)) // Copy only valid bytes
            }
        }
    }

    function _checkMerkleRoot(bytes32 root) internal view returns (bool) {
        if (_simulationMode == SimulationMode.None) {
            return _consensus.checkMerkleRoot(root);
        } else {
            return root == _simulationRoot;
        }
    }

    function _checkInMessage(
        uint256 version,
        bytes calldata encodedMessage,
        bytes32[] calldata proof)
    internal view returns (bytes32 messageHash, VersionLib.UnionInMessage memory message) {
        uint256 gasPassed = gasleft();

        if (_receiveInProgress) {
            revert RecursiveMessageProcessing();
        }

        // calculate the message hash
        messageHash = keccak256(bytes.concat(keccak256(encodedMessage)));

        // check if the message has already been processed
        if(_processedInMessages[messageHash] == true) {
            revert MessageAlreadyProcessed(messageHash);
        }

        if (!_checkMerkleRoot(MerkleProof.processProofCalldata(proof, messageHash))) {
            revert InvalidMerkleProof();
        }

        message = VersionLib.decodeInMessage(version, encodedMessage);

        if (_simulationMode == SimulationMode.None) {
            if (message.gasLimit > gasPassed) {
                revert NotEnoughGas(message.gasLimit, gasPassed);
            }
        }

        if (_simulationMode == SimulationMode.None) {
            bool isValidExecutor = false;
            for (uint256 i = 0; i < message.evmValidExecutors.length; i++) {
                if (message.evmValidExecutors[i] == msg.sender) {
                    isValidExecutor = true;
                    break;
                }
            }
            if (!isValidExecutor) {
                revert ExecutorIsNotValid(message.operationId, msg.sender);
            }
        }
    }

    function _preprocessInMessage(VersionLib.UnionInMessage memory message, address feeReceiver) internal {
        uint i;
        // deploy tokens if not exist
        for (;i < message.meta.length;) {
            TokenInfo memory info = message.meta[i];
            if (!_tokenUtils.exists(info.tvmAddress)) {
                _tokenUtils.create(info);
            }
            unchecked {
                i++;
            }
        }
        delete i;
        // erc721
        for(;i < message.metaNFT.length;) {
            NFTInfo memory info = message.metaNFT[i];
            if (!_tokenUtils.exists(info.tvmAddress)) {
                _tokenUtils.createERC721(info);
            }
            unchecked {
                i++;
            }
        }

        // mint fee to executor
        TokenHelperLib.mint(message.evmExecutorFee, feeReceiver);
    }

    function _processInMessageTokens(VersionLib.UnionInMessage calldata message) internal returns (uint256 valueToUnlock) {
        uint i;
        // mint tokens
        for (; i < message.mint.length;) {
            TokenAmount calldata token = message.mint[i];
            if (!_tokenUtils.exists(token.evmAddress)) {
                revert TokenNotExist(token.evmAddress);
            }
            TokenHelperLib.mint(token, message.target);
            unchecked {
                i++;
            }
        }

        // unlock tokens
        delete i;
        for (; i < message.unlock.length;) {
            TokenAmount calldata token = message.unlock[i];
            if (token.evmAddress == NATIVE_TOKEN_ADDRESS) {
                valueToUnlock += token.amount;
            } else {
                TokenHelperLib.unlock(token, message.target);
            }
            unchecked {
                i++;
            }
        }

        if (valueToUnlock > 0) {
            uint256 balance = address(this).balance;
            if (balance < valueToUnlock) {
                revert CantUnlockNative(balance, valueToUnlock);
            }
        }

        // nft
        // mint nft
        delete i;
        for (; i < message.mintNFT.length;) {
            NFTAmount calldata token = message.mintNFT[i];
            if (!_tokenUtils.exists(token.evmAddress)) {
                revert TokenNotExist(token.evmAddress);
            }
            TokenHelperLib.mintNFT(token, message.target);
            unchecked {
                i++;
            }
        }

        // unlock nft
        delete i;
        for (; i < message.unlockNFT.length;) {
            NFTAmount calldata token = message.unlockNFT[i];
            TokenHelperLib.unlockNFT(token, message.target);
            unchecked {
                i++;
            }
        }
    }

    function _processOutMessageTokens(
        VersionLib.UnionOutMessage memory message
    ) internal returns (TokenAmount[] memory toBurn, TokenAmount[] memory toLock, NFTAmount[] memory toBurnNFT, NFTAmount[] memory toLockNFT) {

        toBurn = new TokenAmount[](message.toBridge.length);
        toLock = new TokenAmount[](message.toBridge.length + 1);
        uint256 i;
        uint256 l;
        uint256 b;
        for (;i < message.toBridge.length;) {
            TokenAmount memory token = message.toBridge[i];
            if (token.amount == 0) {
                unchecked {
                    i++;
                }
                continue;
            }
            if (token.amount >= MAX_BRIDGE_AMOUNT) {
                revert BridgeAmountToBig(token.evmAddress, token.amount);
            }
            if (_tokenUtils.exists(token.evmAddress)) {
                TokenHelperLib.burn(token);
                toBurn[b] = token;
                unchecked {
                    b++;
                }
            }
            else {
                TokenHelperLib.lock(token);
                toLock[l] = token;
                unchecked {
                    l++;
                }
            }
            unchecked {
                i++;
            }
        }

        uint256 valueToLock = msg.value;

        // ensure processing fees
        if (!_receiveInProgress) {
            if (message.tvmProtocolFee < _protocolFee) {
                revert InsufficientFeeAmount(_protocolFee, message.tvmProtocolFee);
            }

            uint256 totalFee = message.tvmExecutorFee + message.tvmProtocolFee;
            if (valueToLock < totalFee) {
                revert InsufficientNativeAttached(totalFee, msg.value);
            }
            valueToLock -= totalFee;
            _collectedProtocolFee += message.tvmProtocolFee;
        }

        // lock received native
        if (valueToLock > 0) {
            if (valueToLock >= MAX_BRIDGE_AMOUNT) {
                revert BridgeAmountToBig(NATIVE_TOKEN_ADDRESS, valueToLock);
            }
            toLock[l] = TokenAmount({
                evmAddress: NATIVE_TOKEN_ADDRESS,
                amount: valueToLock
            });
            unchecked {
                l++;
            }
        }

        // set arrays length
        assembly {
            mstore(toBurn, b)
            mstore(toLock, l)
        }

        delete i;
        delete l;
        delete b;
        toBurnNFT = new NFTAmount[](message.toBridgeNFT.length);
        toLockNFT = new NFTAmount[](message.toBridgeNFT.length);
        for(;i < message.toBridgeNFT.length;) {
            NFTAmount memory token = message.toBridgeNFT[i];
            if (_tokenUtils.exists(token.evmAddress)) {
                TokenHelperLib.burnNFT(token);
                toBurnNFT[l] = token;
                unchecked {
                    l++;
                }
            }
            else {
                TokenHelperLib.lockNFT(token);
                toLockNFT[b] = token;
                unchecked {
                    b++;
                }
            }
            unchecked {
                i++;
            }
        }

        // set arrays length
        assembly {
            mstore(toBurnNFT, l)
            mstore(toLockNFT, b)
        }
    }

    // External methods

    /**
     * @dev Simulates the processing of an TVM->EVM message.
     * @param messageVersion Message version.
     * @param encodedMessage Message to simulate.
     * @param merkleRoot Merkle root for checking proofs simulation.
     * @param merkleProof Merkle proof to check.
     * @param withMessages True if the simulation should include out messages, false - just for gas calculation.
     * @return simulationStatus True if the simulation was successful, false otherwise.
     * @return outMessages Array of out messages if the simulation was successful.
     * @return errorReason Encoded error reason if the simulation was unsuccessful.
     */
    function simulateReceiveMessage(
        uint256 messageVersion,
        bytes calldata encodedMessage,
        bytes calldata extraData,
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof,
        bool withMessages
    ) external returns (bool simulationStatus, OutMessageProcessedEventStruct[] memory outMessages, bytes memory errorReason) {
        if (_simulationMode != SimulationMode.None) {
            revert SimulationRecursiveCall();
        }

        if (extraData.length != 0) {
            revert ExtraDataIsNotSupported();
        }

        if (!withMessages) {
            _simulationMode = SimulationMode.JustGas;
        }
        else {
            _simulationMode = SimulationMode.WithMessages;
        }

        _simulationRoot = merkleRoot;

        (, VersionLib.UnionInMessage memory message) = _checkInMessage(messageVersion, encodedMessage, merkleProof);

        _currentInMessageOperationId = message.operationId;
        _receiveInProgress = true;
        (bool success, bytes memory result) = address(this).call(
            abi.encodeWithSelector(
                this.simulateAppLayerContext.selector,
                message,
                extraData
            )
        );

        if (success) {
            revert SimulationUnexpectedSuccess();
        }

        (bytes4 errorSelector, bytes memory errorData) = _decodeCustomError(result);

        if (errorSelector != SimulationFinished.selector) {
            revert SimulationUnexpectedError();
        }

        bytes memory simulationData;
        (simulationStatus, simulationData) = abi.decode(errorData, (bool, bytes));

        if (simulationStatus) {
            if (_simulationMode == SimulationMode.WithMessages) {
                outMessages = abi.decode(simulationData, (OutMessageProcessedEventStruct[]));
                emit SimulationSuccess(outMessages);
            }
        }
        else {
            if (simulationData.length == 0) {
                revert SimulationUnexpectedError();
            }

            errorReason = simulationData;

            if (_simulationMode == SimulationMode.JustGas) {
                revert SimulationFailedError(errorReason);
            }
        }

        _simulationMode = SimulationMode.None;
        delete _simulationRoot;
        _receiveInProgress = false;
        delete _currentInMessageOperationId;
    }

    function simulateAppLayerContext(
        VersionLib.UnionInMessage calldata message,
        bytes calldata extraData
    ) external {
        if (msg.sender != address(this)) {
            revert OnlySelfCall();
        }

        if (_simulationMode == SimulationMode.None) {
            revert SimulationIsNotInProgress();
        }

        // deploy tokens and mint fee
        _preprocessInMessage(message, message.evmValidExecutors[0]);

        // call appLayerContext where can be called sendMessage
        (bool success, bytes memory result) = address(this).call(
            abi.encodeWithSelector(
                this.appLayerContext.selector,
                message,
                extraData
            )
        );

        if (success) {
            bytes memory outMessagesEncoded;
            if (_simulationMode == SimulationMode.WithMessages) {
                outMessagesEncoded = abi.encode(_simulationOutMessagesProcessedEvents);
            }

            revert SimulationFinished(true, outMessagesEncoded);
        }

        revert SimulationFinished(false, result);
    }

    /**
     * @dev Accepts an TVM->EVM message to process if the Merkle proof is valid.
     * @param messageVersion Message version.
     * @param encodedMessage Encoded message to process.
     * @param merkleProof Merkle proof for the message.
     * @param feeReceiver receiver of fee.
     * @param extraData Untrusted extra data to pass to the message.
     */
    function receiveMessage(
        uint256 messageVersion,
        bytes calldata encodedMessage,
        bytes32[] calldata merkleProof,
        address feeReceiver,
        bytes calldata extraData
    ) external {

        if (extraData.length != 0) {
            revert ExtraDataIsNotSupported();
        }

        (bytes32 messageHash, VersionLib.UnionInMessage memory message) = _checkInMessage(messageVersion, encodedMessage, merkleProof);

        // deploy tokens and mint fee
        _preprocessInMessage(message, feeReceiver);

        _currentInMessageOperationId = message.operationId;
        _receiveInProgress = true;

        // call with full InMessage to avoid stack depth overflow
        (bool success, bytes memory result) = address(this).call(
            abi.encodeWithSelector(
                this.appLayerContext.selector,
                message,
                extraData
            )
        );

        if (!success) {
            if (result.length == 0) revert AppLayerUnexpectedError();
            emit AppLayerCallErrorEvent(message.operationId, result);
        }
        else {
            emit InMessageProcessed({
                operationId: message.operationId
            });
        }

        _processedInMessages[messageHash] = true;

        _receiveInProgress = false;
        delete _currentInMessageOperationId;
    }

    function appLayerContext(
        VersionLib.UnionInMessage calldata message,
        bytes calldata extraData
    ) external {
        if (msg.sender != address(this)) {
            revert OnlySelfCall();
        }

        uint256 valueToUnlock = _processInMessageTokens(message);

        // Process (execute) the message
        if (message.target != address(0)) {
            bool status = true;
            bytes memory response;
            if (bytes(message.methodName).length != 0) {

                bytes memory header = VersionLib.prepareTacHeader(message, extraData);

                bytes memory methodCall = abi.encodeWithSelector(
                    bytes4(keccak256(bytes(message.methodName))),
                    header,
                    message.arguments
                );
                (status, response) = address(message.target).call{value: valueToUnlock}(methodCall);
            }
            else if (valueToUnlock != 0) {
                (status, response) = address(message.target).call{value: valueToUnlock}("");
            }

            if (!status) {
                revert ProxyCallError(response);
            }
        }
    }

    /**
     * @dev Accepts an EVM->TVM message to process (e.g. a callback from dApp).
     * @param messageVersion Message version.
     * @param encodedMessage Encoded message to process.
     */
    function sendMessage(
        uint256 messageVersion,
        bytes calldata encodedMessage
    ) external payable override {
        VersionLib.UnionOutMessage memory message = VersionLib.decodeOutMessage(messageVersion, encodedMessage);

        (
            TokenAmount[] memory toBurn,
            TokenAmount[] memory toLock,
            NFTAmount[] memory toBurnNFT,
            NFTAmount[] memory toLockNFT
        ) = _processOutMessageTokens(message);

        // ensure message parameters if this is a callback message
        bytes32 operationId = bytes32(0);
        if (_receiveInProgress) {
            operationId = _currentInMessageOperationId;
        }

        // if simulation mode is WithMessages, save the out message to the simulation state
        if (_simulationMode == SimulationMode.WithMessages) {

            OutMessageProcessedEventStruct storage outMessage = _simulationOutMessagesProcessedEvents.push();

            outMessage.shardsKey = message.shardsKey;
            outMessage.operationId = operationId;
            outMessage.callerAddress = msg.sender;
            outMessage.targetAddress = message.tvmTarget;
            outMessage.payload = message.tvmPayload;
            outMessage.protocolFee = message.tvmProtocolFee;
            outMessage.executorFee = message.tvmExecutorFee;

            uint i;
            for(; i < message.tvmValidExecutors.length;) {
                outMessage.tvmValidExecutors.push(message.tvmValidExecutors[i]);
                unchecked {
                    i++;
                }
            }

            delete i;
            for (; i < toBurn.length;) {
                outMessage.tokensBurned.push(toBurn[i]);
                unchecked {
                    i++;
                }
            }

            delete i;
            for (; i < toLock.length;) {
                outMessage.tokensLocked.push(toLock[i]);
                unchecked {
                    i++;
                }
            }
            delete i;
            for (; i < toBurnNFT.length;) {
                outMessage.nftsBurned.push(toBurnNFT[i]);
                unchecked {
                    i++;
                }
            }
            delete i;
            for (; i < toLockNFT.length;) {
                outMessage.nftsLocked.push(toLockNFT[i]);
                unchecked {
                    i++;
                }
            }
        }

        emit OutMessageProcessed({
            shardsKey: message.shardsKey,
            operationId: operationId,
            callerAddress: msg.sender,
            targetAddress: message.tvmTarget,
            payload: message.tvmPayload,
            protocolFee: message.tvmProtocolFee,
            executorFee: message.tvmExecutorFee,
            tvmValidExecutors: message.tvmValidExecutors,
            tokensBurned: toBurn,
            tokensLocked: toLock,
            nftsBurned: toBurnNFT,
            nftsLocked: toLockNFT
        });

    }

    // View methods

    /**
     * @dev Checks if the input (receive) message has been processed.
     * @param messageHash Message hash to check.
     * @return bool True if the message has been processed, false otherwise.
     */
    function getInMessageState(
         bytes32 messageHash
    ) external view returns (bool) {
        return _processedInMessages[messageHash];
    }

    /**
     * @dev Gets the current min protocol fee.
     * @return uint256 Fee amount.
     */
    function getProtocolFee() public view returns(uint256) {
        return _protocolFee;
    }

    /**
     * @dev Gets collected protocol fee by token address.
     * @return uint256 Collected fee amount.
     */
    function getCollectedProtocolFee() public view returns(uint256) {
        return _collectedProtocolFee;
    }
}
