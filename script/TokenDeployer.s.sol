// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Distribution, EnsoToken } from "../src/EnsoToken.sol";
import { Script } from "forge-std/Script.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TokenDeployer is Script {
    address public OWNER = 0x0676675F4fddC2f572cf0CdDaAf0a6b31841CDaC; // TODO
    address public COINLIST = 0x6969696969696969696969696969696969696969; // TODO

    uint256 WEI = 10 ** 18;
    uint256 TOTAL_SUPPLY = 100_000_000 * WEI;
    uint256 BASIS_POINTS = 10_000;
    uint256 COINLIST_SHARE = (TOTAL_SUPPLY * 440) / BASIS_POINTS;
    uint256 OWNER_SHARE = TOTAL_SUPPLY - COINLIST_SHARE;

    function deploy() public returns (ERC1967Proxy token, EnsoToken implementation) {
        implementation = new EnsoToken();
        Distribution[] memory nullDistribution = new Distribution[](0);
        implementation.initialize("", "", address(implementation), nullDistribution);

        string memory name = "Enso";
        string memory symbol = "ENSO";
        Distribution[] memory distribution = new Distribution[](2);
        distribution[0] = Distribution(OWNER, OWNER_SHARE);
        distribution[1] = Distribution(COINLIST, COINLIST_SHARE);
        bytes memory initializationCall =
            abi.encodeWithSelector(EnsoToken.initialize.selector, name, symbol, OWNER, distribution);
        token = new ERC1967Proxy(address(implementation), initializationCall);
    }

    function run() public returns (ERC1967Proxy token, EnsoToken implementation) {
        vm.startBroadcast();

        (token, implementation) = deploy();

        vm.stopBroadcast();
    }
}
