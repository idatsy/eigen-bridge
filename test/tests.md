# Testing

## Introduction
This section covers the testing of our smart contracts using the Forge test framework. The tests are written in Solidity and simulate various scenarios to ensure the correctness of the bridge operations and attestation mechanisms.

## Setting Up the Test Environment
The test environment is set up using the `setUp` function in each test contract. This function initializes the contract instances, allocates initial balances, and configures the necessary parameters.

### Example Setup Function
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

Test Cases
Test Case 1: Bridge Request Emission
This test case ensures that a bridge request emits the correct events when created.

```solidity
function testBridgeRequestEmitEvents() public returns (Structs.BridgeRequestData memory) {
    vm.startPrank(bob);

    IERC20(usdc).approve(address(localVault), 1000 * 10**6);

    vm.expectEmit(true, true, true, true);
    emit Events.BridgeRequest(bob, usdc, 0, 1000 * 10**6, 1000 * 10**6, address(remoteVault), alice, 0);

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

Test Case 2: Operator Attestation Submission
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

Test Case 3: Fund Release Completion
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