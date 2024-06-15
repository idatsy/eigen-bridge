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
    }

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