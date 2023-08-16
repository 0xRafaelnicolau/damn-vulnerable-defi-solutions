// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";

/**
 * @title PuppetPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract PuppetPool is ReentrancyGuard {
    using Address for address payable;

    // deposits of every user.
    mapping(address => uint256) public deposits;

    // ETH/DVT uniswap pair
    address public immutable uniswapPair;

    // DVT token
    DamnValuableToken public immutable token;

    event Borrowed(address indexed account, uint256 depositRequired, uint256 borrowAmount);

    error NotDepositingEnoughCollateral();
    error TransferFailed();

    constructor(address tokenAddress, address uniswapPairAddress) {
        token = DamnValuableToken(tokenAddress);
        uniswapPair = uniswapPairAddress;
    }

    // Allows borrowing `borrowAmount` of tokens by first depositing two times their value in ETH
    function borrow(uint256 borrowAmount) public payable nonReentrant {
        // calculates the amount of ETH required to borrow DVT from the pool
        uint256 depositRequired = calculateDepositRequired(borrowAmount);

        // if the amount of ETH in msg.value is less than depositRequired revert
        if (msg.value < depositRequired) revert NotDepositingEnoughCollateral();

        // if the amount of ETH provided is bigger than depositRequired the user is reimbursed
        if (msg.value > depositRequired) {
            payable(msg.sender).sendValue(msg.value - depositRequired);
        }

        // updates the deposited balance of the msg.sender
        deposits[msg.sender] = deposits[msg.sender] + depositRequired;

        // Fails if the pool doesn't have enough tokens in liquidity
        if (!token.transfer(msg.sender, borrowAmount)) revert TransferFailed();

        emit Borrowed(msg.sender, depositRequired, borrowAmount);
    }

    function calculateDepositRequired(uint256 amount) public view returns (uint256) {
        return (amount * _computeOraclePrice() * 2) / 10 ** 18;
    }

    function _computeOraclePrice() private view returns (uint256) {
        // calculates the price of the token in wei according to Uniswap pair
        // uniswapPair.balance represents the balance in ether
        // token.balanceOf(uniswapPair) represents the balance in DVT tokens
        return (uniswapPair.balance * (10 ** 18)) / token.balanceOf(uniswapPair);
    }

    /**
     * ... functions to deposit, redeem, repay, calculate interest, and so on ...
     */
}
