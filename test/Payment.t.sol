// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;
pragma abicoder v2;

import "forge-std/Test.sol";
import "../src/BlockTrekkerDiamond.sol";
import "../src/facets/AdminFacet.sol";
import "../src/facets/DashboardTokenFacet.sol";
import "../src/facets/PaymentFacet.sol";
import "../src/facets/ViewFacet.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/facets/OwnershipFacet.sol";
import "./Helper.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AdminFacetTest is Test, Helper {
    /// EVENTS ///
    event Deposited(address _from, uint256 _amount); // a query payment was made to the treasury
}