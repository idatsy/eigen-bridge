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
    mapping(address => bool) public whitelistedSigners;

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
     * @param _canonicalSigner The address of the canonical signer.
     * @param _crankGasCost The initial gas cost for crank operations.
     * @param _AVSReward The initial reward for AVS operations.
     * @param _bridgeFee The initial fee for bridge operations.
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

}