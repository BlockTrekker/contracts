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

    // ensure only a token creator can create a new token
    function testAddTokenRBA() public {
        // expect a non-creator address cannot create a new token
        vm.expectRevert(bytes("!Creator"));
        vm.prank(address(0xeeee));
        DashboardTokenFacet(address(diamond)).addToken(10000000);

        // expect a creator address can create a new token

        vm.prank(address(0xdead));
        DashboardTokenFacet(address(diamond)).addToken(10000000);
    }

    // ensure a creator can create a new dashboard token and store metadata
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

    // ensure that a creator properly stores references to the global ids of their own tokens
    function testAddTokenCreatorArr() public {
        // add a second creator
        vm.prank(address(msg.sender));
        AdminFacet(address(diamond)).addCreator(address(0xeeee));

        // create tokens 1 and 2 to 0xdead
        vm.prank(address(0xdead));
        DashboardTokenFacet(address(diamond)).addToken(10000000);
        vm.prank(address(0xdead));
        DashboardTokenFacet(address(diamond)).addToken(5000000);

        // create token 3 to 0xeeee
        vm.prank(address(0xeeee));
        DashboardTokenFacet(address(diamond)).addToken(7500000);

        // // create token 4 to 0xdead
        vm.prank(address(0xdead));
        DashboardTokenFacet(address(diamond)).addToken(10000000);

        // // create tokens 5, 6, and 7 to 0xee
        vm.prank(address(0xeeee));
        DashboardTokenFacet(address(diamond)).addToken(10000000);
        vm.prank(address(0xeeee));
        DashboardTokenFacet(address(diamond)).addToken(5000000);
        vm.prank(address(0xeeee));
        DashboardTokenFacet(address(diamond)).addToken(7500000);

        // get creator token arrays
        uint256[] memory tokens1 = ViewFacet(address(diamond)).getCreator(address(0xdead));
        uint256[] memory tokens2 = ViewFacet(address(diamond)).getCreator(address(0xeeee));

        // expect creator 0xdead to have 3 tokens
        assertEq(tokens1.length, 3);

        // expect creator 0xeeee to have 4 tokens
        assertEq(tokens2.length, 4);

        // expect creator 0xdead to have token array = [1, 2, 4]
        uint256[3] memory expected1 = [uint256(1), 2, 4];
        for (uint256 i = 0; i < expected1.length; i++) {
            assertEq(tokens1[i], expected1[i]);
        }

        // expect creator 0xeeee to have token array = [3, 5, 6, 7]
        uint256[4] memory expected2 = [uint256(3), 5, 6, 7];
        for (uint256 i = 0; i < expected2.length; i++) {
            assertEq(tokens2[i], expected2[i]);
        }
    }

    // ensure that a dashboard consumer can purchase a token and that the creator and treasury are paid
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

    // ensure that a dashboard consumer cannot mint a token if they already hold it
    function testMintTokenUniqueHolder() public {
        uint256 amount = 10000000;

        // mint value to the token buyer
        usdc.mint(address(0xeeee), amount);
        vm.prank(address(0xeeee));
        usdc.approve(address(diamond), amount);

        // create a new token
        vm.prank(address(0xdead));
        DashboardTokenFacet(address(diamond)).addToken(amount);

        // mint a new token
        vm.prank(address(0xeeee));
        DashboardTokenFacet(address(diamond)).mintToken(1);

        // try to mint the same token while already holding it
        vm.expectRevert(bytes("!UniqueHolder"));
        vm.prank(address(0xeeee));
        DashboardTokenFacet(address(diamond)).mintToken(1);
    }

    // ensure that a dashboard consumer cannot mint a token if they do not have enough USDC
    function testMintTokenInsufficientBalance() public {
        uint256 amount = 9500000;

        // mint insufficient balance to the token buyer
        usdc.mint(address(0xeeee), amount);
        vm.prank(address(0xeeee));
        usdc.approve(address(diamond), amount);

        // create a new token
        vm.prank(address(0xdead));
        DashboardTokenFacet(address(diamond)).addToken(10000000);

        // try to mint a new token
        vm.expectRevert(bytes("!AffordMint"));
        vm.prank(address(0xeeee));
        DashboardTokenFacet(address(diamond)).mintToken(1);
    }

    // ensure that only a token's creator can mutate the mint price
    function testChangePriceRBA() public {
        // create a new token
        vm.prank(address(0xdead));
        DashboardTokenFacet(address(diamond)).addToken(10000000);

        // expect a non-creator address cannot change the price
        vm.expectRevert(bytes("!TokenCreator"));
        vm.prank(address(0xeeee));
        DashboardTokenFacet(address(diamond)).changePrice(1, 5000000);

        // enroll 0xeeee as a creator
        vm.prank(address(msg.sender));
        AdminFacet(address(diamond)).addCreator(address(0xdead));

        // expect creator that did not issue the token cannot change the price
        vm.expectRevert(bytes("!TokenCreator"));
        vm.prank(address(0xeeee));
        DashboardTokenFacet(address(diamond)).changePrice(1, 5000000);

        // expect token creator can change price
        vm.prank(address(0xdead));
        DashboardTokenFacet(address(diamond)).changePrice(1, 5000000);
    }

    // ensure that a creator can update the mint price of one of their own tokens
    function testChangePrice() public {
        // create a new token
        uint256 amount = 10000000;
        vm.prank(address(0xdead));
        DashboardTokenFacet(address(diamond)).addToken(amount);

        // expect token price to be 10000000
        assertEq(ViewFacet(address(diamond)).getToken(1).price, amount);

        // change price to 5000000
        amount = 5000000;
        vm.prank(address(0xdead));
        DashboardTokenFacet(address(diamond)).changePrice(1, amount);

        // expect token price to be 5000000
        assertEq(ViewFacet(address(diamond)).getToken(1).price, amount);
    }
}
