# Aztec-connect to Aave lending bridge

## Overview

this repo contains a bridge contract (`AaveLendingBridge`) from Aztec to Aave.

It connects the [Aztec-connect](https://medium.com/aztec-protocol/private-defi-with-the-aztec-connect-bridge-76c3da76d982) protocol to Aave's deposit and withdraw functions.

## Description

This contract implements the `IDefiBridge` interface.

It queries the lendingPool adress from `getLendingPool()`, and `getReserveTokensAddresses()` to get the correct `aToken` to redeem (when withdrawing) or to receive (when borrowing).

It also wraps and unwraps `inputAsset` if necessary, by calling the appropriate function depending on the `AztecAssetType` of the input token (e.g. `depositETH()` if `inputAsset` is `ETH`, which first wraps `ETH` to `WETH` before deposit).

## Usage

```solidity
function convert(
    Types.AztecAsset calldata inputAsset,
    Types.AztecAsset calldata,
    Types.AztecAsset calldata,
    Types.AztecAsset calldata,
    uint256 inputValue,
    uint256,
    uint64 mode
)
external payable returns (uint256 outputValue, uint256, bool isAsync);
```

to perform a deposit or a withdraw, call the `convert()` function with the following parameters:

* `inputAsset`  : the asset to deposit or withdraw
* `inputValue`  : the amount of inputAsset to deposit or withdraw
* `mode`        : 0 for deposit, 1 for withdraw
