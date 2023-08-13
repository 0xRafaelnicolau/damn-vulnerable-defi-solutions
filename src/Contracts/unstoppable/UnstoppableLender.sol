// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";

/**
 * @title DamnValuableToken
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract UnstoppableLender is ReentrancyGuard {
    // address of the token.
    IERC20 public immutable damnValuableToken;

    // total amount of DVT tokens in the pool.
    uint256 public poolBalance;

    // custom errors
    error MustDepositOneTokenMinimum();
    error TokenAddressCannotBeZero();
    error MustBorrowOneTokenMinimum();
    error NotEnoughTokensInPool();
    error FlashLoanHasNotBeenPaidBack();
    error AssertionViolated();

    constructor(address tokenAddress) {
        if (tokenAddress == address(0)) revert TokenAddressCannotBeZero();
        damnValuableToken = IERC20(tokenAddress);
    }

    function depositTokens(uint256 amount) external nonReentrant {
        if (amount == 0) revert MustDepositOneTokenMinimum();

        // Transfer token from sender. Sender must have first approved them.
        damnValuableToken.transferFrom(msg.sender, address(this), amount);

        // update the pool balance.
        poolBalance = poolBalance + amount;
    }

    function flashLoan(uint256 borrowAmount) external nonReentrant {
        if (borrowAmount == 0) revert MustBorrowOneTokenMinimum();

        // get the balance of DVT in the contract before the flashloan is executed.
        uint256 balanceBefore = damnValuableToken.balanceOf(address(this));

        // checks if the balance before the execution of the flashloan is less
        // than the amount the user want's to borrow.
        if (balanceBefore < borrowAmount) revert NotEnoughTokensInPool();

        // Ensured by the protocol via the `depositTokens` function
        if (poolBalance != balanceBefore) revert AssertionViolated();

        // transfer the DVT tokens to the msg.sender
        damnValuableToken.transfer(msg.sender, borrowAmount);

        // calls the flashloan receiver contract.
        IReceiver(msg.sender).receiveTokens(address(damnValuableToken), borrowAmount);

        // checks if the balance of DVT tokens in the contract after the execution
        // of the flashloan is equal or bigger to the balance before execution.
        uint256 balanceAfter = damnValuableToken.balanceOf(address(this));
        if (balanceAfter < balanceBefore) revert FlashLoanHasNotBeenPaidBack();
    }
}

interface IReceiver {
    function receiveTokens(address tokenAddress, uint256 amount) external;
}
