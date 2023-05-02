// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * Dashboard Tokens are issued by
 *
 * Features:
 *  - Admin contract whitelists Creators to be allowed to create NFT's
 *  - Admin contract sets fee rate taken from NFT mints by Users
 *  - Creators can make new dashboard tokens with defined mint price in USDC
 *     - Dashboards identified as 2d mapping [creatorAddress][dashboardId]
 *  - Users can mint dashboard tokens to access dashboards for a fee paid in USDC
 *
 * TODO: MerkleDrop addresses
 */
abstract contract IDashboardToken is Ownable, ERC1155 {
    /// EVENTS ///
    event Initialized(address _admin, uint16 _feeBP); // deployer initizlied contract with admin contract & fee
    event CreatorAdded(address indexed _creator); // admin whitelisted a creator address to issue new dashboard tokens
    event TokenAdded(uint256 indexed _tokenNonce); // creator made a new dashboard access NFT
    event TokenMinted(uint256 indexed _tokenNonce, address indexed _minter); // user minted a dashboard access NFT
    event TokenPriceUpdated(uint256 indexed _tokenNonce); // creator changed the price to mint a dashboard access NFT
    event PlatformFeeUpdated(uint16 _feeBP); // admin updated global fee (in basis points) taken as platform fee

    /// VARIABLES ///
    bool public initialized; // boolean that determines whether contract has been initialized
    uint16 public platformFeeBP; // platform fee paid to admin treasury on
    uint256 public tokenNonce; // number of unique token types created in ERC1155 contract

    /// MAPPINGS ///
    mapping(address => Creator) public creators; // map creator addresses to their state
    mapping(uint256 => Token) public tokens; // map global token id to dashboard state

    /// STRUCTS ///
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

    /// MODIFIERS ///

    /**
     * Only allow function to be called if contract has not been initialized
     */
    modifier uninitialized() {
        require(!initialized, "Initialized");
        _;
    }

    /**
     * Only allow whitelisted creator addresses to call a given function
     *
     * @param _creator - address of the creator to check for whitelist membership
     */
    modifier onlyCreator(address _creator) {
        require(creators[_creator].auth, "!Creator");
        _;
    }

    /**
     * Only allow creator of a specified token to call a given function
     *
     * @param _token - tokenId to check for creator membership
     */
    modifier onlyTokenCreator(uint256 _token) {
        require(msg.sender == tokens[_token].creator, "!TokenCreator");
        _;
    }

    /**
     * Prevent a user from minting a token they already own
     *
     * @param _minter - address of the user to check for existing token ownership of _token
     * @param _token - tokenId to check for existing ownership by _minter
     */
    modifier uniqueHolder(address _minter, uint256 _token) {
        require(balanceOf(_minter, _token) == 0, "!UniqueHolder");
        _;
    }

    /// FUNCTIONS ///

    /**
     * Whitelist a new creator that can create dashboard tokens on the platform
     * @dev modifier onlyOwner() - only the owner of the contract can call this function
     * @notice no check on re-whitelisting addresses since the consequences are minimal
     *
     * @param _creator - address of the organization
     */
    function addCreator(address _creator) external virtual;

    /**
     * Create a new dashboard token with a specified price in USDC
     * @dev modifier onlyCreator() - only whitelisted creators can call this function
     * @dev inline requirement that price > 0
     *
     * @param _price - price in USDC to mint the dashboard token
     */
    function addToken(uint256 _price) external virtual;

    /**
     * Mint (purchase) a dashboard token as a user to gain access to a dashboard in the web app
     * @dev modifier uniqueHolder() - only allow minting if user does not already own the token
     * @dev inline requirement that address has approved sufficient balance for this contract to debit
     * @notice todo: ERC20 permit
     *
     * @param _token - tokenId to mint to the user
     */
    function mintToken(uint256 _token) external virtual;

    /// VIEWS ///
}
