// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

import "forge-std/Script.sol";
import "../src/BlockTrekkerDiamond.sol";
import "../src/facets/AdminFacet.sol";
import "../src/facets/DashboardTokenFacet.sol";
import "../src/facets/PaymentFacet.sol";
import "../src/facets/ViewFacet.sol";
import "diamond-3/facets/DiamondCutFacet.sol";
import "diamond-3/facets/DiamondLoupeFacet.sol";
import "diamond-3/facets/OwnershipFacet.sol";
import "../test/Helper.sol";

// import "../src/facets/DiamondLoupeFacet.sol";
// import "../src/facets/OwnershipFacet.sol";
// import "../src/upgradeInitializers/DiamondInit.sol";

contract DeployBlockTrekker is Script, Helper {

    address usdc;
    address treasury;
    uint16 feeBP;

    function setUp() public {
        // CONSTRUCTOR PARAMS FOR ALL CONTRACTS
        usdc = 0x3C8AC1D5Bd747EF24af4370a652573aF003C6A0c;
        treasury = 0x3729a6a9ceD02C9d0A86ec9834b28825B212aBF3;
        feeBP = 2500;
        // tokenURI = "https://api.blocktrekker.xyz/token/";
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        //deploy facets and init contract
        DiamondCutFacet dCutF = new DiamondCutFacet();
        DiamondLoupeFacet dLoupeF = new DiamondLoupeFacet();
        OwnershipFacet ownerF = new OwnershipFacet();
        AdminFacet adminF = new AdminFacet();
        DashboardTokenFacet tokenF = new DashboardTokenFacet();
        PaymentFacet paymentF = new PaymentFacet();
        ViewFacet viewF = new ViewFacet();


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

        BlockTrekkerDiamond.DiamondArgs memory args = BlockTrekkerDiamond.DiamondArgs({
            owner: msg.sender,
            treasury: treasury,
            usdc: usdc,
            feeBP: feeBP
        });

        BlockTrekkerDiamond diamond = new BlockTrekkerDiamond(cut, args);

        vm.stopBroadcast();
    }
}
