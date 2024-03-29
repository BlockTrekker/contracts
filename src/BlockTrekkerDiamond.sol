// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;
pragma abicoder v2;

import "./libraries/LibDiamond.sol";
import "./interfaces/IDiamondLoupe.sol";
import "./interfaces/IDiamondCut.sol";
import "./interfaces/IERC165.sol";
import "./interfaces/IERC173.sol";
import "./libraries/AppStorage.sol";

contract BlockTrekkerDiamond {
    AppStorage s;

    struct DiamondArgs {
        address owner;
        address treasury;
        address usdc;
        uint16 feeBP;
    }

    constructor(IDiamondCut.FacetCut[] memory _diamondCut, DiamondArgs memory _args) payable {
        LibDiamond.diamondCut(_diamondCut, address(0), new bytes(0));
        LibDiamond.setContractOwner(_args.owner);

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // set constructor storage

        s.treasury = _args.treasury;
        s.usdc = _args.usdc;
        s.feeBP = _args.feeBP;

        // adding ERC165 data
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        // erc1155 compatibility
        ds.supportedInterfaces[0xd9b67a26] = true;
        // erc1155 metadata compatibility
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
