// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import { OwnableUpgradeable } from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC20Upgradeable } from "openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC20PausableUpgradeable } from
    "openzeppelin-contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {
    ERC20PermitUpgradeable,
    NoncesUpgradeable
} from "openzeppelin-contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import { ERC20VotesUpgradeable } from
    "openzeppelin-contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";

contract TestTokenUpgrade is
    ERC20Upgradeable,
    ERC20PausableUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    // WARNING: use safe storage practices in real contract upgrades
    address public minter;

    error NotMinter(address sender);

    function initialize(address minter_) external reinitializer(2) {
        minter = minter_;
    }

    function mint(address account, uint256 value) external {
        if (_msgSender() != minter) revert NotMinter(_msgSender());
        _mint(account, value);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function nonces(address owner)
        public
        view
        virtual
        override(ERC20PermitUpgradeable, NoncesUpgradeable)
        returns (uint256)
    {
        // ERC20PermitUpgradeable.nonces already calls NoncesUpgradeable.nonces
        return ERC20PermitUpgradeable.nonces(owner);
    }

    function _update(
        address from,
        address to,
        uint256 value
    )
        internal
        override(ERC20Upgradeable, ERC20PausableUpgradeable, ERC20VotesUpgradeable)
        whenNotPaused
    {
        // ERC20VotesUpgradeable._update already calls ERC20Upgradeable._update
        ERC20VotesUpgradeable._update(from, to, value);
    }

    function _authorizeUpgrade(address) internal override onlyOwner { }
}
