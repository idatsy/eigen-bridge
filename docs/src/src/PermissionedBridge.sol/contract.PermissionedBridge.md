# PermissionedBridge
[Git Source](https://github.com/idatsy/eigen-bridge/blob/eebec4f167dbfa8749ada8d03753364230dd7d49/src/PermissionedBridge.sol)

**Inherits:**
[Vault](/src/Vault.sol/abstract.Vault.md)

Manages bridge operations with manually set operator weights

*Extends Vault for bridging functionality*


## State Variables
### operatorResponses
Tracks bridge requests that this operator has responded to once to avoid duplications

*Double attestations would technically be valid and allow operators to recursively call until funds are released*


```solidity
mapping(address => mapping(uint256 => bool)) public operatorResponses;
```


### bridgeRequestWeights
Tracks the total operator weight attested to a bridge request

*Helpful for determining when enough attestations have been collected to release funds.*


```solidity
mapping(uint256 => uint256) public bridgeRequestWeights;
```


### operatorWeights
Maps operator addresses to their respective weights

*Temporary solution for illustrative purposes on non-mainnet chains*


```solidity
mapping(address => uint256) public operatorWeights;
```


## Functions
### constructor

Initializes the contract with the necessary parameters


```solidity
constructor(uint256 _crankGasCost, uint256 _AVSReward, uint256 _bridgeFee, string memory _name, string memory _version)
    Vault(_crankGasCost, _AVSReward, _bridgeFee, _name, _version);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_crankGasCost`|`uint256`|The estimated gas cost for calling release funds, used to calculate rebate and incentivize users to call|
|`_AVSReward`|`uint256`|The total reward for AVS attestation|
|`_bridgeFee`|`uint256`|The total fee charged to the user for bridging|
|`_name`|`string`|The name of the contract, used for EIP-712 domain construction|
|`_version`|`string`|The version of the contract, used for EIP-712 domain construction|


### onlyOperator

Ensures that only operators with non-zero weight can call the function


```solidity
modifier onlyOperator();
```

### publishAttestation

Publishes an attestation for a bridge request


```solidity
function publishAttestation(bytes memory attestation, uint256 _bridgeRequestId) public nonReentrant onlyOperator;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`attestation`|`bytes`|The signed attestation|
|`_bridgeRequestId`|`uint256`|The ID of the bridge request|


### _releaseFunds

Releases funds to the destination address


```solidity
function _releaseFunds(bytes memory data) public override nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`data`|`bytes`|The bridge request data and signatures|


### releaseFunds

Releases funds to the destination address with typed data for ABI construction


```solidity
function releaseFunds(bytes[] memory signatures, Structs.BridgeRequestData memory data) public nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`signatures`|`bytes[]`|The signatures of the operators attesting to the bridge request|
|`data`|`Structs.BridgeRequestData`|The bridge request data|


### operatorHasMinimumWeight

Checks if the operator has the minimum required weight


```solidity
function operatorHasMinimumWeight(address operator) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|The address of the operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the operator has the minimum weight, false otherwise|


### getOperatorWeight

Gets the weight of an operator


```solidity
function getOperatorWeight(address operator) public view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|The address of the operator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The weight of the operator|


### setOperatorWeight

Sets the weight of an operator


```solidity
function setOperatorWeight(address operator, uint256 weight) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|The address of the operator|
|`weight`|`uint256`|The new weight of the operator|


### receive

Fallback function to receive ether


```solidity
receive() external payable;
```

