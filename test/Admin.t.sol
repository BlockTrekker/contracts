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

contract AdminFacetTest is Test, Helper {
    // events
    event TreasuryChanged(address indexed _to);
    event FeeBPChanged(uint16 _feeBP);
    event WhitelisterAdded(address indexed _whitelister);
    event WhitelisterRemoved(address indexed _whitelister);
    event CreatorAdded(address indexed _creator);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // facet contracts
    DiamondCutFacet dCutF;
    DiamondLoupeFacet dLoupeF;
    OwnershipFacet ownerF;
    AdminFacet adminF;
    DashboardTokenFacet tokenF;
    PaymentFacet paymentF;
    ViewFacet viewF;

    // diamond contract
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

    // ensure only the contract owner can set a creator whitelister
    function testSetWhitelisterRBA() public {
        // check that wrong address cannot set a creator whitelister
        vm.prank(address(0xdead));
        vm.expectRevert(bytes("LibDiamond: Must be contract owner"));
        AdminFacet(address(diamond)).setWhitelister(address(0xdead), true);

        // check that the correct address can set a creator whitelister
        vm.prank(msg.sender);
        AdminFacet(address(diamond)).setWhitelister(address(0xdead), true);
    }

    // check that a whitelister can be set and unset
    function testSetWhitelister() public {
        // expect address to not be enrolled as whitelister
        assertFalse(ViewFacet(address(diamond)).isWhitelisted(address(0xdead)));

        // enroll address as whitelister
        vm.expectEmit(true, false, false, true);
        emit WhitelisterAdded(address(0xdead));
        vm.prank(msg.sender);
        AdminFacet(address(diamond)).setWhitelister(address(0xdead), true);

        // expect address to be enrolled as whitelister
        assertTrue(ViewFacet(address(diamond)).isWhitelisted(address(0xdead)));

        // unenroll address as a whitelister
        vm.expectEmit(true, false, false, true);
        emit WhitelisterRemoved(address(0xdead));
        vm.prank(msg.sender);
        AdminFacet(address(diamond)).setWhitelister(address(0xdead), false);

        // expect address to be enrolled as whitelister
        assertFalse(ViewFacet(address(diamond)).isWhitelisted(address(0xdead)));
    }

    // check that only a whitelister can add a creator
    function testAddCreatorRBA() public {
        // check that wrong address cannot set a creator whitelister
        vm.prank(address(0xdead));
        vm.expectRevert(bytes("!Whitelister"));
        AdminFacet(address(diamond)).addCreator(address(0xeeee));

        // add a whitelister
        vm.prank(msg.sender);
        AdminFacet(address(diamond)).setWhitelister(address(0xdead), true);

        // check that the correct address can set a creator whitelister
        vm.prank(address(0xdead));
        AdminFacet(address(diamond)).addCreator(address(0xeeee));
    }

    // check that a whitelister can add a creator, and that the creator shows as permissioned
    function testAddCreator() public {
        // add a whitelister
        vm.prank(msg.sender);
        AdminFacet(address(diamond)).setWhitelister(address(0xdead), true);

        // expect address to not be enrolled as creator
        assertFalse(ViewFacet(address(diamond)).isCreator(address(0xeeee)));

        // enroll address as creator
        vm.expectEmit(true, false, false, true);
        emit CreatorAdded(address(0xeeee));
        vm.prank(address(0xdead));
        AdminFacet(address(diamond)).addCreator(address(0xeeee));

        // expect address to be enrolled as creator
        assertTrue(ViewFacet(address(diamond)).isCreator(address(0xeeee)));
    }

    // check that only the contract owner can change the treasury address
    function testChangeTreasuryRBA() public {
        // check that wrong address cannot set a creator whitelister
        vm.prank(address(0xdead));
        vm.expectRevert(bytes("LibDiamond: Must be contract owner"));
        AdminFacet(address(diamond)).changeTreasury(address(0xdead));

        // check that the correct address can set a creator whitelister
        vm.prank(msg.sender);
        AdminFacet(address(diamond)).changeTreasury(address(0x00));
    }

    // check that the treasury address can be updated so that funds arrive to the new address
    function testChangeTreasury() public {
        // expect treasury to be set to msg.sender
        assertEq(msg.sender, ViewFacet(address(diamond)).getTreasury());

        // change treasury to address(0xdead)
        vm.expectEmit(true, false, false, true);
        emit TreasuryChanged(address(0xdead));
        vm.prank(msg.sender);
        AdminFacet(address(diamond)).changeTreasury(address(0xdead));

        // expect treasury to be set to address(0xdead)
        assertEq(address(0xdead), ViewFacet(address(diamond)).getTreasury());
    }

    // check that only the contract owner can change the platform fee in basis points
    function testChangeFeeBPRBA() public {
        // check that wrong address cannot set a creator whitelister
        vm.prank(address(0xdead));
        vm.expectRevert(bytes("LibDiamond: Must be contract owner"));
        AdminFacet(address(diamond)).changeFeeBP(10000);

        // check that the correct address can set a creator whitelister
        vm.prank(msg.sender);
        AdminFacet(address(diamond)).changeFeeBP(100);
    }

    // check that the platform fee in basis points charged on token mint can be updated
    function testChangeFeeBP() public {
        // expect treasury to be set to msg.sender
        assertEq(500, uint256(ViewFacet(address(diamond)).getFeeBP()));

        // change treasury to address(0xdead)
        vm.expectEmit(true, false, false, true);
        emit FeeBPChanged(1500);
        vm.prank(msg.sender);
        AdminFacet(address(diamond)).changeFeeBP(1500);

        // expect treasury to be set to address(0xdead)
        assertEq(1500, uint256(ViewFacet(address(diamond)).getFeeBP()));
    }

    // check that only the contract owner can change the owner of the contract
    function testTransferOwnershipRBA() public {
        // check that wrong address cannot set a creator whitelister
        vm.prank(address(0xdead));
        vm.expectRevert(bytes("LibDiamond: Must be contract owner"));
        OwnershipFacet(address(diamond)).transferOwnership(address(0xdead));

        // check that the correct address can set a creator whitelister
        vm.prank(msg.sender);
        OwnershipFacet(address(diamond)).transferOwnership(address(0xdead));
    }

    // check that the contract owner can update the address that owns the contract
    function testTransferOwnership() public {
        // expect treasury to be set to msg.sender
        assertEq(msg.sender, OwnershipFacet(address(diamond)).owner());

        // change treasury to address(0xdead)
        vm.expectEmit(true, true, false, true);
        emit OwnershipTransferred(msg.sender, address(0xdead));
        vm.prank(msg.sender);
        OwnershipFacet(address(diamond)).transferOwnership(address(0xdead));

        // expect treasury to be set to address(0xdead)
        assertEq(address(0xdead), OwnershipFacet(address(diamond)).owner());

        // check that permissions have switched
        vm.prank(msg.sender);
        vm.expectRevert(bytes("LibDiamond: Must be contract owner"));
        AdminFacet(address(diamond)).changeFeeBP(1500);
        vm.prank(address(0xdead));
        AdminFacet(address(diamond)).changeFeeBP(1500);
    }
}
