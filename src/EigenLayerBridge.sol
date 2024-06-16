// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "eigenlayer-middleware/src/unaudited/ECDSAServiceManagerBase.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Events.sol";
import "./Structs.sol";
import "./ECDSAUtils.sol";
import  "./Vault.sol";


contract BridgeServiceManager is ECDSAServiceManagerBase, Vault {
    using Structs for Structs.BridgeRequestData;

    /// @notice Tracks bridge requests that this operator has responded to once to avoid duplications
    /// @dev Double attestations would technically be valid and allow operators to recursively call until funds are released
    mapping(address => mapping(uint256=> bool)) public operatorResponses;

    /// @notice Tracks the total operator weight attested to a bridge request
    /// @dev Helpful for determining when enough attestations have been collected to release funds.
    mapping(uint256 => uint256) public bridgeRequestWeights;

    /**
     * @dev Constructor for ECDSAServiceManagerBase, initializing immutable contract addresses and disabling initializers.
     * @param _avsDirectory The address of the AVS directory contract, managing AVS-related data for registered operators.
     * @param _stakeRegistry The address of the stake registry contract, managing registration and stake recording.
     * @param _rewardsCoordinator The address of the rewards coordinator contract, handling rewards distributions.
     * @param _delegationManager The address of the delegation manager contract, managing staker delegations to operators.
     * @param _crankGasCost The estimated gas cost for calling release funds, used to calculate rebate and incentivise users to call.
     * @param _AVSReward The total reward for AVS attestation.
     * @param _bridgeFee The total fee charged to user for bridging.
     * @param _name The name of the contract. Used for EIP-712 domain construction.
     * @param _version The version of the contract. Used for EIP-712 domain construction.
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

    modifier onlyOperator() {
        require(
            ECDSAStakeRegistry(stakeRegistry).operatorRegistered(msg.sender)
            ==
            true,
            "Operator must be the caller"
        );
        _;
    }

    /* AVS functions */

    function rewardAttestation(address operator) internal {
        // Calculate payment for AVS attestation, equals the reward or the contract balance
        uint256 payout = AVSReward;

        if (address(this).balance < payout) {
            payout = address(this).balance;
        }

        // TODO: This is a placeholder for the actual AVS reward distribution pending Eigen M2 implementation
        (bool success, ) = operator.call{value: payout}("");
        success;
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
        uint256 operatorWeight = getOperatorWeight(msg.sender);
        bridgeRequestWeights[_bridgeRequestId] += operatorWeight;

        rewardAttestation(msg.sender);

        emit AVSAttestation(attestation, _bridgeRequestId, operatorWeight);
    }

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

    function challengeAttestation(
        bytes memory fraudulentSignature,
        Structs.BridgeRequestData memory fraudulentBridgeRequest
    ) public nonReentrant {
        // Get the signer for this potentially fraudulent bridge request
        address fraudulentSigner = getSigner(fraudulentBridgeRequest, fraudulentSignature);

        // Check that a bridge request exists for this transfer index, and has been signed by the alleged fraudster
        require(
            operatorResponses[fraudulentSigner][fraudulentBridgeRequest.transferIndex],
            "Operator has not attested to this bride request"
        );

        // Check that this signed potentially fraudulent bridge request does not match the actual bridge request
        // meaning it would have been manipulated by the operator
        Structs.BridgeRequestData memory actualBridgeRequest = bridgeRequests[fraudulentBridgeRequest.transferIndex];

        if (fraudulentBridgeRequest.hash() != actualBridgeRequest.hash()) {
            // Slash the operator for attempting to submit a fraudulent attestation
            slashMaliciousAttestor(fraudulentSigner, getOperatorWeight(fraudulentSigner));
        }
    }

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

    /// @notice Release funds to the destination address
    function _releaseFunds(bytes memory data) public override nonReentrant {
        releaseFunds(abi.decode(data, (bytes[])), abi.decode(data, (Structs.BridgeRequestData)));
    }

    /// @dev Convenience function for releasing funds to the destination address with typed data for ABI construction
    function releaseFunds(bytes[] memory signatures, Structs.BridgeRequestData memory data) public nonReentrant {
        // Verify each signature and sum the operator weights
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = getSigner(data, signatures[i]);
            require(operatorResponses[signer][data.transferIndex], "Invalid signature");
            totalWeight += getOperatorWeight(signer);
        }

        // Check if the total weight is sufficient to cover the economic value of the swap
        require(totalWeight >= data.amountOut, "Insufficient total weight to cover swap");

        // Transfer the tokens to the destination address
        // NOTE: This should use an oracle price or a passed down price from original BridgeRequest, for the sake of
        // illustrating how EigenLayer works we are using the amountOut as the value of the token here.
        IERC20(data.tokenAddress).transfer(data.destinationAddress, data.amountOut);

        payoutCrankGasCost();

        emit FundsReleased(data.tokenAddress, data.destinationAddress, data.amountOut);
    }

    /* Helper functions */

    function operatorHasMinimumWeight(address operator) public view returns (bool) {
        return ECDSAStakeRegistry(stakeRegistry).getOperatorWeight(operator) >= ECDSAStakeRegistry(stakeRegistry).minimumWeight();
    }

    function getOperatorWeight(address operator) public view returns (uint256) {
        return ECDSAStakeRegistry(stakeRegistry).getOperatorWeight(operator);
    }

    receive() external payable {}
}