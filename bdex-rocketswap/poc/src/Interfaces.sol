// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function mint(address, uint256) external;
}

interface IBridgeToken {
    function mintPublic(address to, uint256 amount) external;
    function mintPrivate(address to, uint256 amount) external;
    function burnFromPublic(address account, uint256 amount) external;
    function owner() external view returns (address);
    function publicBridge() external view returns (address);
    function privateBridge() external view returns (address);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
    function totalSupply() external view returns (uint256);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function mint(address to) external returns (uint256);
    function burn(address to) external returns (uint256, uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
}

interface IUniswapV2Factory {
    function getPair(address, address) external view returns (address);
    function allPairsLength() external view returns (uint256);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
}

interface IUniswapV3Factory {
    function getPool(address, address, uint24) external view returns (address);
    function owner() external view returns (address);
    function feeAmountTickSpacing(uint24) external view returns (int24);
}

interface IUniswapV3Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function liquidity() external view returns (uint128);
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
    function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes calldata data)
        external
        returns (int256 amount0, int256 amount1);
}

interface IHyperlaneMailbox {
    function process(bytes calldata _metadata, bytes calldata _message) external payable;
    function recipientIsm(address _recipient) external view returns (address);
    function defaultIsm() external view returns (address);
    function localDomain() external view returns (uint32);
    function VERSION() external view returns (uint8);
}

interface IInterchainSecurityModule {
    function moduleType() external view returns (uint8);
    function verify(bytes calldata _metadata, bytes calldata _message) external view returns (bool);
}

interface IMultisigIsm {
    function validatorsAndThreshold(bytes calldata _message) external view returns (address[] memory, uint8);
}

interface IProtocolReserve {
    function withdraw(address token, address to, uint256 amount, bytes32 id) external;
    function deposit(address token, uint256 amount, bytes32 id) external;
    function dai() external view returns (address);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
}
