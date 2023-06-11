// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;
pragma abicoder v2;

import "forge-std/Test.sol";
import "../src/libraries/AppStorage.sol";
import "../src/BlockTrekkerDiamond.sol";
import "../src/facets/AdminFacet.sol";
import "../src/facets/DashboardTokenFacet.sol";
import "../src/facets/PaymentFacet.sol";
import "../src/facets/ViewFacet.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/facets/OwnershipFacet.sol";
import "./Helper.sol";
import "./USDC.sol";

contract DashboardTokenFacetTest is Test, Helper {
    // events
    event TokenAdded(uint256 indexed _tokenNonce);
    event TokenMinted(uint256 indexed _tokenNonce, address indexed _minter);
    event TokenPriceUpdated(uint256 indexed _tokenNonce);
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value); // ERC1155
    event Transfer(address indexed from, address indexed to, uint256 value); // ERC20

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

    // Test USDC ERC20
    USDC usdc;

    function setUp() public virtual {
        dCutF = new DiamondCutFacet();
        dLoupeF = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        adminF = new AdminFacet();
        tokenF = new DashboardTokenFacet();
        paymentF = new PaymentFacet();
        viewF = new ViewFacet();

        usdc = new USDC();

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
            BlockTrekkerDiamond.DiamondArgs({owner: msg.sender, treasury: msg.sender, usdc: address(usdc), feeBP: 500});

        diamond = new BlockTrekkerDiamond(cut, args);

        // set a creator
        vm.prank(address(msg.sender));
        AdminFacet(address(diamond)).setWhitelister(msg.sender, true);
        vm.prank(address(msg.sender));
        AdminFacet(address(diamond)).addCreator(address(0xdead));
    }

    function testAddTokenRBA() public {
        // expect a non-creator address cannot create a new token
        vm.expectRevert(bytes("!Creator"));
        vm.prank(address(0xeeee));
        DashboardTokenFacet(address(diamond)).addToken(10000000);

        // expect a creator address can create a new token

        vm.prank(address(0xdead));
        DashboardTokenFacet(address(diamond)).addToken(10000000);
    }

    function testAddToken() public {
        // expect global token nonce to be 0
        assertEq(ViewFacet(address(diamond)).getNumTokens(), 0);

        // expect creator to have no tokens stored
        assertEq(ViewFacet(address(diamond)).getCreator(address(0xdead)).length, 0);

        // create a new token
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(0xdead), address(0), address(0), 1, 0);
        vm.expectEmit(true, false, false, true);
        emit TokenAdded(1);
        vm.prank(address(0xdead));
        DashboardTokenFacet(address(diamond)).addToken(10000000);

        // expect global token nonce to be 1
        assertEq(ViewFacet(address(diamond)).getNumTokens(), 1);

        // expect creator to have 1 stored
        assertEq(ViewFacet(address(diamond)).getCreator(address(0xdead)).length, 1);

        // expect token metadata to be stored
        Token memory t = ViewFacet(address(diamond)).getToken(1);
        assertEq(t.creator, address(0xdead));
        assertEq(t.nonce, 1);
        assertEq(t.price, 10000000);
    }

    function testMintToken() public {
        // compute usdc transfer amonunts
        uint256 amount = 10000000;
        uint256 platformFee = amount * 500 / 10000; // 500 = platform fee BP
        uint256 creatorFee = amount - platformFee;

        // mint value to the token buyer
        usdc.mint(address(0xeeee), amount);
        vm.prank(address(0xeeee));
        usdc.approve(address(diamond), amount);

        // create a new token
        vm.prank(address(0xdead));
        DashboardTokenFacet(address(diamond)).addToken(amount);

        // expect creator and treasury balances to be 0
        assertEq(usdc.balanceOf(address(0xdead)), 0);
        assertEq(usdc.balanceOf(address(msg.sender)), 0);

        // mint a new token
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0xeeee), msg.sender, platformFee);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0xeeee), address(0xdead), creatorFee);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(address(0xeeee), address(0), address(0xeeee), 1, 1);
        vm.expectEmit(true, true, false, true);
        emit TokenMinted(1, address(0xeeee));
        vm.prank(address(0xeeee));
        DashboardTokenFacet(address(diamond)).mintToken(1);

        // expect creator and treasury balances to be minted amounts
        assertEq(usdc.balanceOf(address(0xdead)), creatorFee);
        assertEq(usdc.balanceOf(address(msg.sender)), platformFee);

        // expect token balance for user to be 1
        assertEq(DashboardTokenFacet(address(diamond)).balanceOf(address(0xeeee), 1), 1);
    }

    function testMintTokenUniqueHolder() public {}

    function testMintTokenInsufficientBalance() public {}

    // function testDeposit() public {
    //     uint256 amount = 100000000;

    //     // check that treasury is empty
    //     assertEq(usdc.balanceOf(address(msg.sender)), 0);

    //     // create conditions for usdc to be deposited via contract
    //     vm.prank(address(0xdead));
    //     usdc.mint(address(0xdead), amount);
    //     vm.prank(address(0xdead));
    //     usdc.approve(address(diamond), amount);

    //     // deposit fundss
    //     vm.expectEmit(true, true, false, true);
    //     emit Deposited(address(0xdead), amount);
    //     vm.prank(address(0xdead));
    //     PaymentFacet(address(diamond)).deposit(amount);

    //     // // check that treasury recieved funds
    //     assertEq(usdc.balanceOf(address(msg.sender)), amount);
    // }
}
