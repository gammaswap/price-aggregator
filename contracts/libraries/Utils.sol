// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Utils Library
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Utility functions used by contracts
library Utils {

    /// @dev Convert value number from a fromDecimals number to a toDecimals number
    /// @param value - number to convert
    /// @param fromDecimals - decimals of value to convert from
    /// @param toDecimals - decimals value will be converted to
    /// @return converted - value as a toDecimals number
    function convertDecimals(uint256 value, uint8 fromDecimals, uint8 toDecimals) internal pure returns (uint256 converted) {
        if (fromDecimals == toDecimals) {
            return value;
        } else if (fromDecimals > toDecimals) {
            return value / (10 ** (fromDecimals - toDecimals));
        } else {
            return value * (10 ** (toDecimals - fromDecimals));
        }
    }
}
