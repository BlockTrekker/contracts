// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/AppStorage.sol";
import "diamond-3/libraries/LibDiamond.sol";

// =============================================================
//                      ADMINISTRATION V1
//  Administrative access to BlockTrekker contract ecosystem
// =============================================================
contract AdminFacet {
    AppStorage internal s;

    /// EVENTS ///
    event TreasuryChanged(address indexed _to); // treasury address updated
    event FeeBPChanged(uint16 _feeBP); // fee basis points updated
    event WhitelisterAdded(address indexed _whitelister); // whitelister address added
    event WhitelisterRemoved(address indexed _whitelister); // whitelister address removed
    event CreatorAdded(address indexed _creator); // admin whitelisted a creator address to issue new dashboard tokens

    /// MODIFIERS ///

    /**
     * Only allow whitelister addresses to call the addCreator function in token contract
     */
    modifier onlyWhitelister() {
        require(s.whitelisters[msg.sender], "!Whitelister");
        _;
    }

    /// FUNCTIONS ///

    /**
     * Change the recipient address for the proceeds of BlockTrekker subscriptions
     *
     * @param _to - the address to set as the new treasury
     */
    function changeTreasury(address _to) external {
        LibDiamond.enforceIsContractOwner();
        s.treasury = _to;
        emit TreasuryChanged(_to);
    }

    /**
     * Change the fee rate (in basis points)
     *  - ex: 5% fee -> _feeBP = 500
     *
     * @param _feeBP - the basis points to set for the new fee
     */
    function changeFeeBP(uint16 _feeBP) external {
        LibDiamond.enforceIsContractOwner();
        s.feeBP = _feeBP;
        emit FeeBPChanged(_feeBP);
    }

    /**
     * Add a whitelister address that can call the addCreator function in dashboard token contract
     *
     * @param _whitelister - the address to add as a whitelister
     * @param _permission - true if address should be set as whitelister
     *                      false if address should not be set as whitelister
     */
    function setWhitelister(address _whitelister, bool _permission) external {
        LibDiamond.enforceIsContractOwner();
        s.whitelisters[_whitelister] = _permission;
        if (_permission) {
            emit WhitelisterAdded(_whitelister);
        } else {
            emit WhitelisterRemoved(_whitelister);
        }
    }

    /**
     * Whitelist a new creator that can create dashboard tokens on the platform
     * @dev modifier onlyWhitelister() - only whitelister can call this function
     *
     * @param _creator - address of the organization
     */
    function addCreator(address _creator) external onlyWhitelister {
        // add the creator to the whitelist
        s.creators[_creator].auth = true;
        // log the creator addition event
        emit CreatorAdded(_creator);
    }
}
