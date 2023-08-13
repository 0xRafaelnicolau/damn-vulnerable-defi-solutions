// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DamnValuableTokenSnapshot} from "../DamnValuableTokenSnapshot.sol";
import {Address} from "../../../lib/openzeppelin-contracts/contracts/utils/Address.sol";

/**
 * @title SimpleGovernance
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SimpleGovernance {
    // uses the openzeppelin library for address operations
    using Address for address;

    // representantion of a governance action, and it's parameters
    struct GovernanceAction {
        address receiver; // receiver of the funds
        bytes data; // additional data
        uint256 weiAmount; // wei amount (?)
        uint256 proposedAt; // timestamp of when the action was proposed
        uint256 executedAt; // timestamp of when the action was executed
    }

    // governance token used to vote
    DamnValuableTokenSnapshot public governanceToken;
    // mapping of actionId to the respective governance action.
    mapping(uint256 => GovernanceAction) public actions;
    // actionId counter.
    uint256 private actionCounter;
    // action delay
    uint256 private constant ACTION_DELAY_IN_SECONDS = 2 days;

    // events
    event ActionQueued(uint256 actionId, address indexed caller);
    event ActionExecuted(uint256 actionId, address indexed caller);

    // custom errors
    error GovernanceTokenCannotBeZeroAddress();
    error NotEnoughVotesToPropose();
    error CannotQueueActionsThatAffectGovernance();
    error CannotExecuteThisAction();

    constructor(address governanceTokenAddress) {
        // if the governance token address is address(0) then it should revert.
        if (governanceTokenAddress == address(0)) {
            revert GovernanceTokenCannotBeZeroAddress();
        }

        // sets the address of the governance token.
        governanceToken = DamnValuableTokenSnapshot(governanceTokenAddress);

        // sets the action counter to initial value 1
        actionCounter = 1;
    }

    function queueAction(address receiver, bytes calldata data, uint256 weiAmount) external returns (uint256) {
        // checks if the msg.sender has enough votes to make a proposal.
        if (!_hasEnoughVotes(msg.sender)) revert NotEnoughVotesToPropose();

        // what does this check do ?
        if (receiver == address(this)) {
            revert CannotQueueActionsThatAffectGovernance();
        }

        // gets the current actionId
        uint256 actionId = actionCounter;

        // gets the action to queue in storage, and uptades it's parameters
        GovernanceAction storage actionToQueue = actions[actionId];
        actionToQueue.receiver = receiver;
        actionToQueue.weiAmount = weiAmount;
        actionToQueue.data = data;
        actionToQueue.proposedAt = block.timestamp;

        // increments the action counter.
        actionCounter++;

        emit ActionQueued(actionId, msg.sender);
        return actionId;
    }

    function executeAction(uint256 actionId) external payable {
        // checks if these proposal can be executed.
        if (!_canBeExecuted(actionId)) revert CannotExecuteThisAction();

        // changes the timestamp in which the proposal was executed.
        GovernanceAction storage actionToExecute = actions[actionId];
        actionToExecute.executedAt = block.timestamp;

        // calls the receiver contract with actionToExecute.data (which is func selector and params)
        // with a certain value.
        actionToExecute.receiver.functionCallWithValue(actionToExecute.data, actionToExecute.weiAmount);

        emit ActionExecuted(actionId, msg.sender);
    }

    function getActionDelay() public pure returns (uint256) {
        return ACTION_DELAY_IN_SECONDS;
    }

    /**
     * @dev an action can only be executed if:
     * 1) it's never been executed before and
     * 2) enough time has passed since it was first proposed
     */
    function _canBeExecuted(uint256 actionId) private view returns (bool) {
        GovernanceAction memory actionToExecute = actions[actionId];

        // this statement returns true if the proposal was not executed before (executedAt == 0) and
        // the block.timestamp - timestamp of when it was proposed is bigger than days
        return (
            actionToExecute.executedAt == 0 && (block.timestamp - actionToExecute.proposedAt >= ACTION_DELAY_IN_SECONDS)
        );
    }

    function _hasEnoughVotes(address account) private view returns (bool) {
        // gets the amount of governance token the give account has
        uint256 balance = governanceToken.getBalanceAtLastSnapshot(account);

        // gets the amount of the total supply divided by two
        uint256 halfTotalSupply = governanceToken.getTotalSupplyAtLastSnapshot() / 2;

        // if balance of the given account is bigger than half of the supply
        // this function will return true, if not it will return false.s
        return balance > halfTotalSupply;
    }
}
