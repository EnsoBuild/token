// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { TokenDeployer } from "../script/TokenDeployer.s.sol";
import { EnsoToken } from "../src/EnsoToken.sol";
import { TestTokenUpgrade } from "../src/test/TestTokenUpgrade.sol";
import { Test, console } from "forge-std/Test.sol";
import { PausableUpgradeable } from "openzeppelin-contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TokenTest is Test {
    TokenDeployer public deployer;
    EnsoToken public token;
    ERC1967Proxy public proxy;

    address public receiver = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;
    uint256 public amount = 10 ** 18;

    function setUp() public {
        deployer = new TokenDeployer();
        (proxy,) = deployer.deploy();
        token = EnsoToken(address(proxy));
    }

    function test_Decimals() public view {
        assertEq(token.decimals(), 18);
    }

    function test_TotalSupply() public view {
        assertEq(token.totalSupply(), deployer.TOTAL_SUPPLY());
    }

    function test_PausedFail() public {
        vm.startPrank(deployer.COINLIST());
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        token.transfer(receiver, amount);
        vm.stopPrank();
    }

    function test_Unpause() public {
        vm.startPrank(deployer.OWNER());
        token.unpause();
        token.transfer(receiver, amount);
        assertEq(token.balanceOf(receiver), amount);
        vm.stopPrank();
    }

    function test_UpgradeAndMint() public {
        TestTokenUpgrade implementation = new TestTokenUpgrade();
        address owner = deployer.OWNER();
        vm.startPrank(owner);
        bytes memory initializationCall = abi.encodeWithSelector(TestTokenUpgrade.initialize.selector, owner);
        token.upgradeToAndCall(address(implementation), initializationCall);
        TestTokenUpgrade upgradedToken = TestTokenUpgrade(address(token));
        upgradedToken.unpause();
        upgradedToken.mint(receiver, amount);
        assertEq(token.balanceOf(receiver), amount);
        vm.stopPrank();
    }
}
