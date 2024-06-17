// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import {ECDSAUtils} from "./ECDSAUtils.sol";
import {Structs} from "./Structs.sol";
import {Events} from "./Events.sol";

/// @title Vault
/// @notice Abstract contract providing common vault functionality for bridge contracts
abstract contract Vault is ECDSAUtils, Events, ReentrancyGuard, OwnableUpgradeable {
    /// @notice Stores the transfer index for each user for unique transfer tracking
    mapping(address => uint256) public nextUserTransferIndexes;

    /// @notice Global unique bridge request ID
    uint256 public currentBridgeRequestId;

    /// @notice Stores history of bridge requests
    mapping(uint256 => Structs.BridgeRequestData) public bridgeRequests;

    /// @notice Total fee charged to the user for bridging
    uint256 public bridgeFee;

    /// @notice Total reward for AVS attestation
    uint256 public AVSReward;

    /// @notice Estimated gas cost for calling release funds, used to calculate rebate and incentivize users to call
    uint256 public crankGasCost;

    /// @notice Address of the contract deployer
    address deployer;

    /**
     * @notice Initializes the contract with the necessary parameters
     * @param _crankGasCost The estimated gas cost for calling release funds, used to calculate rebate and incentivize users to call
     * @param _AVSReward The total reward for AVS attestation
     * @param _bridgeFee The total fee charged to the user for bridging
     * @param _name The name of the contract, used for EIP-712 domain construction
     * @param _version The version of the contract, used for EIP-712 domain construction
     */
    constructor(
        uint256 _crankGasCost, uint256 _AVSReward, uint256 _bridgeFee, string memory _name, string memory _version
    ) ECDSAUtils(_name, _version) {
        crankGasCost = _crankGasCost;
        AVSReward = _AVSReward;
        bridgeFee = _bridgeFee;

        deployer = msg.sender;
    }

    /// @notice Initializes the contract and transfers ownership to the deployer
    function initialize() public initializer {
        __Ownable_init();
        transferOwnership(deployer);
    }

    /// @notice Sets the bridge fee
    /// @param _bridgeFee The new bridge fee
    function setBridgeFee(uint256 _bridgeFee) external onlyOwner {
        bridgeFee = _bridgeFee;
    }

    /// @notice Sets the AVS reward
    /// @param _AVSReward The new AVS reward
    function setAVSReward(uint256 _AVSReward) external onlyOwner {
        AVSReward = _AVSReward;
    }

    /// @notice Sets the crank gas cost
    /// @param _crankGasCost The new crank gas cost
    function setCrankGasCost(uint256 _crankGasCost) external onlyOwner {
        crankGasCost = _crankGasCost;
    }

    /// @notice Internal function to transfer ERC20 tokens for bridging
    /// @param tokenAddress The address of the token to be transferred
    /// @param amountIn The amount of tokens to be transferred
    function bridgeERC20(address tokenAddress, uint256 amountIn) internal {
        bool success = IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amountIn
        );
        require(success, "Transfer failed");
    }

    /**
     * @notice Initiates a bridge request
     * @param tokenAddress The address of the token to be bridged
     * @param amountIn The amount of tokens to be bridged
     * @param amountOut The amount of tokens expected at the destination
     * @param destinationVault The address of the destination vault
     * @param destinationAddress The address of the recipient at the destination
     */
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

    /// @notice Abstract function to release funds, to be implemented by inheriting contracts
    /// @param data The bridge request data and signatures
    function _releaseFunds(bytes memory data) public virtual;
}
