// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/** 
 * @title IQueryPayments
 * @dev BlockTrekker query payment rails (how users pay for queries)
 * @notice uses centralized debiting mechanic, advanced state channel architecture in future
 */
contract IQueryPayments is Ownable {

    /// EVENTS ///

    event Deposited(address indexed _from, uint256 indexed _amount);
    event Debited(address indexed _from, uint256 indexed _amount);
    event TreasuryChanged(address indexed _to);
    event AdminChanged(address indexed _to);

    /// VARIABLES ///

    // treasury and admin can be the same or different depending on risk profile
    address public treasury; // address that receives tokens from a subcription transfer
    address public admin; // address permissioned to call administrative functions
    address public usdc; // address of the deployed ERC20 contract for USDC

    uint256 public constant DECIMALS = 10**6; // 6 decimal places on USDC

    mapping(address => uint256) public balances; // map address to query balance

    /// MODIFIERS ///

    /**
     * Requires that a function is called by the administrator address
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "!admin");
        _;
    }

    /// CONSTURCTOR ///

    /** 
     * @dev Creates a new smart contract for managing subscriptions
     * @param _treasury - address to send USDC tokens to
     * @param _admin - address allowed to administrate the smart contract
     * @param _usdc - address of payment token to use (USDC)
     */
    constructor(address _treasury, address _admin, address _usdc) {
        treasury = _treasury;
        admin = _admin;
        usdc = _usdc;
    }

    /// FUNCTIONS ///

    /**
     * Deposit USDC tokens to pay for BlockTrekker queries
     * @dev transfers payment tokens directly to treasury without possibility of refund/ withdrawal
     * @dev deposits limited to $10 to limit damange to users from negligence/ malice by any counterparty
     * 
     * @param _amount - the amount of USDC tokens to deposit 
     */
    function deposit(uint256 _amount) public {
        // ensure depositor does not exceed test contract limit for safety reasons
        require(_amount >= 10 * DECIMALS, "DepositLimit");
        // transfer payment tokens to treasury address or revert if failure
        require(IERC20(usdc).transferFrom(msg.sender, treasury, _amount), "!AffordDeposit");
        // update BlockTrekker balance with deposited value
        // @notice 10 USDC limit can be circumvented by calling many times, but why would you do that
        balances[msg.sender] = balances[msg.sender] + _amount;
        // log the deposit in an event
        emit Deposited(msg.sender, _amount);
    }

    /**
     * Debit value from a BlockTrekker account to reflect payment for queries on backend
     * @dev modifier onlyAdmin
     * @notice Admin will debit many queries in one (ex $0.23 + $1.24 + $.74 = debit of $2.21)
     * @notice this is the centralized point of failure where we couuld steal deposits. This is why deposits are
     *         limited to 10 USDC. Future improvements will use ZK TLS Notarization to prove debit correctness
     *
     * @param _from - the BlockTrekker account to debit value from
     * @param _amount - the amount of tokens to debit from the account
     */
    function debit(address _from, uint256 _amount) public onlyAdmin {
        // ensure the account being debited has a sufficient internal balance
        require(canAfford(_from, _amount), "!AffordDebit");
        // update BlockTrekker balances with debited value
        balances[_from] = balances[_from] - _amount;
        // log the debit in an event
        emit Debited(_from, _amount);
    }

    /**
     * Change the recipient address for the proceeds of BlockTrekker subscriptions
     * @dev modifier onlyAdmin
     *
     * @param _to - the address to set as the new treasury
     */
    function changeTreasury(address _to) public onlyAdmin {
        treasury = _to;
        emit TreasuryChanged(_to);
    }

    /**
     * Change the address allowed to administrate the BlockTrekker contract
     * @dev modifier onlyAdmin
     *
     * @param _to - the address to set as the new admin
     */
    function changeAdmin(address _to) public onlyAdmin {
        admin = _to;
        emit AdminChanged(_to);
    }

    /// VIEWS ///

    /**
     * Evaluate whether or not a given BlockTrekker query account has sufficient balance for a debit value
     *
     * @param _from - address being queried for balance
     * @param _amount - the amount of tokens the address must have to return true
     * @return - true if BlockTrekker balance is sufficient for proposed debit value, and false otherwise
     */
    function canAfford(address _from, uint256 _amount) public view returns (bool) {
        return balances[_from] >= _amount;
    }
    
}