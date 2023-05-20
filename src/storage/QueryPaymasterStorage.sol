pragma solidity ^0.8.0;

library QueryPaymasterStorage {
    struct Layout {
        // =============================================================
        //                            STORAGE
        // =============================================================

        // map address to query balance
        mapping(address => uint256) balances;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("BlockTrekker.contracts.storage.QueryPaymaster");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
