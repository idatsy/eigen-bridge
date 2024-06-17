// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BridgeServiceManager} from "../src/BridgeServiceManager.sol";
import "../src/Events.sol";
import {Structs} from "../src/Structs.sol";
import "openzeppelin/contracts/utils/cryptography/EIP712.sol";

/// @title BridgeServiceManager Test
/// @notice This contract tests the functionalities of the BridgeServiceManager contract using Forge test framework
contract BridgeServiceManagerTest is Test, EIP712("BridgeServiceManager", "1") {
    BridgeServiceManager public localVault;
    BridgeServiceManager public remoteVault;

    address usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    uint256 bridgeFee = 0.005 ether;
    uint256 crankGasCost = 100_000;

    address bob = address(0x123);
    address alice = address(0x456);
    address operator;
    uint256 operatorPrivateKey;

    // MAINNET EIGENLAYER CONTRACTS
    address delegationManager = address(0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37A);
    address aVSDirectory = address(0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37A);
    address rewardsCoordinator = address(0x0BAAc79acD45A023E19345c352d8a7a83C4e5656);
    address stakeRegistry = address(0x006124Ae7976137266feeBFb3F4D2BE4C073139D);

    /// @notice Sets up the test environment
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

    // Add detailed test functions here
}
