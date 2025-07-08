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

struct Distribution {
    address account;
    uint256 amount;
}

contract EnsoToken is
    ERC20Upgradeable,
    ERC20PausableUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    function initialize(
        string memory name,
        string memory symbol,
        address owner,
        Distribution[] calldata distribution
    )
        external
        initializer
    {
        __ERC20_init(name, symbol);
        __ERC20Permit_init(name);
        __ERC20Votes_init();
        __Ownable_init(owner);
        __UUPSUpgradeable_init();
        for (uint256 i = 0; i < distribution.length; ++i) {
            _mint(distribution[i].account, distribution[i].amount);
        }
        _pause();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @inheritdoc ERC20PermitUpgradeable
     */
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

    /**
     * @inheritdoc ERC20Upgradeable
     */
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
