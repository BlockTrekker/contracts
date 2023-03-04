# Description: Deploy the BlockTrekker contract to Goerli


# Variables
export $(grep -v '^#' .env | xargs)

# Constructor Arguments
TREASURY=0x3729a6a9ceD02C9d0A86ec9834b28825B212aBF3
ADMIN=0x3729a6a9ceD02C9d0A86ec9834b28825B212aBF3
USDC=0x2f3A40A3db8a7e3D09B0adfEfbCe4f6F81927557

# Deploy the contract and verify on Etherscan
forge create --rpc-url $INFURA_URI \
    --constructor-args $TREASURY $ADMIN $USDC \
    --private-key $PRIVATE_KEY \
    src/BlockTrekker.sol:BlockTrekker \
    --etherscan-api-key $ETHERSCAN_API --verify