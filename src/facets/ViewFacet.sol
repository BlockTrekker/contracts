// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;
pragma abicoder v2;

import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";

// =============================================================
//                      ADMINISTRATION V1
//  Administrative access to BlockTrekker contract ecosystem
// =============================================================
contract ViewFacet {
    AppStorage internal s;

    /**
     * Returns the treasury address that query deposits and subscription fees are sent to
     *
     * @return - the treasury address
     */
    function getTreasury() external view returns (address) {
        return s.treasury;
    }

    /**
     * Returns the fee charged for minting a dashboard token, as basis points
     *
     * @return - the fee basis points taken by platform
     */
    function getFeeBP() external view returns (uint16) {
        return s.feeBP;
    }

    /**
     * Returns the address of the USDC contract
     *
     * @return - the address of the USDC contract
     */
    function getUSDC() external view returns (address) {
        return s.usdc;
    }

    /**
     * Determines whether a given address is permissioned as a whitelister for creators
     *
     * @param _account - the address to check for whitelist permissions
     * @return - true if the address is a whitelister, false otherwise
     */
    function isWhitelisted(address _account) external view returns (bool) {
        return s.whitelisters[_account];
    }

    /**
     * Return the total number of ERC1155 dashboard tokens issued
     *
     * @return - the total number of ERC1155 dashboard tokens issued
     */
    function getNumTokens() external view returns (uint256) {
        return s.tokenNonce;
    }

    /**
     * Determine if a given address is enrolled as a BlockTrekker creator
     *
     * @param _account - the address to check for creator permission
     * @return - true if the address is a creator, false otherwise
     */
    function isCreator(address _account) external view returns (bool) {
        return s.creators[_account].auth;
    }

    /**
     * Get the tokens issued by a given creator
     *
     * @param _creator - the address of the creator to get tokens for
     * @return _tokenIds - an array of token ids issued by the creator
     */
    function getCreator(address _creator) external view returns (uint256[] memory _tokenIds) {
        // get creator from storage
        uint16 nonce = s.creators[_creator].nonce;
        _tokenIds = new uint256[](nonce);
        // build array of token ids issued by the creator
        for (uint16 i = 1; i <= nonce; i++) {
            _tokenIds[i - 1] = s.creators[_creator].tokens[i];
        }
    }

    /**
     * Get the dashboard token metadata for a given token
     *
     * @param _id - the token id to get metadata for
     * @return - the dashboard token metadata (creator, creator nonce, price)
     */
    function getToken(uint256 _id) external view returns (Token memory) {
        return s.tokens[_id];
    }
}