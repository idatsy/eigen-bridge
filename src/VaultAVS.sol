// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "eigenlayer-middleware/src/unaudited/ECDSAServiceManagerBase.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./Events.sol";
import "./Structs.sol";
import "./ECDSAUtils.sol";


contract VaultAVS is ECDSAServiceManagerBase, Events, ReentrancyGuard, ECDSAUtils {
    mapping(address => uint256) public nextUserTransferIndexes;
//    mapping(address => bool) public whitelistedSigners;
    mapping(address => mapping(address => uint256)) public userDeposits;

    uint256 public currentBridgeRequestId;
    mapping(uint256 => Structs.BridgeRequestData) public bridgeRequests;

    uint256 public bridgeFee;
    uint256 public AVSReward;
    uint256 public crankGasCost;
    address public canonicalSigner;

    /**
     * @dev Constructor for ECDSAServiceManagerBase, initializing immutable contract addresses and disabling initializers.
     * @param _avsDirectory The address of the AVS directory contract, managing AVS-related data for registered operators.
     * @param _stakeRegistry The address of the stake registry contract, managing registration and stake recording.
     * @param _rewardsCoordinator The address of the rewards coordinator contract, handling rewards distributions.
     * @param _delegationManager The address of the delegation manager contract, managing staker delegations to operators.
     */
    constructor(
        address _avsDirectory,
        address _stakeRegistry,
        address _rewardsCoordinator,
        address _delegationManager,
        address _canonicalSigner,
        uint256 _crankGasCost,
        uint256 _AVSReward,
        uint256 _bridgeFee
    )
        ECDSAServiceManagerBase(
            _avsDirectory,
            _stakeRegistry,
            _rewardsCoordinator,
            _delegationManager
        )
        ECDSAUtils("Zarathustra", "1")
    {
        crankGasCost = _crankGasCost;
        AVSReward = _AVSReward;
        bridgeFee = _bridgeFee;

        canonicalSigner = _canonicalSigner;
        currentBridgeRequestId = 0;
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

    function bridgeERC20(address tokenAddress, uint256 amountIn) internal {
        bool success = IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amountIn
        );
        require(success, "Transfer failed");
        userDeposits[msg.sender][tokenAddress] += amountIn;
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

    function publishAttestation(bytes memory attestation, uint256 _bridgeRequestId) public nonReentrant {
        emit AVSAttestation(attestation, _bridgeRequestId);

        uint256 payout = AVSReward;
        if (address(this).balance < payout) {
            payout = address(this).balance;
        }

        // TODO: This is a placeholder for the actual AVS reward distribution pending Eigen M2 implementation
        (bool sent, ) = msg.sender.call{value: payout}("");
        require(sent, "Failed to send AVS reward");
    }

}