// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Address} from "../../../lib/openzeppelin-contracts/contracts/utils/Address.sol";
import {ReentrancyGuard} from "../../../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

/**
 * @title TrusterLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract TrusterLenderPool is ReentrancyGuard {
    // uses openzeppelin library for address operations
    using Address for address;

    // address of the DVT token
    IERC20 public immutable damnValuableToken;

    // custom errors
    error NotEnoughTokensInPool();
    error FlashLoanHasNotBeenPaidBack();

    constructor(address tokenAddress) {
        damnValuableToken = IERC20(tokenAddress);
    }

    function flashLoan(uint256 borrowAmount, address borrower, address target, bytes calldata data)
        external
        nonReentrant
    {
        // checks if the balance of the contract before the flashloan is less than
        // the amount the user wants to borrow
        uint256 balanceBefore = damnValuableToken.balanceOf(address(this));
        if (balanceBefore < borrowAmount) revert NotEnoughTokensInPool();

        // transfers the DVT tokens to the borrower
        damnValuableToken.transfer(borrower, borrowAmount);

        // function calls an arbitrary contract with arbitrary data
        // handing over execution to the target contract.
        target.functionCall(data);

        // checks if the balance of the contract after the flashloan is less than
        // the balance before the flashloan was executed, which means it was not paid
        uint256 balanceAfter = damnValuableToken.balanceOf(address(this));
        if (balanceAfter < balanceBefore) revert FlashLoanHasNotBeenPaidBack();
    }
}
