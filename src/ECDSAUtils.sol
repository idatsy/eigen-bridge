// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin/contracts/utils/cryptography/EIP712.sol";

import "./Structs.sol";

contract ECDSAUtils is EIP712 {
    using ECDSA for bytes32;

    constructor(string memory name, string memory version) EIP712(name, version) {}

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

    function getSigner(Structs.BridgeRequestData memory data, bytes memory signature) public view returns (address) {
        bytes32 digest = getDigest(data);
        return ECDSA.recover(digest, signature);
    }
}
