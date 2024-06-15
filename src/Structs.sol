// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Structs {
    struct BridgeRequestData {
        address user;
        address tokenAddress;
        uint256 amountIn;
        uint256 amountOut;
        address destinationVault;
        address destinationAddress;
        uint256 transferIndex;
        bytes canonicalAttestation;
    }
}