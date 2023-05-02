// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IBlockTrekker
 * @dev Interface for BlockTrekker admin contract
 * @notice admin contract for BlockTrekker contract ecosystem
 */
abstract contract IBlockTrekker is Ownable {
    /// EVENTS ///
    event Initialized(address _dashboardToken, address _queryPaymaster); // initialized control over ecosystem contracts
    event TreasuryChanged(address indexed _to); // treasury address updated
    event FeeBPChanged(uint16 _feeBP); // fee basis points updated
    event WhitelisterAdded(address indexed _whitelister); // whitelister address added
    event WhitelisterRemoved(address indexed _whitelister); // whitelister address removed
    event DebitorAdded(address indexed _debitor); // debitor address added
    event DebitorRemoved(address indexed _debitor); // debitor address removed

    /// VARIABLES ///
    address public treasury; // address that receives tokens from a subcription transfer
    address public usdc; // address of the deployed ERC20 contract for USDC
    address public dashboardToken; // address of the deployed dashboard token contract
    address public queryPayments; // address of the deployed query payments contract
    uint16 public feeBP; // fee basis points taken from dashboard token mints
    bool public initialized; // toggle to ensure initialization of smart contracts

    /// MAPPINGS ///
    mapping(address => bool) public whitelisters; // map of addressess that can whitelist creators in dashboard token contract
    mapping(address => bool) public debitors; // map of addresses that can debit query balances in query payments contract

    /// MODIFIERS ///

    /**
     * Only allow whitelister addresses to call the addCreator function in token contract
     */
    modifier onlyWhitelister() {
        require(whitelisters[msg.sender], "!Whitelister");
        _;
    }

    /**
     * Only allow debitor addresses to call the debit function in payment contract
     */
    modifier onlyDebitor() {
        require(debitors[msg.sender], "!Debitor");
        _;
    }

    /// FUNCTIONS ///

    /**
     * Initialize the BlockTrekker admin contract and point at dashboard token & query paymaster contracts
     * @dev modifier onlyOwner
     * @dev inline requirement that contract has not been initialized
     *
     * @param _dashboardToken - address of the deployed dashboard token contract
     * @param _queryPayments - address of the deployed query payments contract
     */
    function initialize(
        address _dashboardToken,
        address _queryPayments
    ) public virtual;

    /**
     * Change the recipient address for the proceeds of BlockTrekker subscriptions
     * @dev modifier onlyOwner
     *
     * @param _to - the address to set as the new treasury
     */
    function changeTreasury(address _to) public virtual;

    /**
     * Change the fee rate (in basis points)
     *  - ex: 5% fee -> _feeBP = 500
     * @dev modifier onlyOwner
     *
     * @param _feeBP - the basis points to set for the new fee
     */
    function changeFeeBP(uint16 _feeBP) public virtual;

    /**
     * Add a whitelister address that can call the addCreator function in dashboard token contract
     * @dev modifier onlyOwner
     *
     * @param _whitelister - the address to add as a whitelister
     */
    function addWhitelister(address _whitelister) public virtual;

    /**
     * Remove a whitelister address that can call the addCreator function in dashboard token contract
     * @dev modifier onlyOwner
     *
     * @param _whitelister - the address to remove as a whitelister
     */
    function removeWhitelister(address _whitelister) public virtual;

    /**
     * Add a debitor address that can call the debit function in query payments contract
     * @dev modifier onlyOwner
     *
     * @param _debitor - the address to add as a debitor
     */
    function addDebitor(address _debitor) public virtual;

    /**
     * Remove a debitor address that can call the debit function in query payments contract
     * @dev modifier onlyOwner
     *
     * @param _debitor - the address to remove as a debitor
     */
    function removeDebitor(address _debitor) public virtual;

    /**
     * Add a creator address that can call the mint function in dashboard token contract
     * @dev modifier onlyWhitelister
     * @notice see IDashboardToken::addCreator()
     *
     * @param _creator - the address to add as a creator
     */
    function addCreator(address _creator) public virtual;

    /**
     * Debit value from a BlockTrekker account to reflect payment for queries on backend
     * @dev modifier onlyDebitor
     * @notice see IQueryPaymaster::debit()
     *
     * @param _from - the BlockTrekker account to debit value from
     * @param _amount - the amount of tokens to debit from the account
     */
    function debit(address _from, uint256 _amount) public virtual;
}
