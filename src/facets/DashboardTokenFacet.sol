// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../libraries/AppStorage.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/IERC1155TokenReceiver.sol";
import "../interfaces/IERC20.sol";
import "diamond-3/libraries/LibDiamond.sol";

// =============================================================
//                      DASHBOARDTOKEN V1
//  ERC1155 Token that gates access to BlockTrekker Dashboards
// =============================================================
contract DashboardTokenFacet is IERC1155 {
    AppStorage internal s;
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // Return value from `onERC1155Received` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`).
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // Return value from `onERC1155BatchReceived` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).

    /// EVENTS ///
    event TokenAdded(uint256 indexed _tokenNonce); // creator made a new dashboard access NFT
    event TokenMinted(uint256 indexed _tokenNonce, address indexed _minter); // user minted a dashboard access NFT
    event TokenPriceUpdated(uint256 indexed _tokenNonce); // creator changed the price to mint a dashboard access NFT

    /// MODIFIERS ///

    /**
     * Only allow whitelisted creator addresses to call a given function
     */
    modifier anyCreator() {
        require(s.creators[msg.sender].auth, "!Creator");
        _;
    }

    /**
     * Only allow creator of a specified token to call a given function
     *
     * @param _token - tokenId to check for creator membership
     */
    modifier onlyCreator(uint256 _token) {
        require(msg.sender == s.tokens[_token].creator, "!TokenCreator");
        _;
    }

    /**
     * Prevent a caller from minting a token they already own
     *
     * @param _token - tokenId to check for existing ownership by _minter
     */
    modifier uniqueHolder(uint256 _token) {
        require(s.balances[_token][msg.sender] == 0, "!UniqueHolder");
        _;
    }

    /// ERC1155 STANDARD API ///

    /**
     * @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
     *     @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
     *     MUST revert if `_to` is the zero address.
     *     MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
     *     MUST revert on any other error.
     *     MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
     *     After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     *     @param _from    Source address
     *     @param _to      Target address
     *     @param _id      ID of the token type
     *     @param _value   Transfer amount
     *     @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
     */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data)
        external
        override
    {
        require(_to != address(0), "ERC1155: Can't transfer to 0 address");
        require(_from == msg.sender || s.operatorApprovals[_from][msg.sender], "ERC1155: Not approved to transfer");
        uint256 bal = s.balances[_id][_from];
        require(bal >= _value, "ERC1155: _value greater than balance");
        s.balances[_id][_from] = bal - _value;
        s.balances[_id][_to] += _value;
        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        uint256 size;
        assembly {
            size := extcodesize(_to)
        }
        if (size > 0) {
            require(
                ERC1155_ACCEPTED == IERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _value, _data),
                "ERC1155: Transfer rejected/failed by _to"
            );
        }
    }

    /**
     * @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
     *     @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
     *     MUST revert if `_to` is the zero address.
     *     MUST revert if length of `_ids` is not the same as length of `_values`.
     *     MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
     *     MUST revert on any other error.
     *     MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
     *     Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
     *     After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     *     @param _from    Source address
     *     @param _to      Target address
     *     @param _ids     IDs of each token type (order and length must match _values array)
     *     @param _values  Transfer amounts per token type (order and length must match _ids array)
     *     @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external override {
        require(_to != address(0), "ERC1155: Can't transfer to 0 address");
        require(_ids.length == _values.length, "ERC1155: _ids not the same length as _values");
        require(_from == msg.sender || s.operatorApprovals[_from][msg.sender], "ERC1155: Not approved to transfer");
        for (uint256 i; i < _ids.length; i++) {
            uint256 id = _ids[i];
            uint256 value = _values[i];
            uint256 bal = s.balances[id][_from];
            require(bal >= value, "ERC1155: _value greater than balance");
            s.balances[id][_from] = bal - value;
            s.balances[id][_to] += value;
        }
        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        uint256 size;
        assembly {
            size := extcodesize(_to)
        }
        if (size > 0) {
            require(
                ERC1155_BATCH_ACCEPTED
                    == IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _values, _data),
                "Tickets: Transfer rejected/failed by _to"
            );
        }
    }

    /**
     * @notice Get the balance of an account's tokens.
     *     @param _owner    The address of the token holder
     *     @param _id       ID of the token
     *     @return _balance The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view override returns (uint256) {
        return s.balances[_id][_owner];
    }

    /**
     * @notice Get the balance of multiple account/token pairs
     *     @param _owners    The addresses of the token holders
     *     @param _ids       ID of the tokens
     *     @return _balances The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        override
        returns (uint256[] memory _balances)
    {
        require(_owners.length == _ids.length, "ERC1155: _owners not same length as _ids");
        _balances = new uint256[](_owners.length);
        for (uint256 i; i < _owners.length; i++) {
            _balances[i] = s.balances[_ids[i]][_owners[i]];
        }
    }

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
     *     @dev MUST emit the ApprovalForAll event on success.
     *     @param _operator  Address to add to the set of authorized operators
     *     @param _approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external override {
        s.operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @notice Queries the approval status of an operator for a given owner.
     *     @param _owner     The owner of the tokens
     *     @param _operator  Address of authorized operator
     *     @return           True if the operator is approved, false if not
     */
    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        return s.operatorApprovals[_owner][_operator];
    }

    // DASHBOARD TOKEN FUNCTIONS //

    /**
     * Create a new dashboard token with a specified price in USDC
     * @dev modifier anyCreator() - only whitelisted creators can call this function
     * @dev inline requirement that price > 0
     *
     * @param _price - price in USDC to mint the dashboard token
     */
    function addToken(uint256 _price) external anyCreator {
        // require(_price > 0, "!Price>0"); // allow 0 priced tokens
        s.creators[msg.sender].nonce++; // increment creator token nonce
        s.tokenNonce++; // increment global token nonce
        // store token metadata
        s.tokens[s.tokenNonce] = Token({creator: msg.sender, nonce: s.creators[msg.sender].nonce, price: _price});
        // add token id to creator's token map
        s.creators[msg.sender].tokens[s.creators[msg.sender].nonce] = s.tokenNonce;
        // log the token addition event in standard api
        emit TransferSingle(msg.sender, address(0), address(0), s.tokenNonce, 0);
        // log token addition in custom api
        emit TokenAdded(s.tokenNonce);
    }

    /**
     * Mint (purchase) a dashboard token as a user to gain access to a dashboard in the web app
     * @dev modifier uniqueHolder() - only allow minting if user does not already own the token
     * @dev inline requirement that address has approved sufficient balance for this contract to debit
     * @notice todo: ERC20 permit
     *
     * @param _token - tokenId to mint to the user
     */
    function mintToken(uint256 _token) external uniqueHolder(_token) {
        require(IERC20(s.usdc).allowance(msg.sender, address(this)) >= s.tokens[_token].price, "!AffordMint");
        // compute the fee taken by the platform & remaining fee taken by creator when minting
        uint256 platformFee = s.tokens[_token].price * s.feeBP / 10000;
        uint256 creatorFee = s.tokens[_token].price - platformFee;
        // send the platform fee to the treasury
        require(IERC20(s.usdc).transferFrom(msg.sender, s.treasury, platformFee), "!PlatformFee");
        // send the creator fee to the dashboard creator
        require(IERC20(s.usdc).transferFrom(msg.sender, s.tokens[_token].creator, creatorFee), "!CreatorFee");
        // mint the token to the user
        s.balances[_token][msg.sender] += 1;
        emit TransferSingle(msg.sender, address(0), msg.sender, _token, 1);
        // log the token mint event
        emit TokenMinted(_token, msg.sender);
    }

    /**
     * Change the mint price of a dashboard token
     * @dev modifier onlyCreator() - only the creator of the token can call this function
     * @dev inline requirement that price > 0
     *
     * @param _token - global tokenId to change the price of
     * @param _price - new price in USDC to mint the dashboard token
     */
    function changePrice(uint256 _token, uint256 _price) external onlyCreator(_token) {
        // require(_price > 0, "!Price>0"); // allow 0 priced tokens
        // update the token price
        s.tokens[_token].price = _price;
        // log the token price update event
        emit TokenPriceUpdated(_token);
    }
}
