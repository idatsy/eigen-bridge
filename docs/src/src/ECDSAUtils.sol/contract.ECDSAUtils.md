# ECDSAUtils
[Git Source](https://github.com/idatsy/eigen-bridge/blob/eebec4f167dbfa8749ada8d03753364230dd7d49/src/ECDSAUtils.sol)

**Inherits:**
EIP712

Provides ECDSA signature utilities for verifying bridge request data


## Functions
### constructor

Initializes the EIP712 domain with the given name and version


```solidity
constructor(string memory name, string memory version) EIP712(name, version);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name`|`string`|The user-readable name of the signing domain|
|`version`|`string`|The current major version of the signing domain|


### getDigest

Computes the EIP712 digest for the given bridge request data


```solidity
function getDigest(Structs.BridgeRequestData memory data) public view returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`data`|`Structs.BridgeRequestData`|The bridge request data to be hashed|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|The EIP712 hash of the given bridge request data|


### getSigner

Recovers the signer address from the given bridge request data and signature


```solidity
function getSigner(Structs.BridgeRequestData memory data, bytes memory signature) public view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`data`|`Structs.BridgeRequestData`|The bridge request data that was signed|
|`signature`|`bytes`|The ECDSA signature|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the signer|


