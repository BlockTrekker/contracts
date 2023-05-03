// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IBlockTrekker.sol";
import "./interface/IDashboardToken.sol";
import "./interface/IQueryPaymaster.sol";

/**
 * @title BlockTrekker
 * @dev BlockTrekker subscription contract
 */
contract BlockTrekker is IBlockTrekker {
    /// CONSTRUCTOR ///

    /**
     * Deploy a new BlockTrekker administration contract
     * @dev deploy BlockTrekker.sol -> deploy DashboardToken.sol & QueryPaymaster.sol -> call initialize() with dashboard & paymaster addresses
     *
     * @param _usdc - address of the deployed USDC contract to use as a payment medium in the BlockTrekker ecosystem
     * @param _treasury - address of the treasury to receive subscription payments
     * @param _feeBP - fee basis points taken from dashboard token mints
     */
    constructor(address _usdc, address _treasury, uint16 _feeBP) {
        // set the USDC token address
        usdc = _usdc;
        // set the treasury address
        treasury = _treasury;
        // set the fee basis points
        feeBP = _feeBP;
    }

    /// FUNCTIONS ///

    function initialize(
        address _dashboardToken,
        address _queryPayments
    ) public override onlyOwner {
        // check that the contract has not already been initialized
        require(!initialized, "Initialized");
        // store the addresses for ecosystem contracts
        dashboardToken = _dashboardToken;
        queryPayments = _queryPayments;
        // set the contract as initialized
        initialized = true;
        // emit the initialization event
        emit Initialized(_dashboardToken, _queryPayments);
    }

    function changeTreasury(address _to) public override onlyOwner {
        treasury = _to;
        emit TreasuryChanged(_to);
    }

    function changeFeeBP(uint16 _feeBP) public override onlyOwner {
        feeBP = _feeBP;
        emit FeeBPChanged(_feeBP);
    }

    function addWhitelister(address _whitelister) public override onlyOwner {
        whitelisters[_whitelister] = true;
        emit WhitelisterAdded(_whitelister);
    }

    function removeWhitelister(address _whitelister) public override onlyOwner {
        whitelisters[_whitelister] = false;
        emit WhitelisterRemoved(_whitelister);
    }

    function addDebitor(address _debitor) public override onlyOwner {
        debitors[_debitor] = true;
        emit DebitorAdded(_debitor);
    }

    function removeDebitor(address _debitor) public override onlyOwner {
        debitors[_debitor] = false;
        emit DebitorRemoved(_debitor);
    }

    function addCreator(address _creator) public override onlyWhitelister {
        IDashboardToken(dashboardToken).addCreator(_creator);
    }

    function debit(address _from, uint256 _amount) public override onlyDebitor {
        IQueryPaymaster(queryPayments).debit(_from, _amount);
    }
}
