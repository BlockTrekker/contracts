# Description: Deploy the BlockTrekker contract

# Deploy TestERC20 for USDC testing
# forge create \
#   --rpc-url https://sepolia.infura.io/v3/$INFURA_KEY \
#   --private-key $PRIVATE_KEY \
#   src/TestERC20.sol:TestERC20 \
#   --etherscan-api-key $ETHERSCAN_KEY \
#   --verify

# Set environment variables from .env
export $(grep -v '^#' .env | xargs)

# Form the RPC URL
network=sepolia
rpc_url=https://$network.infura.io/v3/$INFURA_KEY

# Block exporer url prefix 
explorer_url=https://sepolia.etherscan.io/address/

# Constructor Arguments
uri=https://api.blocktrekker.xyz/
usdc=0x3C8AC1D5Bd747EF24af4370a652573aF003C6A0c
treasury=0x3729a6a9ceD02C9d0A86ec9834b28825B212aBF3
fee_bp=1000

# # Deploy the BlockTrekker.sol admin contract
# echo "Deploying BlockTrekker.sol"
# output=$(forge create \
#     --constructor-args $usdc $treasury $fee_bp \
#     --rpc-url $rpc_url \
#     --private-key $PRIVATE_KEY \
#     src/BlockTrekker.sol:BlockTrekker \
#     --etherscan-api-key $ETHERSCAN_KEY \
#     --verify)
# admin_contract=$(echo "$output" | awk -F': ' '/Deployed to:/ {print $2}')
# echo "BlockTrekker.sol deployed to $explorer_url$admin_contract"
admin_contract=0x4a672B89aA25E14647aC06716c48BDBb181E627d

# Deploy the QueryPaymaster.sol query wallet contract
echo "Deploying QueryPaymaster.sol"
output=$(forge create \
    --constructor-args $admin_contract \
    --rpc-url https://sepolia.infura.io/v3/$INFURA_KEY \
    --private-key $PRIVATE_KEY \
    src/QueryPaymaster.sol:QueryPaymaster \
    --etherscan-api-key $ETHERSCAN_KEY \
    --verify)
query_payment_contract=$(echo "$output" | awk -F': ' '/Deployed to:/ {print $2}')
echo "QueryPaymaster.sol deployed to $explorer_url$query_payment_contract"

# Deploy the DashboardToken.sol dashboard token gating contract
echo "Deploying DashboardToken.sol"
output=$(forge create \
    --constructor-args $admin_contract \
    --rpc-url https://sepolia.infura.io/v3/$INFURA_KEY \
    --private-key $PRIVATE_KEY \
    src/DashboardToken.sol:DashboardToken \
    --etherscan-api-key $ETHERSCAN_KEY \
    --verify)
dashboard_token_contract=$(echo "$output" | awk -F': ' '/Deployed to:/ {print $2}')
echo "DashboardToken.sol deployed to $explorer_url$dashboard_token_contract"

# Initialize the BlockTrekker.sol contract with the QueryPaymaster and DashboardToken addresses
echo "Initializing BlockTrekker.sol with QueryPaymaster and DashboardToken addresses"
cast call $admin_contract \
    "initialize(address,address)" $dashboard_token_contract $query_payment_contract \
    --rpc-url https://sepolia.infura.io/v3/$INFURA_KEY \
    --private-key $PRIVATE_KEY \

# Unset environment variables
unset $(grep -v '^#' .env | sed -E 's/(.*)=.*/\1/' | xargs)

# Summarize Deployment
echo "=-=-=-=-=-=-=-=-=-=-=[Deployment Summary]=-=-=-=-=-=-=-=-=-=-="
echo "BlockTrekker contracts deployed to $network:"
echo "BlockTrekker.sol: $admin_contract"
echo "QueryPaymaster.sol: $query_payment_contract"
echo "DashboardToken.sol: $dashboard_token_contract"