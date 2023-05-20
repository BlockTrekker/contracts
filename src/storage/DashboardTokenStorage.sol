pragma solidity ^0.8.0;

library DashboardTokenStorage {

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

    struct Layout {
        // =============================================================
        //                            STORAGE
        // =============================================================

        // number of unique token types created in ERC1155 contract
        uint256 tokenNonce;

        // map creator addresses to their state
        mapping(address => Creator) creators;

        // map global token id to dashboard state
        mapping(uint256 => Token) tokens;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("BlockTrekker.contracts.storage.DashboardToken");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
