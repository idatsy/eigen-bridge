// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Events {
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

    event AVSAttestation(
        bytes indexed attestation,
        uint256 indexed bridgeRequestId
    );

    event FundsReleased(
        address indexed destinationVault,
        address indexed destinationAddress,
        uint256 indexed amountOut
    );
}