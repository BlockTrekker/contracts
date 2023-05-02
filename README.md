# BlockTrekker Smart Contracts
BlockTrekker on-chain contract ecosystem

## Using the BlockTrekker Smart Contracts

### Testing
TODO
### Deployment
TODO
## Contracts

### BlockTrekker.sol
`BlockTrekker.sol` is the admin smart contract that governs the other smart contracts.
 - Defines the `treasury` address where profits are sent
 - Defines the `feeBP` uint16 which defines the basis points (percentage) of mint fees taken by platform
 - Defines the `usdc` address which points to the USDC ERC20 facilitating query & token payments
 - Allows additional permissioning of `whitelisters` addresses which can call the admin contract to whitelist `creators` in `DashboardToken.sol` contract deployment
    - this allows day-to-day low security function calls to be segregated from high-security calls like updating `treasury`, `feeBP`, or `tokenURI`
 - Allows additional permissioning of `debitors` addresses which can call the admin contract to debit tokens from `creators` in the `QueryPaymaster.sol` contract deployment
    - this allows the segregation of debiting query costs from contract maintenance functions, meaning we can use a robotic backend for this functionality only

### DashboardToken.sol
`DashboardToken.sol` is an ERC1155 token contract which allows dashboard creators to monetize their dashboards by token-gating access
 - Defines a whitelist set of `creators` who are allowed to create new NFTs on the BlockTrekker platform
    - Called by `BlockTrekker.sol` contract by permissioned `whitelisters`
 - Allows `creators` to create new ERC1155 NFT tokens that gate access to dashboards & allow users to compensate them in USDC for a given `price`
 - Allows arbitrary contract callers to mint a `creator`'s NFT for a price in USDC
    - Uses `feeBP` from `BlockTrekker.sol` to make a payment to `treasury` for platform to make a profit as `platformFee`
    - Remaining value from `price - platformFee` to get `creatorFee` which is directly paid to creator when token is minted
 - Allows `creators` to change the mint price of their own tokens
### QueryPaymaster.sol
`QueryPaymaster.sol` is a contract that acts as a non-refundable wallet for `creators` to pay for their queries in the BlockTrekker app
 - `creators` can deposit USDC directly into the `QueryPaymaster.sol` smart contract
    - note: `creators` do not need to be whitelisted as they are in `DashboardToken.sol` to deposit and use the query payment wallet
 - `admin` unilaterally debits from `creator` query wallet
    - use the `debitors` permission set to debit
    - this is not trustless or permissionless. True trustlessness will require TLS notarization 
    - *TODO ASAP: add merkle tree for query receipts to at least provide onchain audit tools that can be cross-referenced with offchain receipts shown in web app*
