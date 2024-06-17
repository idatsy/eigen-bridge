# BridgeServiceManager
[Git Source](https://github.com/idatsy/eigen-bridge/blob/c580a263608f0a9abe800c41a2d4bf408db0805d/src/EigenLayerBridge.sol)

**Inherits:**
ECDSAServiceManagerBase, [Vault](/src/Vault.sol/abstract.Vault.md)

Manages bridge operations and attestation validations

*Extends ECDSAServiceManagerBase and Vault for bridging and staking functionality*


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


## Functions
### constructor

Initializes the contract with the necessary addresses and parameters


```solidity
constructor(
    address _avsDirectory,
    address _stakeRegistry,
    address _rewardsCoordinator,
    address _delegationManager,
    uint256 _crankGasCost,
    uint256 _AVSReward,
    uint256 _bridgeFee,
    string memory _name,
    string memory _version
)
    ECDSAServiceManagerBase(_avsDirectory, _stakeRegistry, _rewardsCoordinator, _delegationManager)
    Vault(_crankGasCost, _AVSReward, _bridgeFee, _name, _version);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_avsDirectory`|`address`|The address of the AVS directory contract, managing AVS-related data for registered operators|
|`_stakeRegistry`|`address`|The address of the stake registry contract, managing registration and stake recording|
|`_rewardsCoordinator`|`address`|The address of the rewards coordinator contract, handling rewards distributions|
|`_delegationManager`|`address`|The address of the delegation manager contract, managing staker delegations to operators|
|`_crankGasCost`|`uint256`|The estimated gas cost for calling release funds, used to calculate rebate and incentivize users to call|
|`_AVSReward`|`uint256`|The total reward for AVS attestation|
|`_bridgeFee`|`uint256`|The total fee charged to the user for bridging|
|`_name`|`string`|The name of the contract, used for EIP-712 domain construction|
|`_version`|`string`|The version of the contract, used for EIP-712 domain construction|


### onlyOperator

Ensures that only registered operators can call the function


```solidity
modifier onlyOperator();
```

### rewardAttestation

Rewards the operator for providing a valid attestation

*Placeholder for actual AVS reward distribution pending Eigen M2 implementation*


```solidity
function rewardAttestation(address operator) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|The address of the operator to be rewarded|


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


### slashMaliciousAttestor

Slashes a malicious attestor's stake

*Placeholder for slashing logic pending Eigen implementations*


```solidity
function slashMaliciousAttestor(address operator, uint256 penalty) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operator`|`address`|The address of the operator to be slashed|
|`penalty`|`uint256`|The penalty amount to be slashed|


### challengeAttestation

Challenges a potentially fraudulent attestation


```solidity
function challengeAttestation(
    bytes memory fraudulentSignature,
    Structs.BridgeRequestData memory fraudulentBridgeRequest
) public nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fraudulentSignature`|`bytes`|The signature of the fraudulent attestation|
|`fraudulentBridgeRequest`|`Structs.BridgeRequestData`|The data of the fraudulent bridge request|


### payoutCrankGasCost

Payouts the crank gas cost to the caller


```solidity
function payoutCrankGasCost() internal;
```

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


### receive

Fallback function to receive ether


```solidity
receive() external payable;
```

