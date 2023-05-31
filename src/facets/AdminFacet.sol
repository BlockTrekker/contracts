// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../libraries/AppStorage.sol";

contract AdministrationFacet {
    // =============================================================
    //                      ADMINISTRATION V1
    //  Administrative access to BlockTrekker contract ecosystem
    // =============================================================

    AppStorage internal s;

    /// MODIFIERS ///
    // modifier onlyOwner();

    // function changeTreasury(address _to) public override onlyOwner {
    //     // get layout struct
    //     BlockTrekkerStorage.Layout storage l = BlockTrekkerStorage.layout();
    //     // set treasury
    //     l.treasury = _to;
    //     emit TreasuryChanged(_to);
    // }
}
