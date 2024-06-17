# Vault
[Git Source](https://github.com/idatsy/eigen-bridge/blob/ba02380b529b1b58f7d32ebb56870074714e37df/src/Vault.sol)

**Inherits:**
[ECDSAUtils](/src/ECDSAUtils.sol/contract.ECDSAUtils.md), [Events](/src/Events.sol/contract.Events.md), ReentrancyGuard, OwnableUpgradeable

*this looks weird, but has to be imported from the same location as any sibling contracts*


## State Variables
### nextUserTransferIndexes
Stores the transfer index for each user for unique transfer tracking

*conveniently solidity mappings start at 0 when uninitialized so we don't have to worry about new users*


```solidity
mapping(address => uint256) public nextUserTransferIndexes;
```


### currentBridgeRequestId

```solidity
uint256 public currentBridgeRequestId;
```


### bridgeRequests

```solidity
mapping(uint256 => Structs.BridgeRequestData) public bridgeRequests;
```


### bridgeFee

```solidity
uint256 public bridgeFee;
```


### AVSReward

```solidity
uint256 public AVSReward;
```


### crankGasCost

```solidity
uint256 public crankGasCost;
```


## Functions
### constructor


```solidity
constructor(uint256 _crankGasCost, uint256 _AVSReward, uint256 _bridgeFee, string memory _name, string memory _version)
    ECDSAUtils(_name, _version);
```

### setBridgeFee


```solidity
function setBridgeFee(uint256 _bridgeFee) external onlyOwner;
```

### setAVSReward


```solidity
function setAVSReward(uint256 _AVSReward) external onlyOwner;
```

### setCrankGasCost


```solidity
function setCrankGasCost(uint256 _crankGasCost) external onlyOwner;
```

### bridgeERC20


```solidity
function bridgeERC20(address tokenAddress, uint256 amountIn) internal;
```

### bridge


```solidity
function bridge(
    address tokenAddress,
    uint256 amountIn,
    uint256 amountOut,
    address destinationVault,
    address destinationAddress
) public payable nonReentrant;
```

