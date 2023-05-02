// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./interface/IDashboardToken.sol";
import "./interface/IBlockTrekker.sol";

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
abstract contract DashboardToken is IDashboardToken {
    /// CONSTRUCTOR ///

    /**
     * Initialize the dashboard token contract and point ownership at the BlockTrekker admin contract
     *
     * @param _blocktrekker - address of the BlockTrekker admin contract
     */
    constructor(address _blocktrekker) {
        // set ownership over contract to be the BlockTrekker admin contract
        transferOwnership(_blocktrekker);
    }

    /// FUNCTIONS ///

    function addCreator(address _creator) external override onlyOwner {
        // add the creator to the whitelist
        creators[_creator].auth = true;
        // log the creator addition event
        emit CreatorAdded(_creator);
    }

    function addToken(uint256 _price) external override anyCreator {
        // ensure the price is greater than 0
        require(_price > 0, "!Price>0");
        // increment the creator token nonce
        creators[msg.sender].nonce++;
        // increment the global token nonce
        tokenNonce++;
        // set the token state
        tokens[tokenNonce] = Token({
            creator: msg.sender,
            nonce: creators[msg.sender].nonce,
            price: _price
        });
        // set the creator state
        // todo: remove with subgraph indexing
        creators[msg.sender].tokens[creators[msg.sender].nonce] = tokenNonce;
        // log the token creation event
        emit TokenAdded(tokenNonce);
    }

    function mintToken(uint256 _token) external override uniqueHolder(_token) {
        address usdcAddress = IBlockTrekker(owner()).usdc();
        // ensure the user can afford the entire mint price
        require(
            IERC20(usdcAddress).allowance(msg.sender, address(this)) >=
                tokens[_token].price,
            "!AffordMint"
        );
        // compute the fee taken by the platform & remaining fee taken by creator when minting
        uint256 platformFee = mintFee(tokens[_token].price);
        uint256 creatorFee = tokens[_token].price - platformFee;
        // send the platform fee to the treasury
        require(
            IERC20(usdcAddress).transferFrom(
                msg.sender,
                IBlockTrekker(owner()).treasury(),
                platformFee
            ),
            "!PlatformFee"
        );
        // send the creator fee to the dashboard creator
        require(
            IERC20(usdcAddress).transferFrom(
                msg.sender,
                tokens[_token].creator,
                creatorFee
            ),
            "!CreatorFee"
        );
        // mint the token to the user
        _mint(msg.sender, _token, 1, "");
        // log the token mint event
        emit TokenMinted(_token, msg.sender);
    }

    function changePrice(uint256 _token, uint256 _price) external override onlyCreator(_token) {
        // ensure the price is greater than 0
        require(_price > 0, "!Price>0");
        // update the token price
        tokens[_token].price = _price;
        // log the token price update event
        emit TokenPriceUpdated(_token);
    }

    /// VIEWS ///

    function usdc() public view override returns (address) {
        return IBlockTrekker(owner()).usdc();
    }

    function treasury() public view override returns (address) {
        return IBlockTrekker(owner()).treasury();
    }

    function basisPoints() public view override returns (uint16) {
        return IBlockTrekker(owner()).feeBP();
    }

    function mintFee(uint256 _price) public view override returns (uint256) {
        uint16 bp = basisPoints();
        return (_price * bp) / 10000;
    }
}
