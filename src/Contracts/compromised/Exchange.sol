// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";

import {TrustfulOracle} from "./TrustfulOracle.sol";
import {DamnValuableNFT} from "../DamnValuableNFT.sol";

/**
 * @title Exchange
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract Exchange is ReentrancyGuard {
    // uses openzeppelin library for address operations
    using Address for address payable;

    // damn valuable NFT collection
    DamnValuableNFT public immutable token;

    // oracle
    TrustfulOracle public immutable oracle;

    event TokenBought(address indexed buyer, uint256 tokenId, uint256 price);
    event TokenSold(address indexed seller, uint256 tokenId, uint256 price);

    error NotEnoughETHInBalance();
    error AmountPaidIsNotEnough();
    error ValueMustBeGreaterThanZero();
    error SellerMustBeTheOwner();
    error SellerMustHaveApprovedTransfer();

    constructor(address oracleAddress) payable {
        token = new DamnValuableNFT();
        oracle = TrustfulOracle(oracleAddress);
    }

    function buyOne() external payable nonReentrant returns (uint256) {
        // amount paid in wei.
        uint256 amountPaidInWei = msg.value;
        if (amountPaidInWei == 0) revert ValueMustBeGreaterThanZero();

        // gets the price in wei of the token.
        uint256 currentPriceInWei = oracle.getMedianPrice(token.symbol());

        // if the amount being paid is less than the price of the NFT revert
        // can I pass this check by manipulating the currentPriceInWei?
        if (amountPaidInWei < currentPriceInWei) revert AmountPaidIsNotEnough();

        // mint the nft to the msg.sender
        uint256 tokenId = token.safeMint(msg.sender);

        // repay the difference to the msg.sender
        payable(msg.sender).sendValue(amountPaidInWei - currentPriceInWei);

        emit TokenBought(msg.sender, tokenId, currentPriceInWei);

        return tokenId;
    }

    function sellOne(uint256 tokenId) external nonReentrant {
        // checks if the msg.sender is the owner of the tokenId being sold.
        if (msg.sender != token.ownerOf(tokenId)) revert SellerMustBeTheOwner();

        // checks if the seller approved this contract to transfer the NFT
        if (token.getApproved(tokenId) != address(this)) {
            revert SellerMustHaveApprovedTransfer();
        }

        // gets the current prince in wei of the nft.
        uint256 currentPriceInWei = oracle.getMedianPrice(token.symbol());

        // if the balance in this contract is less than the amount to be paid
        // the transaction will revert.
        if (address(this).balance < currentPriceInWei) {
            revert NotEnoughETHInBalance();
        }

        // transfers the nft from the msg.sender to this contract.
        token.transferFrom(msg.sender, address(this), tokenId);

        // burns the received NFT
        token.burn(tokenId);

        // sends ether to the msg.sender corresponding to the amount of the sold NFT.
        payable(msg.sender).sendValue(currentPriceInWei);

        emit TokenSold(msg.sender, tokenId, currentPriceInWei);
    }

    receive() external payable {}
}
