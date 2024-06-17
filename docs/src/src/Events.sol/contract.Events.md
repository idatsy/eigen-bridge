# Events
[Git Source](https://github.com/idatsy/eigen-bridge/blob/eebec4f167dbfa8749ada8d03753364230dd7d49/src/Events.sol)

Contains event definitions for bridge operations


## Events
### BridgeRequest
Emitted when a new bridge request is created


```solidity
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
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user initiating the bridge request|
|`tokenAddress`|`address`|The address of the token to be bridged|
|`bridgeRequestId`|`uint256`|The unique ID of the bridge request|
|`amountIn`|`uint256`|The amount of tokens to be bridged|
|`amountOut`|`uint256`|The amount of tokens expected at the destination|
|`destinationVault`|`address`|The address of the destination vault|
|`destinationAddress`|`address`|The address of the recipient at the destination|
|`transferIndex`|`uint256`|The transfer index for unique tracking|

### AVSAttestation
Emitted when an attestation is published by an AVS operator


```solidity
event AVSAttestation(bytes indexed attestation, uint256 indexed bridgeRequestId, uint256 indexed operatorWeight);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`attestation`|`bytes`|The attestation data|
|`bridgeRequestId`|`uint256`|The ID of the bridge request|
|`operatorWeight`|`uint256`|The weight of the operator attesting|

### FundsReleased
Emitted when funds are released to the destination address


```solidity
event FundsReleased(address indexed destinationVault, address indexed destinationAddress, uint256 indexed amountOut);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`destinationVault`|`address`|The address of the destination vault|
|`destinationAddress`|`address`|The address of the recipient at the destination|
|`amountOut`|`uint256`|The amount of tokens released|

