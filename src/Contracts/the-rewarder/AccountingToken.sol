// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20Snapshot, ERC20} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";

/**
 * @title AccountingToken
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 * @notice A limited pseudo-ERC20 token to keep track of deposits and withdrawals
 *         with snapshotting capabilities
 */
contract AccountingToken is ERC20Snapshot, AccessControl {
    // this tokens helps the system keep track of ddeposits and
    // withdrawals, like receipts.
    // the receipts are minted when the user deposits, and burned
    // when the user withdrawals.

    // different roles in this system related to access control.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // custom errors
    error Forbidden();
    error NotImplemented();

    // sets up access control, and creates the receipt token.
    constructor() ERC20("rToken", "rTKN") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(SNAPSHOT_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
    }

    // can only called by the minter, and it can mint `amount` of
    // tokens to address `to`.
    function mint(address to, uint256 amount) external {
        if (!hasRole(MINTER_ROLE, msg.sender)) revert Forbidden();
        _mint(to, amount);
    }

    // can only be called by the burner, and it can burn `amount` of
    // receipt tokens from address `from`.
    function burn(address from, uint256 amount) external {
        if (!hasRole(BURNER_ROLE, msg.sender)) revert Forbidden();
        _burn(from, amount);
    }

    // takes a snapshot of the current users balances.
    function snapshot() external returns (uint256) {
        if (!hasRole(SNAPSHOT_ROLE, msg.sender)) revert Forbidden();
        return _snapshot();
    }

    // Do not need transfer of this token
    // These token can't be transfered.
    function _transfer(address, address, uint256) internal pure override {
        revert NotImplemented();
    }

    // Do not need allowance of this token
    // Since the token cant be transfered, it does not need to have allowance.
    function _approve(address, address, uint256) internal pure override {
        revert NotImplemented();
    }
}
