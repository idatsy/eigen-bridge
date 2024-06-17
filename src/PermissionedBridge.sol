// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Events.sol";
import "./Structs.sol";
import "./ECDSAUtils.sol";
import "./Vault.sol";

/// @title Permissioned Bridge
/// @notice Manages bridge operations with manually set operator weights
/// @dev Extends Vault for bridging functionality
contract PermissionedBridge is Vault {
    using Structs for Structs.BridgeRequestData;

    /// @notice Tracks bridge requests that this operator has responded to once to avoid duplications
    /// @dev Double attestations would technically be valid and allow operators to recursively call until funds are released
    mapping(address => mapping(uint256 => bool)) public operatorResponses;

    /// @notice Tracks the total operator weight attested to a bridge request
    /// @dev Helpful for determining when enough attestations have been collected to release funds.
    mapping(uint256 => uint256) public bridgeRequestWeights;

    /// @notice Maps operator addresses to their respective weights
    /// @dev Temporary solution for illustrative purposes on non-mainnet chains
    mapping(address => uint256) public operatorWeights;

    /**
     * @notice Initializes the contract with the necessary parameters
     * @param _crankGasCost The estimated gas cost for calling release funds, used to calculate rebate and incentivize users to call
     * @param _AVSReward The total reward for AVS attestation
     * @param _bridgeFee The total fee charged to the user for bridging
     * @param _name The name of the contract, used for EIP-712 domain construction
     * @param _version The version of the contract, used for EIP-712 domain construction
     */
    constructor(
        uint256 _crankGasCost, uint256 _AVSReward, uint256 _bridgeFee,
        string memory _name, string memory _version
    )
        Vault(_crankGasCost, _AVSReward, _bridgeFee, _name, _version)
    {}

    /// @notice Ensures that only operators with non-zero weight can call the function
    modifier onlyOperator() {
        require(operatorWeights[msg.sender] > 0, "Operator weight must be greater than 0");
        _;
    }

    /// @notice Publishes an attestation for a bridge request
    /// @param attestation The signed attestation
    /// @param _bridgeRequestId The ID of the bridge request
    function publishAttestation(bytes memory attestation, uint256 _bridgeRequestId) public nonReentrant onlyOperator {
        require(!operatorResponses[msg.sender][_bridgeRequestId], "Operator has already responded to the task");
        require(msg.sender == getSigner(bridgeRequests[_bridgeRequestId], attestation), "Invalid attestation signature");

        uint256 operatorWeight = getOperatorWeight(msg.sender);
        bridgeRequestWeights[_bridgeRequestId] += operatorWeight;

        emit AVSAttestation(attestation, _bridgeRequestId, operatorWeight);
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
            totalWeight += getOperatorWeight(signer);
        }

        require(totalWeight >= data.amountOut, "Insufficient total weight to cover swap");
        IERC20(data.tokenAddress).transfer(data.destinationAddress, data.amountOut);

        emit FundsReleased(data.tokenAddress, data.destinationAddress, data.amountOut);
    }

    /// @notice Checks if the operator has the minimum required weight
    /// @param operator The address of the operator
    /// @return True if the operator has the minimum weight, false otherwise
    function operatorHasMinimumWeight(address operator) public view returns (bool) {
        return operatorWeights[operator] >= 1;
    }

    /// @notice Gets the weight of an operator
    /// @param operator The address of the operator
    /// @return The weight of the operator
    function getOperatorWeight(address operator) public view returns (uint256) {
        return operatorWeights[operator];
    }

    /// @notice Sets the weight of an operator
    /// @param operator The address of the operator
    /// @param weight The new weight of the operator
    function setOperatorWeight(address operator, uint256 weight) public onlyOwner {
        operatorWeights[operator] = weight;
    }

    /// @notice Fallback function to receive ether
    receive() external payable {}
}
