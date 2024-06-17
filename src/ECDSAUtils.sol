// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin/contracts/utils/cryptography/EIP712.sol";

import "./Structs.sol";

/// @title ECDSA Utilities
/// @notice Provides ECDSA signature utilities for verifying bridge request data
contract ECDSAUtils is EIP712 {
    using ECDSA for bytes32;

    /// @notice Initializes the EIP712 domain with the given name and version
    /// @param name The user-readable name of the signing domain
    /// @param version The current major version of the signing domain
    constructor(string memory name, string memory version) EIP712(name, version) {}

    /// @notice Computes the EIP712 digest for the given bridge request data
    /// @param data The bridge request data to be hashed
    /// @return The EIP712 hash of the given bridge request data
    function getDigest(Structs.BridgeRequestData memory data) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "BridgeRequestData(address user,address tokenAddress,uint256 amountIn,uint256 amountOut,address destinationVault,address destinationAddress,uint256 transferIndex)"
                    ),
                    data.user,
                    data.tokenAddress,
                    data.amountIn,
                    data.amountOut,
                    data.destinationVault,
                    data.destinationAddress,
                    data.transferIndex
                )
            )
        );
    }

    /// @notice Recovers the signer address from the given bridge request data and signature
    /// @param data The bridge request data that was signed
    /// @param signature The ECDSA signature
    /// @return The address of the signer
    function getSigner(Structs.BridgeRequestData memory data, bytes memory signature) public view returns (address) {
        bytes32 digest = getDigest(data);
        return ECDSA.recover(digest, signature);
    }
}
