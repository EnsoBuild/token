// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TokenDeployer } from "../script/TokenDeployer.s.sol";
import { Airdrop } from "../src/Airdrop.sol";
import { EnsoToken } from "../src/EnsoToken.sol";
import { MerkleHelper } from "./helpers/MerkleHelper.sol";
import { Test } from "forge-std/Test.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract AirdropTest is Test {
    TokenDeployer public deployer;
    EnsoToken public token;
    ERC1967Proxy public proxy;

    struct Reward {
        address to;
        uint256 amount;
    }

    Reward[] private rewards;
    bytes32[] private hashes;
    bytes32 private root;
    uint256 private total;

    mapping(bytes32 => Reward) private hashToReward;

    uint256 constant N = 100;

    function setUp() public {
        deployer = new TokenDeployer();
        (proxy,) = deployer.deploy();
        token = EnsoToken(address(proxy));

        // Initialize users and airdrop amounts
        total = 0;
        for (uint256 i = 0; i < N; i++) {
            uint256 amount = (i + 1) * 100;
            rewards.push(Reward({ to: address(uint160(i + 1)), amount: amount }));
            hashes.push(keccak256(abi.encode(rewards[i].to, rewards[i].amount)));
            hashToReward[hashes[i]] = rewards[i];
            total += amount;
        }

        hashes = MerkleHelper.sort(hashes);

        root = MerkleHelper.calcRoot(hashes);
    }

    function test_valid_proof() public {
        Airdrop airdrop = deployAirdrop(block.number + 60);
        for (uint256 i = 0; i < N; i++) {
            bytes32 h = hashes[i];
            Reward memory reward = hashToReward[h];
            bytes32[] memory proof = MerkleHelper.getProof(hashes, i);

            airdrop.claim(proof, reward.to, reward.amount);
            assertEq(token.balanceOf(reward.to), reward.amount);
        }
    }

    function test_expiration() public {
        Airdrop airdrop = deployAirdrop(block.number - 1); // revert on claim
        bytes32 h = hashes[0];
        Reward memory reward = hashToReward[h];
        bytes32[] memory proof = MerkleHelper.getProof(hashes, 0);

        vm.expectRevert(abi.encodeWithSelector(Airdrop.AirdropExpired.selector));
        airdrop.claim(proof, reward.to, reward.amount);

        vm.prank(deployer.OWNER());
        airdrop.sweep(address(this));
        vm.assertEq(token.balanceOf(address(this)), total);
    }

    function deployAirdrop(uint256 expiration) internal returns (Airdrop airdrop) {
        airdrop = new Airdrop(address(token), root, expiration, deployer.OWNER());
        vm.prank(deployer.OWNER());
        token.unpause();
        vm.prank(deployer.OWNER());
        token.transfer(address(airdrop), total);
    }
}
