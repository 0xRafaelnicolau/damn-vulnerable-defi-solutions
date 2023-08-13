// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {ERC20Snapshot} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {SimpleGovernance} from "./SimpleGovernance.sol";

/**
 * @title SelfiePool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SelfiePool is ReentrancyGuard {
    // uses the openzeppelin library for address operations.
    using Address for address;

    // token with snapshot capabilities
    ERC20Snapshot public token;

    // address of the governance contract.
    SimpleGovernance public governance;

    // events.
    event FundsDrained(address indexed receiver, uint256 amount);

    // custom errors.
    error OnlyGovernanceAllowed();
    error NotEnoughTokensInPool();
    error BorrowerMustBeAContract();
    error FlashLoanHasNotBeenPaidBack();

    // this modifier makes functions only callable by the governance contract.
    modifier onlyGovernance() {
        if (msg.sender != address(governance)) revert OnlyGovernanceAllowed();
        _;
    }

    // initializes the state-variables.
    constructor(address tokenAddress, address governanceAddress) {
        token = ERC20Snapshot(tokenAddress);
        governance = SimpleGovernance(governanceAddress);
    }

    function flashLoan(uint256 borrowAmount) external nonReentrant {
        // checks the balance of the contract before performing the flashloan
        uint256 balanceBefore = token.balanceOf(address(this));

        // if the amount the user is trying to borrow is bigger than the amount
        // deposited in the pool, then it should revert.
        if (balanceBefore < borrowAmount) revert NotEnoughTokensInPool();

        // transfers `borrowAmount` to the msg.sender
        token.transfer(msg.sender, borrowAmount);

        // reverts the transaction if the msg.sender is not a contract, therefore
        // he would not be able to perform a flashloan and execute custom logic.
        if (!msg.sender.isContract()) revert BorrowerMustBeAContract();

        // calls the receiveTokens function in the attack contract (which will be msg.sender)
        // sending `borrowAmount` of `token`
        msg.sender.functionCall(abi.encodeWithSignature("receiveTokens(address,uint256)", address(token), borrowAmount));

        // checks the balance of the pool after the flashloan is executed.
        uint256 balanceAfter = token.balanceOf(address(this));

        // makes sure that the flashloan has been paid back.
        if (balanceAfter < balanceBefore) revert FlashLoanHasNotBeenPaidBack();
    }

    // this function let's the governance drain every `token` in the pool
    function drainAllFunds(address receiver) external onlyGovernance {
        // checks the amount of `token` is deposited in this pool.
        uint256 amount = token.balanceOf(address(this));

        // transfers that amount to the specified receiver address provided
        // by the governance contract.
        token.transfer(receiver, amount);

        // emits an event saying that the pool was drained.
        emit FundsDrained(receiver, amount);
    }
}
