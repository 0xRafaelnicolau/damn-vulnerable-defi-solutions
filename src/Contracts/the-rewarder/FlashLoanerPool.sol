// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";

/**
 * @title FlashLoanerPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 * @dev A simple pool to get flash loans of DVT
 */
contract FlashLoanerPool is ReentrancyGuard {
    // this contract offers flashloans of the DVT token
    // in the contract the DVT token is refered to as the
    // liquidityToken.

    // uses custom address operations defined by openzeppeliin
    using Address for address;

    // address of the DVT token.
    DamnValuableToken public immutable liquidityToken;

    // custom errors.
    error NotEnoughTokensInPool();
    error FlashLoanHasNotBeenPaidBack();
    error BorrowerMustBeAContract();

    constructor(address liquidityTokenAddress) {
        liquidityToken = DamnValuableToken(liquidityTokenAddress);
    }

    // allows users to get flashloans of DVT tokens for free.
    function flashLoan(uint256 amount) external nonReentrant {
        // verifies the amount of DVT tokens deposited in the contract
        // before the flashloan is executed.
        uint256 balanceBefore = liquidityToken.balanceOf(address(this));

        // if the amount of DVT tokens the user is trying to borrow from
        // the pool is bigger than the balance he has, then the transaction
        // should revert.
        if (amount > balanceBefore) revert NotEnoughTokensInPool();

        // these checks verify if the address the DVT tokens are being sent
        // to are a contract or not, if they are not the transaction should
        // revert.
        if (!msg.sender.isContract()) revert BorrowerMustBeAContract();

        // transfers the DVT tokens to the msg.sender
        liquidityToken.transfer(msg.sender, amount);

        // calls the receiveFlashLoan function in the attack contract.
        msg.sender.functionCall(abi.encodeWithSignature("receiveFlashLoan(uint256)", amount));

        // verifies that the amount of DVT tokens the user borrowed
        // is being paid back.
        if (liquidityToken.balanceOf(address(this)) < balanceBefore) {
            revert FlashLoanHasNotBeenPaidBack();
        }
    }
}
