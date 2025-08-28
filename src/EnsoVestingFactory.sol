// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import { SafeERC20, IERC20 } from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "openzeppelin-contracts/access/Ownable.sol";
import { EnsoVestingWallet } from "./EnsoVestingWallet.sol";

contract EnsoVestingFactory is Ownable {
    using SafeERC20 for IERC20;

    IERC20 private immutable _token;

    struct VestingOptions {
        address beneficiary;
        uint256 amount;
        uint64 startTimestamp;
        uint64 durationSeconds;
        uint64 cliffSeconds;
    }

    event VestingWalletCreated(
        address wallet,
        address beneficiary,
        uint256 amount,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffSeconds
    );

    constructor(address token, address owner) Ownable(owner) {
        _token = IERC20(token);
    }

    function token() external view returns (address) {
        return address(_token);
    }

    function create(VestingOptions calldata options) external onlyOwner {
        _create(options);
    }

    function batchCreate(VestingOptions[] calldata options) external onlyOwner {
        for (uint256 i = 0; i < options.length; i++) {
            _create(options[i]);
        }
    }

    function _create(VestingOptions calldata options) internal {
        EnsoVestingWallet wallet = new EnsoVestingWallet(
            _token,
            address(this),
            options.beneficiary,
            options.startTimestamp,
            options.durationSeconds,
            options.cliffSeconds
        );
        _token.safeTransferFrom(msg.sender, address(wallet), options.amount);
        emit VestingWalletCreated(
            address(wallet),
            options.beneficiary,
            options.amount,
            options.startTimestamp,
            options.durationSeconds,
            options.cliffSeconds
        );
    }
}