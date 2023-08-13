// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

/**
 * @title FlashLoanReceiver
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract FlashLoanReceiver {
    // uses openzeppelin library for address operations
    using Address for address payable;

    // address of the naive lender pool
    address payable private pool;

    // custom errors
    error SenderMustBePool();
    error CannotBorrowThatMuch();

    constructor(address payable poolAddress) {
        pool = poolAddress;
    }

    // Function called by the pool during flash loan
    function receiveEther(uint256 fee) public payable {
        if (msg.sender != pool) revert SenderMustBePool();

        // the amount to be repaid is the price of the flashloan + 1 ether.
        uint256 amountToBeRepaid = msg.value + fee;

        // if the balance of ETH in this contract is less than the amount
        // to be repaid then the transaction will revert.
        if (address(this).balance < amountToBeRepaid) {
            revert CannotBorrowThatMuch();
        }

        // logic to execute during the flashloan...
        _executeActionDuringFlashLoan();

        // Return funds to pool
        pool.sendValue(amountToBeRepaid);
    }

    // Internal function where the funds received are used
    function _executeActionDuringFlashLoan() internal {}

    // Allow deposits of ETH
    receive() external payable {}
}
