# BlockTrekker Smart Contracts
BlockTrekker on-chain contract ecosystem using ERC2535 to manage upgradability.

## Using the BlockTrekker Smart Contracts

### Testing
Unit tests for each facet are written in `./test/`.
```
forge test --ffi
```
The `--ffi` flag is required since a helper method is used to generate function selectors used in facet cuts.

### Deployment
Deploy the smart contract to the Sepolia Testnet:

```
forge script script/deploy.s.sol:DeployBlockTrekker --broadcast --verify --ffi --rpc-url https://sepolia.infura.io/v3/$INFURA_KEY --etherscan-api-key $ETHERSCAN_KEY
```
Make sure you have an infura api key and etherscan api key. You can change the deploy script below according to the network you want to deploy to. The `--ffi` flag is required since a helper method is used to generate function selectors used in facet cuts.

## Contract Descriptions
 - `DiamondCutFacet.sol` is a standard ERC2535 facet that governs the logic of adding/ removing/ updating functionality from the diamond proxy
 - `DiamondLoupeFacet.sol` is a standard ERC2535 facet that provides introspection into the facets & function selectors available from the diamond proxy
 - `OwnershipFacet.sol` is a standard Diamond Facet used to manage ownership over contracts, and employs ERC173.
   - Extended into `AdminFacet.sol` via `LibDiamond.enforceIsContractOwner()` to manage ownership functionality
   - Allows the transfer of Ownership as shown in `./test/Admin.t.sol`
 - `AdminFacet.sol` defines administrator logic for the smart contract.
   - Contract owner can set "whitelisters" who are allowed to set creator roles (separates day-to-day actions from critical ownership actions)
   - Whitelisters can set "creators" who are allowed to create new dashboard tokens through the `DashboardTokenFacet.sol` logic
   - Contract owner can change the platform fee (`feeBP`) that is charged from dashboard token mints and paid to the treasury as profit
   - Contract owner can change the `treasury` address that dashboard query deposits and token mint platform fees are paid to
 - `PaymentFacet.sol` is a small base of logic for users to pay the treasury in USDC for BlockTrekker queries. There is no decentralization currently integrated and it simply allows an onchain payment rail (rather than Stripe, for example) with provable history of payment
   - Anyone can `deposit` usdc directly to the treasury
 - `DashboardTokenFacet.sol` is an ERC1155 with extra logic governing dashboard token minting
   - All standard ERC1155 functionality is included
   - Creators can `addToken` with a given mint price in USDC. The global id of the token maps to the dashboard on BlockTrekker backend and is used to tokengate a given dashboard
   - Creators can `changePrice` of a given dashboard token that they creatred to update the price to access an already-deployed dashboard
   - Any user can `mintToken` to purchase a dashboard token to gain access to a given dashboard. This will pay the creator the fee set for the token - the platform fee taken by the BlockTrekker smart contract
      - A user can only mint a token once and will be prevented from minting multiple tokens since this is useless to them
 - `ViewFacet.sol` provides visibility functions across the BlockTrekker ecosystem since Diamond storage does not support the traditionally created view calls that come with public variable declarations
 - `BlockTrekkerDiamond.sol` is the ERC2535 Diamond Proxy contract that serves as an entry point for all facet functionality & houses all storage

## Deployments

### Sepolia
 - `DiamondCutFacet.sol`: [`0x535656F02879C7cBBEE20Dc3aF4bE966E384AB7C`](https://sepolia.etherscan.io/address/0x535656F02879C7cBBEE20Dc3aF4bE966E384AB7C)
 - `DiamondLoupeFacet.sol`: [`0xC01311dF54341B3eFD492004245361f2BA5C6FC9`](https://sepolia.etherscan.io/address/0xC01311dF54341B3eFD492004245361f2BA5C6FC9)
 - `OwnershipFacet.sol`: [`0x87BC2911A50AD59845925fdD2009515213dc5a7c`](https://sepolia.etherscan.io/address/0x87BC2911A50AD59845925fdD2009515213dc5a7c)
 - `AdminFacet.sol`: [`0x99aD6C509263c24BC9D5C0fe0EF89c83c4b3ba5d`](https://sepolia.etherscan.io/address/0x99aD6C509263c24BC9D5C0fe0EF89c83c4b3ba5d)
 - `DashboardTokenFacet.sol`: [`0xb61ACbeE3685F4B8aE65ce5ab6a7d4f761419999`](https://sepolia.etherscan.io/address/0xb61ACbeE3685F4B8aE65ce5ab6a7d4f761419999)
 - `PaymentFacet.sol`: [`0x0c57183B33bE7D3418a55a0717Aa034E11d127D2`](https://sepolia.etherscan.io/address/0x0c57183B33bE7D3418a55a0717Aa034E11d127D2)
 - `ViewFacet.sol`: [`0x97AE9d7Ab03b7C0a3ef0dBE63a390dBd454F2D06`](https://sepolia.etherscan.io/address/0x97AE9d7Ab03b7C0a3ef0dBE63a390dBd454F2D06)
 - `BlockTrekkerDiamond.sol`: [`0x01e3E47386C9357110aE0D05e2Dd28d841bBd3a1`](https://sepolia.etherscan.io/address/0x01e3E47386C9357110aE0D05e2Dd28d841bBd3a1)
