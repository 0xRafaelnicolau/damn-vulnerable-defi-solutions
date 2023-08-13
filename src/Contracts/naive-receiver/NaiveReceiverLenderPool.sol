// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

/**
 * @title NaiveReceiverLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract NaiveReceiverLenderPool is ReentrancyGuard {
    // uses the openzeppelin librabry for address operations
    using Address for address;

    // defines how much the for the flashloan is
    uint256 private constant FIXED_FEE = 1 ether; // not the cheapest flash loan

    // custom errors
    error BorrowerMustBeADeployedContract();
    error NotEnoughETHInPool();
    error FlashLoanHasNotBeenPaidBack();

    function fixedFee() external pure returns (uint256) {
        return FIXED_FEE;
    }

    function flashLoan(address borrower, uint256 borrowAmount) external nonReentrant {
        // checks the balance of the contract before executing the flashloan
        uint256 balanceBefore = address(this).balance;

        // if the balance before the flash loan is less than the amount in the pool
        // the transaction will revert
        if (balanceBefore < borrowAmount) revert NotEnoughETHInPool();

        // ensures that the flashloan receiver is a contract account and not an EOA
        if (!borrower.isContract()) revert BorrowerMustBeADeployedContract();

        // Transfer ETH and handle control to receiver
        borrower.functionCallWithValue(abi.encodeWithSignature("receiveEther(uint256)", FIXED_FEE), borrowAmount);

        // checks if the flashloan was repaid plus the fee to be paid
        if (address(this).balance < balanceBefore + FIXED_FEE) {
            revert FlashLoanHasNotBeenPaidBack();
        }
    }

    // Allow deposits of ETH
    receive() external payable {}
}
