// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "solidstate-solidity/access/ownable/Ownable.sol";
import "solidstate-solidity/token/ERC1155/base/ERC1155Base.sol";
import "../storage/DashboardTokenStorage.sol";

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
abstract contract IDashboardToken is Ownable, ERC1155Base {
    /// EVENTS ///
    event CreatorAdded(address indexed _creator); // admin whitelisted a creator address to issue new dashboard tokens
    event TokenAdded(uint256 indexed _tokenNonce); // creator made a new dashboard access NFT
    event TokenMinted(uint256 indexed _tokenNonce, address indexed _minter); // user minted a dashboard access NFT
    event TokenPriceUpdated(uint256 indexed _tokenNonce); // creator changed the price to mint a dashboard access NFT

    /// MODIFIERS ///

    /**
     * Only allow whitelisted creator addresses to call a given function
     */
    modifier anyCreator() {
        require(DashboardTokenStorage.layout().creators[msg.sender].auth, "!Creator");
        _;
    }

    /**
     * Only allow creator of a specified token to call a given function
     *
     * @param _token - tokenId to check for creator membership
     */
    modifier onlyCreator(uint256 _token) {
        require(msg.sender == DashboardTokenStorage.layout().tokens[_token].creator, "!TokenCreator");
        _;
    }

    /**
     * Prevent a caller from minting a token they already own
     *
     * @param _token - tokenId to check for existing ownership by _minter
     */
    modifier uniqueHolder(uint256 _token) {
        require(balanceOf(msg.sender, _token) == 0, "!UniqueHolder");
        _;
    }

    /// FUNCTIONS ///

    /**
     * Whitelist a new creator that can create dashboard tokens on the platform
     * @dev modifier onlyWhitelister() - only whitelister can call this function
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

    /**
     * Change the mint price of a dashboard token
     * @dev modifier onlyCreator() - only the creator of the token can call this function
     * @dev inline requirement that price > 0
     *
     * @param _token - global tokenId to change the price of
     * @param _price - new price in USDC to mint the dashboard token
     */
    function changePrice(uint256 _token, uint256 _price) external virtual;

    /// VIEWS ///

    /**
     * Return the address for USDC used to compensate creators and the platform
     *
     * @return - the address of the usdc erc20 contract
     */
    function usdc() public view virtual returns (address);

    /**
     * Return the treasury address for blocktrekker that receives fees on each mint
     *
     * @return - the address of the treasury
     */
    function treasury() public view virtual returns (address);

    /**
     * Return the platform fee (basis points) that is paid to the admin treasury on each mint
     * @return - the basis points to calculate share paid to the admin treasury on each mint
     */
    function basisPoints() public view virtual returns (uint16);

    /**
     * Return the mint fee in USDC paid to treasury when a user mints a token
     *
     * @param _price - the price in USDC to mint the token
     * @return - the fee in USDC paid to treasury
     */
    function mintFee(uint256 _price) public view virtual returns (uint256);
}
