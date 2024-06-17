// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/PermissionedBridge.sol";
import "../src/Events.sol";
import {Structs} from "../src/Structs.sol";
import "openzeppelin/contracts/utils/cryptography/EIP712.sol";

/// @title PermissionedBridge Test
/// @notice This contract tests the functionalities of the PermissionedBridge contract using Forge test framework
contract PermissionedBridgeTest is Test, EIP712("PermissionedBridge", "1") {
    PermissionedBridge public localVault;
    PermissionedBridge public remoteVault;

    address usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    uint256 bridgeFee = 0.005 ether;
    uint256 crankGasCost = 100_000;

    address bob = address(0x123);
    address alice = address(0x456);
    address operator;
    uint256 operatorPrivateKey;

    /// @notice Sets up the test environment
    function setUp() public {
        (operator, operatorPrivateKey) = makeAddrAndKey("operator");

        localVault = new PermissionedBridge(crankGasCost, 0, bridgeFee, "PermissionedBridge", "1");
        localVault.initialize();
        remoteVault = new PermissionedBridge(crankGasCost, 0, bridgeFee, "PermissionedBridge", "1");
        remoteVault.initialize();

        deal(bob, 1 ether);
        deal(usdc, bob, 1000 * 10**6);
        deal(usdc, address(remoteVault), 1000 * 10**6);
        deal(operator, 1 ether);
        localVault.setOperatorWeight(operator, 1000 ether);
        remoteVault.setOperatorWeight(operator, 1000 ether);
    }

    /// @dev Util function for signing bridge request data. This should be mirrored on frontends and operator implementations.
    function signBridgeRequestData(
        PermissionedBridge forVault, Structs.BridgeRequestData memory data, uint256 pkey
    ) public returns (bytes memory) {
        bytes32 digest = forVault.getDigest(data);

        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(pkey, digest);

        return abi.encodePacked(r1, s1, v1);
    }

    /// @notice Tests if bridge request emits correct events
    /// @return The created bridge request data
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

    /// @notice Tests if an operator can submit an attestation
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

    /// @notice Tests if the bridge completes and releases funds
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
}
