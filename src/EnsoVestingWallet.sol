// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

// Based on OpenZeppelin's VestingWallet & VestingWalletCliff contracts:
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/finance

import { SafeERC20, IERC20 } from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "openzeppelin-contracts/access/Ownable.sol";

contract EnsoVestingWallet is Ownable {
    using SafeERC20 for IERC20;

    event TokenReleased(uint256 amount);
    event VestingRevoked(uint256 amount, address receiver);

    uint256 public released;
    bool public revoked;
    bool public immutable revocable;
    
    IERC20 private immutable _token;
    address private immutable _revoker;
    uint64 private immutable _start;
    uint64 private immutable _duration;
    uint64 private immutable _cliff;

    error InvalidCliffDuration(uint64 cliffSeconds, uint64 durationSeconds);
    error Revoked();
    error NotRevocable();
    error NotRevoker(address sender, address revoker);

    constructor(IERC20 token, address revoker, address beneficiary, uint64 startTimestamp, uint64 durationSeconds, uint64 cliffSeconds) Ownable(beneficiary) {
        if (cliffSeconds > durationSeconds) {
            revert InvalidCliffDuration(cliffSeconds, durationSeconds);
        }
        _start = startTimestamp;
        _duration = durationSeconds;
        _cliff = startTimestamp + cliffSeconds;
        _token = token;
        if (revoker != address(0)) {
            _revoker = revoker;
            revocable = true;
        }
    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start() public view returns (uint256) {
        return _start;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view returns (uint256) {
        return _duration;
    }

    /**
     * @dev Getter for the end timestamp.
     */
    function end() public view returns (uint256) {
        return start() + duration();
    }

     /**
     * @dev Getter for the cliff timestamp.
     */
    function cliff() public view virtual returns (uint256) {
        return _cliff;
    }

    /**
     * @dev Getter for the token address.
     */
    function token() public view returns (address) {
        return address(_token);
    }

    /**
     * @dev Getter for the revoker address.
     */
    function revoker() public view returns (address) {
        return _revoker;
    }

    /**
     * @dev Getter for the amount of releasable tokens.
     */
    function releasable() public view  returns (uint256) {
        return vestedAmount(uint64(block.timestamp)) - released;
    }

    /**
     * @dev Calculates the amount of the token that has already vested.
     */
    function vestedAmount(uint64 timestamp) public view returns (uint256) {
        return _vestingSchedule(_token.balanceOf(address(this)) + released, timestamp);
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {TokenReleased} event.
     */
    function release() public {
        if (revoked) revert Revoked();
        uint256 amount = releasable();
        if (amount > 0) {
            released += amount;
            emit TokenReleased(amount);
            _token.safeTransfer(owner(), amount);
        }
    }

    /**
     * @dev Revoke vesting contract. Send remaining funds to another account.
     *
     * Emits a {VestingRevoked} event.
     */
    function revoke(address receiver) external {
        if (!revocable) revert NotRevocable();
        if (msg.sender != _revoker) revert NotRevoker(msg.sender, _revoker);
        release(); // first, release funds beneficiary is entitled to up to this point
        revoked = true;
        uint256 amount = _token.balanceOf(address(this));
        _token.safeTransfer(receiver, amount);
        emit VestingRevoked(amount, receiver);
    }

    /**
     * @dev Implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation. Returns 0 if the {cliff} timestamp is not met.
     */
    function _vestingSchedule(
        uint256 totalAllocation,
        uint64 timestamp
    ) internal view returns (uint256) {
        if (revoked || timestamp < cliff()) {
            return 0;
        } else if (timestamp >= end()) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start())) / duration();
        }
    }
}