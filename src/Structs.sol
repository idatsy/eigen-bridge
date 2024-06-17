// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title Struct Definitions
/// @notice Contains struct definitions and related functions for bridge operations
library Structs {
    /// @notice Structure representing bridge request data
    /// @param user The address of the user initiating the bridge request
    /// @param tokenAddress The address of the token to be bridged
    /// @param amountIn The amount of tokens to be bridged
    /// @param amountOut The amount of tokens expected at the destination
    /// @param destinationVault The address of the destination vault
    /// @param destinationAddress The address of the recipient at the destination
    /// @param transferIndex The transfer index for unique tracking
    struct BridgeRequestData {
        address user;
        address tokenAddress;
        uint256 amountIn;
        uint256 amountOut;
        address destinationVault;
        address destinationAddress;
        uint256 transferIndex;
    }

    /// @notice Computes the hash of the bridge request data
    /// @param data The bridge request data to be hashed
    /// @return The hash of the given bridge request data
    function hash(BridgeRequestData memory data) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            data.user,
            data.tokenAddress,
            data.amountIn,
            data.amountOut,
            data.destinationVault,
            data.destinationAddress,
            data.transferIndex
        ));
    }
}
