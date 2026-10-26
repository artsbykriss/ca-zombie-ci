// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256 price);

    function price_oracle() external view returns (uint256);

    function price_oracle(uint256 i) external view returns (uint256);

    function balances(uint256 _id) external view returns (uint256);

    function calc_token_amount(
        uint256[2] memory _amounts,
        bool _is_deposit
    ) external view returns (uint256);

    function calc_token_amount(
        uint256[] memory _amounts,
        bool _is_deposit
    ) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

    function add_liquidity(uint256[2] memory amounts, uint256 _min_mint_amount) external;

    function add_liquidity(uint256[] memory amounts, uint256 _min_mint_amount) external;
}