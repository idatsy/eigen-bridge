// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "eigenlayer-middleware/src/unaudited/ECDSAServiceManagerBase.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./Events.sol";
import "./Structs.sol";
import "./ECDSAUtils.sol";


contract VaultAVS is ECDSAServiceManagerBase, Events, ReentrancyGuard, ECDSAUtils {
    // Stores the transfer index for each user for unique transfer tracking
    mapping(address => uint256) public nextUserTransferIndexes;
    // Tracks bridge requests that this operator has responded to once to avoid duplications
    mapping(address => mapping(uint256=> bool)) public operatorResponses;
    // Tracks the total operator weight attested to a bridge request
    mapping(uint256 => uint256) public bridgeRequestWeights;

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

    modifier onlyOperator() {
        require(
            ECDSAStakeRegistry(stakeRegistry).operatorRegistered(msg.sender)
            ==
            true,
            "Operator must be the caller"
        );
        _;
    }

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

    function publishAttestation(bytes memory attestation, uint256 _bridgeRequestId) public nonReentrant onlyOperator {
        // Check minimum weight requirement
        require(operatorHasMinimumWeight(msg.sender), "Operator does not have minimum weight");
        // Check that operator doesn't respond to the same task twice
        require(!operatorResponses[msg.sender][_bridgeRequestId], "Operator has already responded to the task");
        // Check that the operator is signing the correct bridge request parameters
        require(msg.sender == getSigner(bridgeRequests[_bridgeRequestId], attestation), "Invalid attestation signature");

        // Increment the total weights attested for this bridge request.
        // Helpful for determining when enough attestations have been collected to release funds.
        bridgeRequestWeights[_bridgeRequestId] += getOperatorWeight(msg.sender);

        // Calculate payment for AVS attestation, equals the reward or the contract balance
        uint256 payout = AVSReward;
        if (address(this).balance < payout) {
            payout = address(this).balance;
        }

        // TODO: This is a placeholder for the actual AVS reward distribution pending Eigen M2 implementation
        (bool sent, ) = msg.sender.call{value: payout}("");
        require(sent, "Failed to send AVS reward");

        emit AVSAttestation(attestation, _bridgeRequestId);
    }

    function challengeAttestation(uint256 _bridgeRequestId) public nonReentrant {
        // TODO: Implement slashing logic pending clarity on Eigen implementation
    }

    function operatorHasMinimumWeight(address operator) public view returns (bool) {
        return ECDSAStakeRegistry(stakeRegistry).getOperatorWeight(operator) >= ECDSAStakeRegistry(stakeRegistry).minimumWeight();
    }

    function getOperatorWeight(address operator) public view returns (uint256) {
        return ECDSAStakeRegistry(stakeRegistry).getOperatorWeight(operator);
    }

    receive() external payable {}
}