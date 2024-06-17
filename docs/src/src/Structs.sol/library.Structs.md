# Structs
[Git Source](https://github.com/idatsy/eigen-bridge/blob/c580a263608f0a9abe800c41a2d4bf408db0805d/src/Structs.sol)

Contains struct definitions and related functions for bridge operations


## Functions
### hash

Computes the hash of the bridge request data


```solidity
function hash(BridgeRequestData memory data) internal pure returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`data`|`BridgeRequestData`|The bridge request data to be hashed|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|The hash of the given bridge request data|


## Structs
### BridgeRequestData
Structure representing bridge request data


```solidity
struct BridgeRequestData {
    address user;
    address tokenAddress;
    uint256 amountIn;
    uint256 amountOut;
    address destinationVault;
    address destinationAddress;
    uint256 transferIndex;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user initiating the bridge request|
|`tokenAddress`|`address`|The address of the token to be bridged|
|`amountIn`|`uint256`|The amount of tokens to be bridged|
|`amountOut`|`uint256`|The amount of tokens expected at the destination|
|`destinationVault`|`address`|The address of the destination vault|
|`destinationAddress`|`address`|The address of the recipient at the destination|
|`transferIndex`|`uint256`|The transfer index for unique tracking|

