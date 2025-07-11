// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Distribution } from "../src/Distribution.sol";
import { EnsoToken } from "../src/EnsoToken.sol";
import { Script, console } from "forge-std/Script.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TokenDeployer is Script {
    address public OWNER = 0x715B1ddF5d6dA6846eaDB72d3D6f9d93148d0bb0;
    address public COINLIST = 0x477F48C93738C0A3a49E365c90Dc56e5466544Df;
    address public COINLIST_FEE = 0x9CA33da9D11cCb2E2b0870f83C0f963573B74A43;

    uint256 internal WEI = 10 ** 18;
    uint256 internal BASIS_POINTS = 10_000;

    uint256 public TOTAL_SUPPLY = 100_000_000 * WEI;
    uint256 public COINLIST_SHARE = (TOTAL_SUPPLY * 400) / BASIS_POINTS;
    uint256 public COINLIST_FEE_SHARE = (TOTAL_SUPPLY * 40) / BASIS_POINTS;
    uint256 public OWNER_SHARE = TOTAL_SUPPLY - COINLIST_SHARE - COINLIST_FEE_SHARE;

    function deploy() public returns (ERC1967Proxy token, EnsoToken implementation) {
        implementation = new EnsoToken{ salt: "EnsoTokenV1" }();
        Distribution[] memory nullDistribution = new Distribution[](0);
        implementation.initialize("", "", address(implementation), nullDistribution);

        string memory name = "Enso";
        string memory symbol = "ENSO";
        Distribution[] memory distribution = new Distribution[](3);
        distribution[0] = Distribution(OWNER, OWNER_SHARE);
        distribution[1] = Distribution(COINLIST, COINLIST_SHARE);
        distribution[2] = Distribution(COINLIST_FEE, COINLIST_FEE_SHARE);
        bytes memory initializationCall =
            abi.encodeWithSelector(EnsoToken.initialize.selector, name, symbol, OWNER, distribution);
        token = new ERC1967Proxy{ salt: "EnsoToken" }(address(implementation), initializationCall);
    }

    function run() public returns (ERC1967Proxy token, EnsoToken implementation) {
        vm.startBroadcast();

        (token, implementation) = deploy();

        vm.stopBroadcast();
    }
}
