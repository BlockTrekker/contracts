// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

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

struct AppStorage {
    // =============================================================
    //                            ADMINISTRATION V1
    // =============================================================
    // address that receives tokens from a subcription transfer
    address treasury;
    // address of the deployed ERC20 contract for USDC
    address usdc;
    // fee basis points taken from dashboard token mints
    uint16 feeBP;
    // map of addressess that can whitelist creators in dashboard token contract
    mapping(address => bool) whitelisters;
    // =============================================================
    //                            TOKEN V1
    // =============================================================
    // ERC1155 token standard storage
    mapping(uint256 => mapping(address => uint256)) balances;
    mapping(address => mapping(address => bool)) operatorApprovals;
    // number of unique token types created in ERC1155 contract
    uint256 tokenNonce;
    // map creator addresses to their state
    mapping(address => Creator) creators;
    // map global token id to dashboard state
    mapping(uint256 => Token) tokens;

}

