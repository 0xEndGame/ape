pragma solidity ^0.5.16;

import "./ApeWrappedNative.sol";

/**
 * @title ApeFinance's Maximillion Contract
 */
contract Maximillion {
    /**
     * @notice The ApeWrappedNative market to repay in
     */
    ApeWrappedNative public apeWrappedNative;

    /**
     * @notice Construct a Maximillion to repay max in a ApeWrappedNative market
     */
    constructor(ApeWrappedNative apeWrappedNative_) public {
        apeWrappedNative = apeWrappedNative_;
    }

    /**
     * @notice msg.sender sends Ether to repay an account's borrow in the apeWrappedNative market
     * @dev The provided Ether is applied towards the borrow balance, any excess is refunded
     * @param borrower The address of the borrower account to repay on behalf of
     */
    function repayBehalf(address borrower) public payable {
        repayBehalfExplicit(borrower, apeWrappedNative);
    }

    /**
     * @notice msg.sender sends Ether to repay an account's borrow in a apeWrappedNative market
     * @dev The provided Ether is applied towards the borrow balance, any excess is refunded
     * @param borrower The address of the borrower account to repay on behalf of
     * @param apeWrappedNative_ The address of the apeWrappedNative contract to repay in
     */
    function repayBehalfExplicit(address borrower, ApeWrappedNative apeWrappedNative_) public payable {
        uint256 received = msg.value;
        uint256 borrows = apeWrappedNative_.borrowBalanceCurrent(borrower);
        if (received > borrows) {
            apeWrappedNative_.repayBorrowNative.value(borrows)(borrower);
            msg.sender.transfer(received - borrows);
        } else {
            apeWrappedNative_.repayBorrowNative.value(received)(borrower);
        }
    }
}
