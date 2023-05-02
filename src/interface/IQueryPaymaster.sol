// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IQueryPaymaster
 * @dev BlockTrekker query payment rails (how users pay for queries)
 * @notice uses centralized debiting mechanic, advanced state channel architecture in future
 */
abstract contract IQueryPaymaster is Ownable {
    /// EVENTS ///
    event Deposited(address indexed _from, uint256 indexed _amount);
    event Debited(address indexed _from, uint256 indexed _amount);

    /// VARIABLES ///
    mapping(address => uint256) public balances; // map address to query balance

    /// MODIFIERS ///

    /**
     * Ensure a given creator query account has sufficient balance for a debit value
     *
     * @param _from - creator address being queried for usdc balance
     * @param _amount - the amount of tokens the address must have to return true
     */
    modifier queryBalance(address _from, uint256 _amount) {
        require(balances[_from] >= _amount, "!Afford");
        _;
    }

    /// FUNCTIONS ///

    /**
     * Deposit USDC tokens to pay for BlockTrekker queries
     * @dev transfers payment tokens directly to treasury without possibility of refund/ withdrawal
     *
     * @param _amount - the amount of USDC tokens to deposit
     */
    function deposit(uint256 _amount) public virtual;

    /**
     * Debit value from a BlockTrekker account to reflect payment for queries on backend
     * @dev modifier onlyOwner, queryBalance
     * @notice Admin will debit many queries in one (ex $0.23 + $1.24 + $.74 = debit of $2.21)
     * @notice centralied, improvements todo
     *
     * @param _from - the BlockTrekker account to debit value from
     * @param _amount - the amount of tokens to debit from the account
     */
    function debit(address _from, uint256 _amount) public virtual;

    /// VIEWS ///

    /**
     * Return the address for USDC used to compensate creators and the platform
     *
     * @return - the address of the usdc erc20 contract
     */
    function usdc() public view virtual returns (address);

    /**
     * Return the treasury address for blocktrekker that receives fees on each mint
     *
     * @return - the address of the treasury
     */
    function treasury() public view virtual returns (address);
}
