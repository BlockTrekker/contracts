pragma solidity ^0.8.0;

struct Creator {
        bool auth; // toggle by admin that allows a creator to build tokens
        uint16 nonce; // defines the dashboard token nonce for a given dashboard creator (65535 per creator)
        mapping(uint16 => uint256) tokens; // map of incremental creator dashboard nonce to global erc1155 token id
    }

    struct Token {
        address creator; // the creator that issued a token
        uint16 nonce; // the creator nonce that identifies token within domain of creator
        uint256 price; // the price in USDC to mint the ERC1155 token
    }

library BlockTrekkerStorage {
    struct Layout {
        // =============================================================
        //                            STORAGE
        // =============================================================
        
        // address that receives tokens from a subcription transfer
        address treasury;
        // address of the deployed ERC20 contract for USDC
        address usdc;
        // address of the deployed dashboard token contract
        address dashboardToken; 
        // address of the deployed query payments contract
        address queryPayments;
        // fee basis points taken from dashboard token mints
        uint16 feeBP;
        // toggle to ensure initialization of smart contracts
        bool initialized;

        /// MAPPINGS ///
        // map of addressess that can whitelist creators in dashboard token contract
        mapping(address => bool) whitelisters;
        // map of addresses that can debit query balances in query payments contract
        mapping(address => bool) debitors; 
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("BlockTrekker.contracts.storage.BlockTrekker");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
