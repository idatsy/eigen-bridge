# Vault
[Git Source](https://github.com/idatsy/eigen-bridge/blob/b48404690919046d685c16cb037d35d4bd1626d5/src/Vault.sol)

**Inherits:**
[ECDSAUtils](/src/ECDSAUtils.sol/contract.ECDSAUtils.md), [Events](/src/Events.sol/contract.Events.md), ReentrancyGuard, OwnableUpgradeable

Abstract contract providing common vault functionality for bridge contracts


## State Variables
### nextUserTransferIndexes
Stores the transfer index for each user for unique transfer tracking


```solidity
mapping(address => uint256) public nextUserTransferIndexes;
```


### currentBridgeRequestId
Global unique bridge request ID


```solidity
uint256 public currentBridgeRequestId;
```


### bridgeRequests
Stores history of bridge requests


```solidity
mapping(uint256 => Structs.BridgeRequestData) public bridgeRequests;
```


### bridgeFee
Total fee charged to the user for bridging


```solidity
uint256 public bridgeFee;
```


### AVSReward
Total reward for AVS attestation


```solidity
uint256 public AVSReward;
```


### crankGasCost
Estimated gas cost for calling release funds, used to calculate rebate and incentivize users to call


```solidity
uint256 public crankGasCost;
```


### deployer
Address of the contract deployer


```solidity
address deployer;
```


## Functions
### constructor

Initializes the contract with the necessary parameters


```solidity
constructor(uint256 _crankGasCost, uint256 _AVSReward, uint256 _bridgeFee, string memory _name, string memory _version)
    ECDSAUtils(_name, _version);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_crankGasCost`|`uint256`|The estimated gas cost for calling release funds, used to calculate rebate and incentivize users to call|
|`_AVSReward`|`uint256`|The total reward for AVS attestation|
|`_bridgeFee`|`uint256`|The total fee charged to the user for bridging|
|`_name`|`string`|The name of the contract, used for EIP-712 domain construction|
|`_version`|`string`|The version of the contract, used for EIP-712 domain construction|


### initialize

Initializes the contract and transfers ownership to the deployer


```solidity
function initialize() public initializer;
```

### setBridgeFee

Sets the bridge fee


```solidity
function setBridgeFee(uint256 _bridgeFee) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_bridgeFee`|`uint256`|The new bridge fee|


### setAVSReward

Sets the AVS reward


```solidity
function setAVSReward(uint256 _AVSReward) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_AVSReward`|`uint256`|The new AVS reward|


### setCrankGasCost

Sets the crank gas cost


```solidity
function setCrankGasCost(uint256 _crankGasCost) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_crankGasCost`|`uint256`|The new crank gas cost|


### bridgeERC20

Internal function to transfer ERC20 tokens for bridging


```solidity
function bridgeERC20(address tokenAddress, uint256 amountIn) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|The address of the token to be transferred|
|`amountIn`|`uint256`|The amount of tokens to be transferred|


### bridge

Initiates a bridge request


```solidity
function bridge(
    address tokenAddress,
    uint256 amountIn,
    uint256 amountOut,
    address destinationVault,
    address destinationAddress
) public payable nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|The address of the token to be bridged|
|`amountIn`|`uint256`|The amount of tokens to be bridged|
|`amountOut`|`uint256`|The amount of tokens expected at the destination|
|`destinationVault`|`address`|The address of the destination vault|
|`destinationAddress`|`address`|The address of the recipient at the destination|


### _releaseFunds

Abstract function to release funds, to be implemented by inheriting contracts


```solidity
function _releaseFunds(bytes memory data) public virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`data`|`bytes`|The bridge request data and signatures|


