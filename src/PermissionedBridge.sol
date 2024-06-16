// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Events.sol";
import "./Structs.sol";
import "./ECDSAUtils.sol";
import  "./Vault.sol";


contract PermissionedBridge is Vault {
    using Structs for Structs.BridgeRequestData;

    /// @notice Tracks bridge requests that this operator has responded to once to avoid duplications
    /// @dev Double attestations would technically be valid and allow operators to recursively call until funds are released
    mapping(address => mapping(uint256=> bool)) public operatorResponses;

    /// @notice Tracks the total operator weight attested to a bridge request
    /// @dev Helpful for determining when enough attestations have been collected to release funds.
    mapping(uint256 => uint256) public bridgeRequestWeights;

    /// @notice This is a hack around the fact that we don't have access to the EigenLayer stake registry on non-mainnet
    /// networks. Instead we monitor the operator's weights on mainnet and change them here manually using a watcher.
    /// @dev This is a temporary solution for illustrative purposes only.
    mapping(address => uint256) public operatorWeights;

    /**
     * @param _crankGasCost The estimated gas cost for calling release funds, used to calculate rebate and incentivise users to call.
     * @param _AVSReward The total reward for AVS attestation.
     * @param _bridgeFee The total fee charged to user for bridging.
     * @param _name The name of the contract. Used for EIP-712 domain construction.
     * @param _version The version of the contract. Used for EIP-712 domain construction.
     */
    constructor(
        uint256 _crankGasCost, uint256 _AVSReward, uint256 _bridgeFee,
        string memory _name, string memory _version
    )
        Vault(_crankGasCost, _AVSReward, _bridgeFee, _name, _version)
    {}

    modifier onlyOperator() {
        require(operatorWeights[msg.sender] > 0, "Operator weight must be greater than 0");
        _;
    }

    /* MOCK AVS functions */

    function publishAttestation(bytes memory attestation, uint256 _bridgeRequestId) public nonReentrant onlyOperator {
        // Check that operator doesn't respond to the same task twice
        require(!operatorResponses[msg.sender][_bridgeRequestId], "Operator has already responded to the task");

        // Check that the operator is signing the correct bridge request parameters
        require(msg.sender == getSigner(bridgeRequests[_bridgeRequestId], attestation), "Invalid attestation signature");

        // Increment the total weights attested for this bridge request.
        // Helpful for determining when enough attestations have been collected to release funds.
        uint256 operatorWeight = getOperatorWeight(msg.sender);
        bridgeRequestWeights[_bridgeRequestId] += operatorWeight;

        emit AVSAttestation(attestation, _bridgeRequestId, operatorWeight);
    }

    /// @notice Release funds to the destination address
    function _releaseFunds(bytes memory data) public override nonReentrant {
        releaseFunds(abi.decode(data, (bytes[])), abi.decode(data, (Structs.BridgeRequestData)));
    }

    /// @notice Convenience function for releasing funds to the destination address with typed data for ABI construction
    /// @dev NOTE: this function is only callable by the owner and always releases the funds to the destination address
    function releaseFunds(bytes[] memory signatures, Structs.BridgeRequestData memory data) public nonReentrant {
        // Verify each signature and sum the operator weights
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = getSigner(data, signatures[i]);
            totalWeight += getOperatorWeight(signer);
        }

        // Check if the total weight is sufficient to cover the economic value of the swap
        require(totalWeight >= data.amountOut, "Insufficient total weight to cover swap");

        // Transfer the tokens to the destination address
        // NOTE: This should use an oracle price or a passed down price from original BridgeRequest, for the sake of
        // illustrating how EigenLayer works we are using the amountOut as the value of the token here.
        IERC20(data.tokenAddress).transfer(data.destinationAddress, data.amountOut);

        emit FundsReleased(data.tokenAddress, data.destinationAddress, data.amountOut);
    }

    /* Helper functions */

    function operatorHasMinimumWeight(address operator) public view returns (bool) {
        return operatorWeights[operator] >= 1;
    }

    function getOperatorWeight(address operator) public view returns (uint256) {
        return operatorWeights[operator];
    }

    function setOperatorWeight(address operator, uint256 weight) public onlyOwner {
        operatorWeights[operator] = weight;
    }

    receive() external payable {}
}