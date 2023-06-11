// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "../src/BlockTrekkerDiamond.sol";
import "../src/facets/AdminFacet.sol";
import "../src/facets/DashboardTokenFacet.sol";
import "../src/facets/PaymentFacet.sol";
import "../src/facets/ViewFacet.sol";
import "diamond-3/facets/DiamondCutFacet.sol";
import "diamond-3/facets/DiamondLoupeFacet.sol";
import "diamond-3/facets/OwnershipFacet.sol";
import "./Helper.sol";

contract AdminFacetTest is Test, Helper {
    DiamondCutFacet dCutF;
    DiamondLoupeFacet dLoupeF;
    OwnershipFacet ownerF;
    AdminFacet adminF;
    DashboardTokenFacet tokenF;
    PaymentFacet paymentF;
    ViewFacet viewF;
    BlockTrekkerDiamond diamond;

    function setUp() public virtual {
        dCutF = new DiamondCutFacet();
        dLoupeF = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        adminF = new AdminFacet();
        tokenF = new DashboardTokenFacet();
        paymentF = new PaymentFacet();
        viewF = new ViewFacet();

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](7);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(dCutF),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondCutFacet")
        });
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(dLoupeF),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondLoupeFacet")
        });
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(ownerF),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("OwnershipFacet")
        });
        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(adminF),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("AdminFacet")
        });
        cut[4] = IDiamondCut.FacetCut({
            facetAddress: address(tokenF),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("DashboardTokenFacet")
        });
        cut[5] = IDiamondCut.FacetCut({
            facetAddress: address(paymentF),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("PaymentFacet")
        });
        cut[6] = IDiamondCut.FacetCut({
            facetAddress: address(viewF),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("ViewFacet")
        });

        BlockTrekkerDiamond.DiamondArgs memory args =
            BlockTrekkerDiamond.DiamondArgs({owner: msg.sender, treasury: msg.sender, usdc: address(0), feeBP: 500});

        diamond = new BlockTrekkerDiamond(cut, args);
    }

    function testAdminRBA() public {
        // check that 
        assertFalse(ViewFacet(address(diamond)).isWhitelisted(address(0xdead)));
        vm.prank(msg.sender);
        AdminFacet(address(diamond)).setWhitelister(address(0xdead), true);
        assertTrue(ViewFacet(address(diamond)).isWhitelisted(address(0xdead)));
    }
}
