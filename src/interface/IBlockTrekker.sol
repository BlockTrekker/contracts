// SPDX-License-Identifier: GPL-3.0

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDashboardToken.sol";
import "./IQueryPayments.sol";

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title BlockTrekker
 * @dev BlockTrekker admin contract
 * @notice admin contract for BlockTrekker contract ecosystem
 */
contract IBlockTrekker {
    /// EVENTS ///
    event Initialized(address _dashboardToken, uint16 _feeBP); // initialized control over ecosystem contracts
    event TreasuryChanged(address indexed _to); // treasury address updated
    event WhitelisterAdded(address indexed _whitelister); // whitelister address added
    event WhitelisterRemoved(address indexed _whitelister); // whitelister address removed

    /// VARIABLES ///
    address public treasury; // address that receives tokens from a subcription transfer
    address public usdc; // address of the deployed ERC20 contract for USDC
    address public dashboardToken; // address of the deployed dashboard token contract
    address public queryPayments; // address of the deployed query payments contract
    uint16 public feeBP; // fee basis points taken from dashboard token mints
    
    /// MAPPINGS ///
    mapping(address => bool) public whitelisters; // map of addressess that can whitelist creators in dashboard token contract

    /// MODIFIERS ///

}