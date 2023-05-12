// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Script.sol";
import "../src/BlockTrekker.sol";
import "../src/QueryPaymaster.sol";
import "../src/DashboardToken.sol";

contract DeployBlockTrekker is Script {
    address usdc;
    address treasury;
    uint16 feeBP;
    string tokenURI;

    function setUp() public {
        // CONSTRUCTOR PARAMS FOR ALL CONTRACTS
        usdc = 0x3C8AC1D5Bd747EF24af4370a652573aF003C6A0c;
        treasury = 0x3729a6a9ceD02C9d0A86ec9834b28825B212aBF3;
        feeBP = 2500;
        tokenURI = "https://api.blocktrekker.xyz/token/";
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        // Deploy Contracts
        BlockTrekker bt = new BlockTrekker(usdc, treasury, feeBP);
        QueryPaymaster qp = new QueryPaymaster(address(bt));
        DashboardToken dt = new DashboardToken(tokenURI, address(bt));
        // Initialize ecosystem contracts with admin contract
        bt.initialize(address(dt), address(qp));
        vm.stopBroadcast();
    }
}
