// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

library Token {
    struct Data {
        /// Bytes32 name of the token
        bytes32 name;
        /// ERC20 address, synthetic accounting key, or zero for virtual tokens.
        address tokenAddress;
        /// Whether concrete-token deposits are enabled.
        bool depositEnabled;
        /// Whether concrete-token withdrawals are enabled.
        bool withdrawEnabled;
        /// If the token is used by a product (as either a quote or base asset), it cannot ever be removed.
        bool removeProtected;
        /// Concrete-token capacity in D9, including pending deposits and excluding initiated withdrawals.
        uint256 depositCapacity;
        /// Minimum concrete-token deposit in D9.
        uint256 minDeposit;
        /// Flat concrete-token withdrawal fee in D9.
        uint128 withdrawFee;
        /// Flat concrete-token deposit fee in D9.
        uint128 depositFee;
        /// Address of the OFT contract (or OFTAdapter)
        address oftAddress;
        /// Concrete backing token; nonzero only for synthetic tokens.
        address backingToken;
    }

    function load(bytes32 name) internal pure returns (Data storage $) {
        bytes32 s = keccak256(abi.encode("xyz.meridian.Token.Data", name));
        assembly {
            $.slot := s
        }
    }

    /// @dev Resets a token back to its zero default state.
    function remove(Token.Data storage self) internal {
        self.name = bytes32(0);
        self.tokenAddress = address(0);
        self.depositCapacity = 0;
        self.minDeposit = 0;
        self.withdrawFee = 0;
        self.depositFee = 0;
        self.depositEnabled = false;
        self.withdrawEnabled = false;
        self.removeProtected = false;
        self.oftAddress = address(0);
        self.backingToken = address(0);
    }
}
