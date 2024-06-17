// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title Event Definitions
/// @notice Contains event definitions for bridge operations
contract Events {
    /// @notice Emitted when a new bridge request is created
    /// @param user The address of the user initiating the bridge request
    /// @param tokenAddress The address of the token to be bridged
    /// @param bridgeRequestId The unique ID of the bridge request
    /// @param amountIn The amount of tokens to be bridged
    /// @param amountOut The amount of tokens expected at the destination
    /// @param destinationVault The address of the destination vault
    /// @param destinationAddress The address of the recipient at the destination
    /// @param transferIndex The transfer index for unique tracking
    event BridgeRequest(
        address indexed user,
        address indexed tokenAddress,
        uint256 indexed bridgeRequestId,
        uint256 amountIn,
        uint256 amountOut,
        address destinationVault,
        address destinationAddress,
        uint256 transferIndex
    );

    /// @notice Emitted when an attestation is published by an AVS operator
    /// @param attestation The attestation data
    /// @param bridgeRequestId The ID of the bridge request
    /// @param operatorWeight The weight of the operator attesting
    event AVSAttestation(
        bytes indexed attestation,
        uint256 indexed bridgeRequestId,
        uint256 indexed operatorWeight
    );

    /// @notice Emitted when funds are released to the destination address
    /// @param destinationVault The address of the destination vault
    /// @param destinationAddress The address of the recipient at the destination
    /// @param amountOut The amount of tokens released
    event FundsReleased(
        address indexed destinationVault,
        address indexed destinationAddress,
        uint256 indexed amountOut
    );
}
