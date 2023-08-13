// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";

/**
 * @title RewardToken
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 * @dev A mintable ERC20 with 2 decimals to issue rewards
 */
contract RewardToken is ERC20, AccessControl {
    // defines the roles that exist in these system.
    // in this case there's only the minter role.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // custom errors.
    error Forbidden();

    // sets up custom roles in the system.
    constructor() ERC20("Reward Token", "RWT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    // this function let's the user with MINTER_ROLE mint
    // `amount` of tokens to address `to`.
    function mint(address to, uint256 amount) external {
        if (!hasRole(MINTER_ROLE, msg.sender)) revert Forbidden();
        _mint(to, amount);
    }
}
