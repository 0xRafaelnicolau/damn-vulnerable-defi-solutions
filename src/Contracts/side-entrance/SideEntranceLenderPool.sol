// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SideEntranceLenderPool {
    using Address for address payable;

    // amount of deposited ether by each address
    mapping(address => uint256) private balances;

    error NotEnoughETHInPool();
    error FlashLoanHasNotBeenPaidBack();

    function deposit() external payable {
        // updates the msg.sender balance in the mapping
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        // gets the balance of the msg.sender has deposited.
        uint256 amountToWithdraw = balances[msg.sender];

        // updates the balance of the msg.sender to 0.
        balances[msg.sender] = 0;

        // withdraws the user balance by sending it to msg.sender
        payable(msg.sender).sendValue(amountToWithdraw);
    }

    // this contract offers flashloans to the msg.sender
    function flashLoan(uint256 amount) external {
        // balance of the contract before the flashloan
        uint256 balanceBefore = address(this).balance;

        // if the balance of the contract before the flashloan is
        // less the the amount the user want to borrow then
        // the transaction should revert.
        if (balanceBefore < amount) revert NotEnoughETHInPool();

        // calls the flashloan receiver contract to execute some kind
        // of logic, sending the ether to the flashloan receiver contract.
        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        // if the balance of the contract before the flashloan is
        // less than the balance of the contract after the flashloan
        // then the transaction should revert.
        if (address(this).balance < balanceBefore) {
            revert FlashLoanHasNotBeenPaidBack();
        }
    }
}
