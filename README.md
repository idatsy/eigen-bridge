# Proof of Concept Cross-Chain Bridge Secured by EigenLayer

![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)
![License](https://img.shields.io/badge/license-UNLICENSED-blue.svg)

## Overview

This project is a proof of concept for a decentralized bridge secured with attestations by EigenLayer's AVS operators.
The goal is to demonstrate how EigenLayer can be used to secure cross-chain token transfers without direct communication between chains.
Arbitrary message passing allows not only instantaneous settlement but also the ability to transfer between non VM-compatible chains such as Ethereum and Solana, or Bitcoin.

### What is EigenLayer?

EigenLayer is a protocol that allows operators to receive delegated stake in order to secure various applications (such as applications relying on off-chain state).
Operators are incentivized through application rewards and penalized through stake slashing if they act maliciously.

EigenLayer relies on at least one smart contract interacting with the EigenLayer protocol, that registers and tracks operators and their stake, as well as defines the rules for rewards and penalties.

### Objective

This proof of concept aims to showcase the potential of EigenLayer in securing decentralized bridges. It includes smart contracts that handle bridging operations, attestation verification, and slashing mechanisms.

## Project Structure

- **Contracts**:
  - `ECDSAUtils.sol`: Provides ECDSA signature utilities.
  - `EigenLayerBridge.sol`: Manages bridge operations and attestation validations.
  - `PermissionedBridge.sol`: Manages bridge operations with manually set operator weights.
  - `Events.sol`: Contains event definitions for bridge operations.
  - `Structs.sol`: Defines structs and related functions for bridge operations.
  - `Vault.sol`: Abstract contract providing common vault functionality for bridge contracts.

- **Tests**:
  - `EigenLayerBridge.t.sol`: Tests for `EigenLayerBridge.sol`.
  - `PermissionedBridge.t.sol`: Tests for `PermissionedBridge.sol`.

## Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-repo/eigenlayer-bridge.git
   cd eigenlayer-bridge
   ```

2. **Install Foundry**:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

### Running Tests

To run the tests, use the Foundry framework. Running the tests requires an HTTP endpoint to Ethereum mainnet.

> The tests use an anvil fork-test from latest Ethereum mainnet state in order to simulate a realistic environment and test against the EigenLayer contracts deployed there.

```bash
forge test --rpc-url <RPC_URL>
```

## Detailed Explanations

### ECDSA Signature Verification

The `ECDSAUtils` contract provides utilities for verifying ECDSA signatures. These utilities are essential for ensuring the authenticity and integrity of the bridge request data. The process involves two main functions:

1. **getDigest**: Computes the EIP712 digest of the bridge request data, which is used for signing.
2. **getSigner**: Recovers the signer's address from the given bridge request data and signature.

#### Example Function: `getDigest`

This function computes the EIP712 digest for the given bridge request data, ensuring that the data can be signed in a standardized and secure way.

```solidity
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
```

### Attestation Mechanism

The attestation mechanism leverages EigenLayer's AVS operators to secure the bridge. Here's a detailed explanation of the process:

1. **Bridge Request Creation**: A user creates a bridge request, which is stored on-chain and emits an event for operators to observe.
2. **Signature Collection**: AVS operators observe the bridge request event and sign the request data using their private keys. These signatures are then submitted back to the bridge contract.
3. **Attestation Verification**: The bridge contract verifies these signatures to ensure they are from valid operators with sufficient stake.
4. **Fund Release**: Once the contract verifies that enough valid signatures (attestations) have been collected, it releases the funds to the destination address.

#### Example Function: `publishAttestation`

This function allows an AVS operator to publish an attestation for a bridge request. It verifies the operator's weight and ensures no double attestations for the same request.

```solidity
function publishAttestation(bytes memory attestation, uint256 _bridgeRequestId) public nonReentrant onlyOperator {
    require(operatorHasMinimumWeight(msg.sender), "Operator does not have minimum weight");
    require(!operatorResponses[msg.sender][_bridgeRequestId], "Operator has already responded to the task");
    require(msg.sender == getSigner(bridgeRequests[_bridgeRequestId], attestation), "Invalid attestation signature");

    uint256 operatorWeight = getOperatorWeight(msg.sender);
    bridgeRequestWeights[_bridgeRequestId] += operatorWeight;

    rewardAttestation(msg.sender);

    emit AVSAttestation(attestation, _bridgeRequestId, operatorWeight);
}
```

### Fund Release Process

The fund release process is critical to ensuring that the bridge operates securely and efficiently. The process involves the following steps:

1. **Signature Verification**: The contract verifies that the submitted signatures are valid and from authorized operators.
2. **Weight Calculation**: It sums the weights of the valid signatures to ensure that the total weight meets or exceeds the required threshold.
3. **Fund Transfer**: If the total weight is sufficient, the contract transfers the funds to the destination address.
4. **Incentivizing Validators**: The contract pays out gas costs and a small incentive to the caller who initiates the fund release, encouraging users to participate in this final step.

#### Example Function: `releaseFunds`

This function releases the funds to the destination address once the required attestations are verified. It ensures the transaction's economic security by checking the total attested weight.

```solidity
function releaseFunds(bytes[] memory signatures, Structs.BridgeRequestData memory data) public nonReentrant {
    uint256 totalWeight = 0;
    for (uint256 i = 0; i < signatures.length; i++) {
        address signer = getSigner(data, signatures[i]);
        require(operatorResponses[signer][data.transferIndex], "Invalid signature");
        totalWeight += getOperatorWeight(signer);
    }

    require(totalWeight >= data.amountOut, "Insufficient total weight to cover swap");
    IERC20(data.tokenAddress).transfer(data.destinationAddress, data.amountOut);

    payoutCrankGasCost();

    emit FundsReleased(data.tokenAddress, data.destinationAddress, data.amountOut);
}
```

### AVS Interactions

EigenLayer's AVS operators play a crucial role in the security of the bridge. These operators:

1. **Monitor**: Observe events emitted by the bridge contract to detect new bridge requests.
2. **Sign**: Validate the bridge request and provide their signature as an attestation.
3. **Submit**: Send their attestations back to the bridge contract.
4. **Get Rewarded**: Receive rewards for valid attestations and get penalized for any malicious activities through slashing.

These interactions ensure that the bridge is both secure and decentralized, relying on the collective security provided by the EigenLayer's staked operators.

## Testing

### Introduction

This section covers the testing of our smart contracts using the Forge test framework. The tests are written in Solidity and simulate various scenarios to ensure the correctness of the bridge operations and attestation mechanisms.

### Setting Up the Test Environment

The test environment is set up using the `setUp` function in each test contract. This function initializes the contract instances, allocates initial balances, and configures the necessary parameters.

#### Example Setup Function

```solidity
function setUp() public {
    (operator, operatorPrivateKey) = makeAddrAndKey("operator");

    localVault = new BridgeServiceManager(
        aVSDirectory, stakeRegistry, rewardsCoordinator, delegationManager,
        crankGasCost, 0, bridgeFee, "PermissionedBridge", "1"
    );
    localVault.initialize();

    remoteVault = new BridgeServiceManager(
        aVSDirectory, stakeRegistry, rewardsCoordinator, delegationManager,
        crankGasCost, 0, bridgeFee, "PermissionedBridge", "1"
    );
    remoteVault.initialize();

    deal(bob, 1 ether);
    deal(usdc, bob, 1000 * 10**6);
    deal(usdc, address(remoteVault), 1000 * 10**6);
    deal(operator, 1 ether);
}
```

### Test Cases

#### Test Case 1: Bridge Request Emission

This test case ensures that a bridge request emits the correct events when created.

```solidity
function testBridgeRequestEmitEvents() public returns (Structs.BridgeRequestData memory) {
    vm.startPrank(bob);

    IERC20(usdc).approve(address(localVault), 1000 * 10**6);

    vm.expectEmit(true, true, true, true);
    emit Events.BridgeRequest(bob, usdc, 0, 1000 * 10**6, 1000 * 10**6, address(remote

Vault), alice, 0);

    localVault.bridge{value: bridgeFee}(usdc, 1000 * 10**6, 1000 * 10**6, address(remoteVault), alice);

    vm.stopPrank();

    return Structs.BridgeRequestData(
        bob,
        usdc,
        1000 * 10**6,
        1000 * 10**6,
        address(remoteVault),
        alice,
        0
    );
}
```

#### Test Case 2: Operator Attestation Submission

This test case verifies that an operator can submit an attestation for a bridge request.

```solidity
function testOperatorCanSubmitAttestation() public {
    testBridgeRequestEmitEvents();

    (
    address user,
    address tokenAddress,
    uint256 amountIn,
    uint256 amountOut,
    address destinationVault,
    address destinationAddress,
    uint256 transferIndex
    ) = localVault.bridgeRequests(0);

    Structs.BridgeRequestData memory bridgeRequest = Structs.BridgeRequestData(
        user,
        tokenAddress,
        amountIn,
        amountOut,
        destinationVault,
        destinationAddress,
        transferIndex
    );

    bytes memory attestation = signBridgeRequestData(localVault, bridgeRequest, operatorPrivateKey);

    vm.prank(operator);
    vm.expectEmit(true, true, true, true);
    emit Events.AVSAttestation(attestation, 0, 1000 ether);

    localVault.publishAttestation(attestation, 0);
}
```

#### Test Case 3: Fund Release Completion

This test case ensures that the bridge completes and releases funds correctly.

```solidity
function testBridgeCompletesReleaseFunds() public {
    testBridgeRequestEmitEvents();

    (
        address user,
        address tokenAddress,
        uint256 amountIn,
        uint256 amountOut,
        address destinationVault,
        address destinationAddress,
        uint256 transferIndex
    ) = localVault.bridgeRequests(0);

    Structs.BridgeRequestData memory bridgeRequest = Structs.BridgeRequestData(
        user,
        tokenAddress,
        amountIn,
        amountOut,
        destinationVault,
        destinationAddress,
        transferIndex
    );

    bytes memory attestation = signBridgeRequestData(remoteVault, bridgeRequest, operatorPrivateKey);
    bytes[] memory bridgeRequestSignatures = new bytes[](1);
    bridgeRequestSignatures[0] = attestation;

    assertEq(IERC20(usdc).balanceOf(address(remoteVault)), 1000 * 10**6);
    assertEq(IERC20(usdc).balanceOf(alice), 0);

    vm.prank(alice);
    remoteVault.releaseFunds(bridgeRequestSignatures, bridgeRequest);

    assertEq(IERC20(usdc).balanceOf(address(remoteVault)), 0);
    assertEq(IERC20(usdc).balanceOf(alice), 1000 * 10**6);
}
```

## License

This project is licensed under the UNLICENSED License.

## Disclaimer

This project is provided "as is" with no guarantees or warranties. It is intended as a proof of concept only and should not be used in production environments. Use at your own risk.