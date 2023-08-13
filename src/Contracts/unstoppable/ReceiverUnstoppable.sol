// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {UnstoppableLender} from "./UnstoppableLender.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title ReceiverUnstoppable
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract ReceiverUnstoppable {
    // uses the openzeppelin librabry for safe ERC20 transfers.
    using SafeERC20 for IERC20;

    // address of the lender pool.
    UnstoppableLender private immutable pool;

    // owner of the contract
    address private immutable owner;

    // custom errors.
    error OnlyOwnerCanExecuteFlashLoan();
    error SenderMustBePool();

    constructor(address poolAddress) {
        pool = UnstoppableLender(poolAddress);
        owner = msg.sender;
    }

    /// @dev Pool will call this function during the flash loan
    function receiveTokens(address tokenAddress, uint256 amount) external {
        // if the msg.sender is not the pool the transaction will revert.
        if (msg.sender != address(pool)) revert SenderMustBePool();

        // transfers the received tokens back to the pool to repay
        // the flashloan.
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }

    function executeFlashLoan(uint256 amount) external {
        // if the msg.sender is not the owner then the transaction will revert.
        if (msg.sender != owner) revert OnlyOwnerCanExecuteFlashLoan();

        // execute the flashloan with the specified amount.
        pool.flashLoan(amount);
    }
}
