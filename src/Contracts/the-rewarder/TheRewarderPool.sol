// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {RewardToken} from "./RewardToken.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";
import {AccountingToken} from "./AccountingToken.sol";

/**
 * @title TheRewarderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract TheRewarderPool {
    // Minimum duration of each round of rewards in seconds
    uint256 private constant REWARDS_ROUND_MIN_DURATION = 5 days;

    uint256 public lastSnapshotIdForRewards;
    uint256 public lastRecordedSnapshotTimestamp;

    mapping(address => uint256) public lastRewardTimestamps;

    // Token deposited into the pool by users
    DamnValuableToken public immutable liquidityToken;

    // Token used for internal accounting and snapshots
    // Pegged 1:1 with the liquidity token
    AccountingToken public accToken;

    // Token in which rewards are issued
    RewardToken public immutable rewardToken;

    // Track number of rounds
    uint256 public roundNumber;

    // Custom errors
    error MustDepositTokens();
    error TransferFail();

    constructor(address tokenAddress) {
        // Assuming all three tokens have 18 decimals
        liquidityToken = DamnValuableToken(tokenAddress);
        accToken = new AccountingToken();
        rewardToken = new RewardToken();

        _recordSnapshot();
    }

    /**
     * @notice sender must have approved `amountToDeposit` liquidity tokens in advance
     */
    function deposit(uint256 amountToDeposit) external {
        // if the amountToDeposit is equal to zero the transaction should revert
        if (amountToDeposit == 0) revert MustDepositTokens();

        // mints receipts tokens to the msg.sender in the same quantity he deposited.
        accToken.mint(msg.sender, amountToDeposit);

        // distributes rewards
        distributeRewards();

        // transfers the DVT tokens from the msg.sender to this contract.
        if (!liquidityToken.transferFrom(msg.sender, address(this), amountToDeposit)) revert TransferFail();
    }

    function withdraw(uint256 amountToWithdraw) external {
        // burns the amountToWithdraw of receipt tokens from the msg.sender
        accToken.burn(msg.sender, amountToWithdraw);

        // transfers the DVT token to the msg.sender
        if (!liquidityToken.transfer(msg.sender, amountToWithdraw)) {
            revert TransferFail();
        }
    }

    function distributeRewards() public returns (uint256) {
        uint256 rewards = 0;

        // if it is a new rewards round (which happens every 5 days)
        // then a new snapshot should be created.
        if (isNewRewardsRound()) {
            _recordSnapshot();
        }

        // calculates the totalDeposits according to the totalSupply at the last snapshot.
        uint256 totalDeposits = accToken.totalSupplyAt(lastSnapshotIdForRewards);

        // calculates the amount deposited by the msg.sender in the last snapshot.
        uint256 amountDeposited = accToken.balanceOfAt(msg.sender, lastSnapshotIdForRewards);

        if (amountDeposited > 0 && totalDeposits > 0) {
            rewards = (amountDeposited * 100 * 10 ** 18) / totalDeposits;

            if (rewards > 0 && !_hasRetrievedReward(msg.sender)) {
                rewardToken.mint(msg.sender, rewards);
                lastRewardTimestamps[msg.sender] = block.timestamp;
            }
        }

        return rewards;
    }

    function _recordSnapshot() private {
        lastSnapshotIdForRewards = accToken.snapshot();
        lastRecordedSnapshotTimestamp = block.timestamp;
        roundNumber++;
    }

    function _hasRetrievedReward(address account) private view returns (bool) {
        return (
            lastRewardTimestamps[account] >= lastRecordedSnapshotTimestamp
                && lastRewardTimestamps[account] <= lastRecordedSnapshotTimestamp + REWARDS_ROUND_MIN_DURATION
        );
    }

    function isNewRewardsRound() public view returns (bool) {
        return block.timestamp >= lastRecordedSnapshotTimestamp + REWARDS_ROUND_MIN_DURATION;
    }
}
