// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";

import {ECDSAUtils} from "./ECDSAUtils.sol";
import {Structs} from "./Structs.sol";
import {Events} from "./Events.sol";

contract Vault is ECDSAUtils, Events, ReentrancyGuard, OwnableUpgradeable {
    /// @notice Stores the transfer index for each user for unique transfer tracking
    /// @dev conveniently solidity mappings start at 0 when uninitialized so we don't have to worry about new users
    mapping(address => uint256) public nextUserTransferIndexes;
    // Global unique bridge request ID
    uint256 public currentBridgeRequestId;
    // Stores history of bridge requests
    mapping(uint256 => Structs.BridgeRequestData) public bridgeRequests;

    // Total fee charged to user for bridging
    uint256 public bridgeFee;
    // Total reward for AVS attestation
    uint256 public AVSReward;
    // Estimated gas cost for calling release funds, used to calculate rebate and incentivise users to call
    uint256 public crankGasCost;

    constructor(
        uint256 _crankGasCost, uint256 _AVSReward, uint256 _bridgeFee, string memory _name, string memory _version
    ) ECDSAUtils(_name, _version) {
        crankGasCost = _crankGasCost;
        AVSReward = _AVSReward;
        bridgeFee = _bridgeFee;
    }

    /* Access control functions and fee setters */

    function setBridgeFee(uint256 _bridgeFee) external onlyOwner {
        bridgeFee = _bridgeFee;
    }

    function setAVSReward(uint256 _AVSReward) external onlyOwner {
        AVSReward = _AVSReward;
    }

    function setCrankGasCost(uint256 _crankGasCost) external onlyOwner {
        crankGasCost = _crankGasCost;
    }

    /* Bridge functions */

    function bridgeERC20(address tokenAddress, uint256 amountIn) internal {
        bool success = IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amountIn
        );
        require(success, "Transfer failed");
    }

    function bridge(
        address tokenAddress,
        uint256 amountIn,
        uint256 amountOut,
        address destinationVault,
        address destinationAddress
    ) public payable nonReentrant {
        require(msg.value == bridgeFee, "Incorrect bridge fee");

        bridgeERC20(tokenAddress, amountIn);
        uint256 transferIndex = nextUserTransferIndexes[msg.sender];

        emit BridgeRequest(
            msg.sender,
            tokenAddress,
            currentBridgeRequestId,
            amountIn,
            amountOut,
            destinationVault,
            destinationAddress,
            transferIndex
        );

        bridgeRequests[currentBridgeRequestId] = Structs.BridgeRequestData(
            msg.sender,
            tokenAddress,
            amountIn,
            amountOut,
            destinationVault,
            destinationAddress,
            transferIndex
        );

        currentBridgeRequestId++;
        nextUserTransferIndexes[msg.sender]++;
    }
}
