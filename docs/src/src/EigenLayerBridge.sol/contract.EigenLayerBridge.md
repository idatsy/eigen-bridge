# EigenLayerBridge
[Git Source](https://github.com/idatsy/eigen-bridge/blob/4bbab8924ec1c5205dc848c3b60057e0c417dbf1/src/EigenLayerBridge.sol)

**Inherits:**
ECDSAServiceManagerBase, [Vault](/src/Vault.sol/abstract.Vault.md)


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

*Constructor for ECDSAServiceManagerBase, initializing immutable contract addresses and disabling initializers.*


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
|`_avsDirectory`|`address`|The address of the AVS directory contract, managing AVS-related data for registered operators.|
|`_stakeRegistry`|`address`|The address of the stake registry contract, managing registration and stake recording.|
|`_rewardsCoordinator`|`address`|The address of the rewards coordinator contract, handling rewards distributions.|
|`_delegationManager`|`address`|The address of the delegation manager contract, managing staker delegations to operators.|
|`_crankGasCost`|`uint256`|The estimated gas cost for calling release funds, used to calculate rebate and incentivise users to call.|
|`_AVSReward`|`uint256`|The total reward for AVS attestation.|
|`_bridgeFee`|`uint256`|The total fee charged to user for bridging.|
|`_name`|`string`|The name of the contract. Used for EIP-712 domain construction.|
|`_version`|`string`|The version of the contract. Used for EIP-712 domain construction.|


### onlyOperator


```solidity
modifier onlyOperator();
```

### rewardAttestation


```solidity
function rewardAttestation(address operator) internal;
```

### publishAttestation


```solidity
function publishAttestation(bytes memory attestation, uint256 _bridgeRequestId) public nonReentrant onlyOperator;
```

### slashMaliciousAttestor


```solidity
function slashMaliciousAttestor(address operator, uint256 penalty) internal;
```

### challengeAttestation


```solidity
function challengeAttestation(
    bytes memory fraudulentSignature,
    Structs.BridgeRequestData memory fraudulentBridgeRequest
) public nonReentrant;
```

### payoutCrankGasCost


```solidity
function payoutCrankGasCost() internal;
```

### _releaseFunds

Release funds to the destination address


```solidity
function _releaseFunds(bytes memory data) public override nonReentrant;
```

### releaseFunds

*Convenience function for releasing funds to the destination address with typed data for ABI construction*


```solidity
function releaseFunds(bytes[] memory signatures, Structs.BridgeRequestData memory data) public nonReentrant;
```

### operatorHasMinimumWeight


```solidity
function operatorHasMinimumWeight(address operator) public view returns (bool);
```

### getOperatorWeight


```solidity
function getOperatorWeight(address operator) public view returns (uint256);
```

### receive


```solidity
receive() external payable;
```

