// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "eigenlayer-middleware/src/unaudited/ECDSAServiceManagerBase.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Events.sol";
import "./Structs.sol";
import "./ECDSAUtils.sol";
import "./Vault.sol";

/// @title Bridge Service Manager
/// @notice Manages bridge operations and attestation validations
/// @dev Extends ECDSAServiceManagerBase and Vault for bridging and staking functionality
contract BridgeServiceManager is ECDSAServiceManagerBase, Vault {
    using Structs for Structs.BridgeRequestData;

    /// @notice Tracks bridge requests that this operator has responded to once to avoid duplications
    /// @dev Double attestations would technically be valid and allow operators to recursively call until funds are released
    mapping(address => mapping(uint256 => bool)) public operatorResponses;

    /// @notice Tracks the total operator weight attested to a bridge request
    /// @dev Helpful for determining when enough attestations have been collected to release funds.
    mapping(uint256 => uint256) public bridgeRequestWeights;

    /**
     * @notice Initializes the contract with the necessary addresses and parameters
     * @param _avsDirectory The address of the AVS directory contract, managing AVS-related data for registered operators
     * @param _stakeRegistry The address of the stake registry contract, managing registration and stake recording
     * @param _rewardsCoordinator The address of the rewards coordinator contract, handling rewards distributions
     * @param _delegationManager The address of the delegation manager contract, managing staker delegations to operators
     * @param _crankGasCost The estimated gas cost for calling release funds, used to calculate rebate and incentivize users to call
     * @param _AVSReward The total reward for AVS attestation
     * @param _bridgeFee The total fee charged to the user for bridging
     * @param _name The name of the contract, used for EIP-712 domain construction
     * @param _version The version of the contract, used for EIP-712 domain construction
     */
    constructor(
        address _avsDirectory, address _stakeRegistry, address _rewardsCoordinator, address _delegationManager,
        uint256 _crankGasCost, uint256 _AVSReward, uint256 _bridgeFee,
        string memory _name, string memory _version
    )
        ECDSAServiceManagerBase(
            _avsDirectory,
            _stakeRegistry,
            _rewardsCoordinator,
            _delegationManager
        )
        Vault(_crankGasCost, _AVSReward, _bridgeFee, _name, _version)
    {}

    /// @notice Ensures that only registered operators can call the function
    modifier onlyOperator() {
        require(
            ECDSAStakeRegistry(stakeRegistry).operatorRegistered(msg.sender),
            "Operator must be the caller"
        );
        _;
    }

    /// @notice Rewards the operator for providing a valid attestation
    /// @dev Placeholder for actual AVS reward distribution pending Eigen M2 implementation
    /// @param operator The address of the operator to be rewarded
    function rewardAttestation(address operator) internal {
        uint256 payout = AVSReward;

        if (address(this).balance < payout) {
            payout = address(this).balance;
        }

        (bool success, ) = operator.call{value: payout}("");
        success;
    }

    /// @notice Publishes an attestation for a bridge request
    /// @param attestation The signed attestation
    /// @param _bridgeRequestId The ID of the bridge request
    function publishAttestation(bytes memory attestation, uint256 _bridgeRequestId) public nonReentrant onlyOperator {
        require(operatorHasMinimumWeight(msg.sender), "Operator does not have minimum weight");
        require(!operatorResponses[msg.sender][_bridgeRequestId], "Operator has already responded to the task");
        require(msg.sender == getSigner(bridgeRequests[_bridgeRequestId], attestation), "Invalid attestation signature");

        uint256 operatorWeight = getOperatorWeight(msg.sender);
        bridgeRequestWeights[_bridgeRequestId] += operatorWeight;

        rewardAttestation(msg.sender);

        emit AVSAttestation(attestation, _bridgeRequestId, operatorWeight);
    }

    /// @notice Slashes a malicious attestor's stake
    /// @dev Placeholder for slashing logic pending Eigen implementations
    /// @param operator The address of the operator to be slashed
    /// @param penalty The penalty amount to be slashed
    function slashMaliciousAttestor(address operator, uint256 penalty) internal {
        // TODO: Implement slashing logic pending clarity on Eigen implementations
        // @dev the below code is commented out for the upcoming M2 release
        //      in which there will be no slashing. The slasher is also being redesigned
        //      so its interface may very well change.
        // ==========================================
        // // get the list of all operators who were active when the task was initialized
        // Operator[][] memory allOperatorInfo = getOperatorState(
        //     IRegistryCoordinator(address(registryCoordinator)),
        //     task.quorumNumbers,
        //     task.taskCreatedBlock
        // );
        // // freeze the operators who signed adversarially
        // for (uint i = 0; i < allOperatorInfo.length; i++) {
        //     // first for loop iterate over quorums

        //     for (uint j = 0; j < allOperatorInfo[i].length; j++) {
        //         // second for loop iterate over operators active in the quorum when the task was initialized

        //         // get the operator address
        //         bytes32 operatorID = allOperatorInfo[i][j].operatorId;
        //         address operatorAddress = BLSPubkeyRegistry(
        //             address(blsPubkeyRegistry)
        //         ).pubkeyCompendium().pubkeyHashToOperator(operatorID);

        //         // check if the operator has already NOT been frozen
        //         if (
        //             IServiceManager(
        //                 address(
        //                     BLSRegistryCoordinatorWithIndices(
        //                         address(registryCoordinator)
        //                     ).serviceManager()
        //                 )
        //             ).slasher().isFrozen(operatorAddress) == false
        //         ) {
        //             // check whether the operator was a signer for the task
        //             bool wasSigningOperator = true;
        //             for (
        //                 uint k = 0;
        //                 k < addresssOfNonSigningOperators.length;
        //                 k++
        //             ) {
        //                 if (
        //                     operatorAddress == addresssOfNonSigningOperators[k]
        //                 ) {
        //                     // if the operator was a non-signer, then we set the flag to false
        //                     wasSigningOperator == false;
        //                     break;
        //                 }
        //             }

        //             if (wasSigningOperator == true) {
        //                 BLSRegistryCoordinatorWithIndices(
        //                     address(registryCoordinator)
        //                 ).serviceManager().freezeOperator(operatorAddress);
        //             }
        //         }
        //     }
        // }

        // the task response has been challenged successfully
    }

    /// @notice Challenges a potentially fraudulent attestation
    /// @param fraudulentSignature The signature of the fraudulent attestation
    /// @param fraudulentBridgeRequest The data of the fraudulent bridge request
    function challengeAttestation(
        bytes memory fraudulentSignature,
        Structs.BridgeRequestData memory fraudulentBridgeRequest
    ) public nonReentrant {
        address fraudulentSigner = getSigner(fraudulentBridgeRequest, fraudulentSignature);
        require(operatorResponses[fraudulentSigner][fraudulentBridgeRequest.transferIndex], "Operator has not attested to this bridge request");

        Structs.BridgeRequestData memory actualBridgeRequest = bridgeRequests[fraudulentBridgeRequest.transferIndex];

        if (fraudulentBridgeRequest.hash() != actualBridgeRequest.hash()) {
            slashMaliciousAttestor(fraudulentSigner, getOperatorWeight(fraudulentSigner));
        }
    }

    /// @notice Payouts the crank gas cost to the caller
    function payoutCrankGasCost() internal {
        uint256 payout = crankGasCost * tx.gasprice;
        if (address(this).balance < payout) {
            payout = address(this).balance;
        }

        if (payout > 0) {
            (bool success, ) = msg.sender.call{value: payout}("");
            require(success, "Failed to send crank fee");
        }
    }

    /// @notice Releases funds to the destination address
    /// @param data The bridge request data and signatures
    function _releaseFunds(bytes memory data) public override nonReentrant {
        releaseFunds(abi.decode(data, (bytes[])), abi.decode(data, (Structs.BridgeRequestData)));
    }

    /// @notice Releases funds to the destination address with typed data for ABI construction
    /// @param signatures The signatures of the operators attesting to the bridge request
    /// @param data The bridge request data
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

    /// @notice Checks if the operator has the minimum required weight
    /// @param operator The address of the operator
    /// @return True if the operator has the minimum weight, false otherwise
    function operatorHasMinimumWeight(address operator) public view returns (bool) {
        return ECDSAStakeRegistry(stakeRegistry).getOperatorWeight(operator) >= ECDSAStakeRegistry(stakeRegistry).minimumWeight();
    }

    /// @notice Gets the weight of an operator
    /// @param operator The address of the operator
    /// @return The weight of the operator
    function getOperatorWeight(address operator) public view returns (uint256) {
        return ECDSAStakeRegistry(stakeRegistry).getOperatorWeight(operator);
    }

    /// @notice Fallback function to receive ether
    receive() external payable {}
}
