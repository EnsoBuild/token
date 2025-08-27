// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import { Ownable } from "openzeppelin-contracts/access/Ownable.sol";
import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { MerkleProof } from "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";

contract Airdrop is Ownable {
    event Claim(address to, uint256 amount);

    error InvalidMerkleProof();
    error AlreadyClaimed(bytes32 leaf);
    error AirdropExpired();
    error AirdropNotExpired();

    IERC20 public immutable token;
    bytes32 public immutable root;
    uint256 public immutable expiration;
    mapping(bytes32 => bool) public claimed;

    constructor(address _token, bytes32 _root, uint256 _expiration, address _owner) Ownable(_owner) {
        token = IERC20(_token);
        root = _root;
        expiration = _expiration;
    }

    function getLeafHash(address to, uint256 amount) public pure returns (bytes32) {
        return keccak256(abi.encode(to, amount));
    }

    function claim(bytes32[] memory proof, address to, uint256 amount) external {
        if (block.timestamp > expiration) revert AirdropExpired();

        // NOTE: (to, amount) cannot have duplicates
        bytes32 leaf = getLeafHash(to, amount);

        if (claimed[leaf]) revert AlreadyClaimed(leaf);
        if (!MerkleProof.verify(proof, root, leaf)) revert InvalidMerkleProof();
        claimed[leaf] = true;

        token.transfer(to, amount);

        emit Claim(to, amount);
    }

    function sweep(address to) external onlyOwner {
        if (block.timestamp <= expiration) revert AirdropNotExpired();
        token.transfer(to, token.balanceOf(address(this)));
    }
}
